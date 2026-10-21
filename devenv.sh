#!/bin/bash -i
LOCATION="${LOCATION:=$(pwd)}"

ACTIVE_CONTAINER_ID=$(docker ps -aqf "name=devenv")

docker pull ghcr.io/hauxir/devenv:latest

# Cap devenv so it can never starve the host (sshd/dockerd live outside it).
# Reserve exactly one core for the host: pin devenv to all-but-the-last core
# via cpuset, and set --cpus to match so it doesn't double-reserve a second.
# Scales to whatever core count this machine has.
# Ask the Docker daemon (not nproc) for the core count: it reports the CPUs
# Docker can actually hand out, and since dockerd runs on the host, the answer
# doesn't shrink when this script is run from inside a cpuset-limited devenv.
TOTAL_CPUS=$(docker info --format '{{.NCPU}}')
DEVENV_CPUSET="0-$(( TOTAL_CPUS - 2 > 0 ? TOTAL_CPUS - 2 : 0 ))"
DEVENV_CPUS=$(( TOTAL_CPUS - 1 > 1 ? TOTAL_CPUS - 1 : 1 ))

# GPU passthrough, only when the host has a working NVIDIA driver.
# The devices are also passed explicitly with --device: Docker remembers those,
# so they survive `docker update` (which otherwise drops the device access that
# --gpus grants and leaves nvidia-smi failing with "Failed to initialize NVML").
GPU_ARGS=()
if nvidia-smi >/dev/null 2>&1; then
  # Make sure /dev/nvidia-uvm exists; it's only created on first CUDA use.
  nvidia-modprobe -u -c=0 >/dev/null 2>&1 || true
  GPU_ARGS=(--gpus all)
  # The NVIDIA container runtime injects only the compute libraries by default.
  # "all" adds the graphics ones too (libEGL_nvidia, libGLX_nvidia, the Vulkan
  # ICD), which headless Chromium needs to render on the GPU instead of
  # SwiftShader (e.g. the streetsim screenshots and smoke checks). The image
  # provides the loaders (libegl1, libgl1, libvulkan1); the runtime drops in the
  # driver's libraries at the host's version, so nothing is apt-installed inside.
  GPU_ARGS+=(-e NVIDIA_DRIVER_CAPABILITIES=all)
  for d in /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm /dev/nvidia-uvm-tools /dev/nvidia-modeset; do
    [ -e "$d" ] && GPU_ARGS+=(--device "$d")
  done
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The container mounts $LOCATION at /root/work.  Tools inside the container
# (e.g. docker compose via kh) pass /root/work/… paths to the Docker daemon,
# which resolves them on the HOST filesystem.  A symlink on the host lets the
# daemon follow /root/work → $LOCATION so nested bind-mounts work.
if [ "$(readlink /root/work 2>/dev/null)" != "$LOCATION" ]; then
  ln -sfn "$LOCATION" /root/work 2>/dev/null \
    || sudo ln -sfn "$LOCATION" /root/work 2>/dev/null \
    || true
fi

mkdir -p "$HOME/.local/share/fish/" "$HOME/.config"
touch "$HOME/.local/share/fish/fish_history"
touch "$HOME/.config/.env"

# Deploy tracked Claude global config to the host before it's bind-mounted in.
# Repo is the source of truth; runtime edits to ~/.claude/settings.json are
# overwritten on each launch.
mkdir -p "$HOME/.claude"
if [ -f "$SCRIPT_DIR/.claude/settings.json" ]; then
  cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
else
  echo "warning: $SCRIPT_DIR/.claude/settings.json not found; run this script from a clone of the repo. Keeping existing ~/.claude/settings.json." >&2
fi

# Deploy tracked tmux helper scripts (branch.sh, stat.sh) to the host too.
# ~/.config is bind-mounted over /root/.config, which hides the copies baked
# into the image; without them the window tabs and CPU/mem status render empty.
mkdir -p "$HOME/.config/tmux"
if ls "$SCRIPT_DIR"/.config/tmux/*.sh >/dev/null 2>&1; then
  cp "$SCRIPT_DIR"/.config/tmux/*.sh "$HOME/.config/tmux/"
else
  echo "warning: $SCRIPT_DIR/.config/tmux/*.sh not found; tmux tab names and status will be empty." >&2
fi

if [ -z "$ACTIVE_CONTAINER_ID" ]
then
  ACTIVE_CONTAINER_ID=$(
    docker run \
    --platform linux/amd64 \
    --cpus="$DEVENV_CPUS" \
    --cpuset-cpus="$DEVENV_CPUSET" \
    "${GPU_ARGS[@]}" \
    -v "$HOME/.local/share/fish/fish_history:/root/.local/share/fish/fish_history" \
    -v "$HOME/.ssh":/root/.ssh \
    -v "$HOME/.aws":/root/.aws \
    -v "$HOME/.config":/root/.config \
    -v "$HOME/.claude":/root/.claude \
    -v "$LOCATION:/root/work/" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --network host \
    --name devenv \
    -d \
    -it \
    ghcr.io/hauxir/devenv:latest \
    fish -lc 'tmux -u new-session -d -s work; exec tail -f /dev/null'
  )
fi

# Stop here instead of cascading into confusing start/update/exec errors.
if [ -z "$ACTIVE_CONTAINER_ID" ]; then
  echo "error: failed to create the devenv container (see the docker error above)" >&2
  exit 1
fi

docker start "$ACTIVE_CONTAINER_ID" >/dev/null

# Keep an existing container's limits in sync with the detected core count,
# but only call `docker update` when something actually changed, so it doesn't
# touch the container's device access on every launch.
CURRENT_LIMITS=$(docker inspect -f '{{.HostConfig.NanoCpus}} {{.HostConfig.CpusetCpus}}' "$ACTIVE_CONTAINER_ID")
WANTED_LIMITS="$(( DEVENV_CPUS * 1000000000 )) $DEVENV_CPUSET"
if [ "$CURRENT_LIMITS" != "$WANTED_LIMITS" ]; then
  docker update --cpus="$DEVENV_CPUS" --cpuset-cpus="$DEVENV_CPUSET" "$ACTIVE_CONTAINER_ID" >/dev/null
fi

# attach -d detaches any other client from the session first, so repeated
# `devenv.sh` runs (or terminals that died without detaching) can't pile up as
# stale clients — at most one live client per session.
docker exec -it "$ACTIVE_CONTAINER_ID" tmux attach-session -d || docker exec -it "$ACTIVE_CONTAINER_ID" tmux -u new-session

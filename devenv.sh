#!/bin/bash -i
LOCATION="${LOCATION:=$(pwd)}"

ACTIVE_CONTAINER_ID=$(docker ps -aqf "name=devenv")

docker pull ghcr.io/hauxir/devenv:latest

# Cap devenv so it can never starve the host (sshd/dockerd live outside it).
# Reserve exactly one core for the host: pin devenv to all-but-the-last core
# via cpuset, and set --cpus to match so it doesn't double-reserve a second.
# Scales to whatever core count this machine has.
# nproc --all (not plain nproc) so a cpuset-limited container can't make this
# ratchet down on each run — we always want the true host core count.
TOTAL_CPUS=$(nproc --all)
DEVENV_CPUSET="0-$(( TOTAL_CPUS - 2 > 0 ? TOTAL_CPUS - 2 : 0 ))"
DEVENV_CPUS=$(( TOTAL_CPUS - 1 > 1 ? TOTAL_CPUS - 1 : 1 ))

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p $HOME/.local/share/fish/
touch $HOME/.local/share/fish/fish_history
touch $HOME/.config/.env

# Deploy tracked Claude global config to the host before it's bind-mounted in.
# Repo is the source of truth; runtime edits to ~/.claude/settings.json are
# overwritten on each launch.
mkdir -p $HOME/.claude
cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/settings.json"

if [ -z "$ACTIVE_CONTAINER_ID" ]
then
  ACTIVE_CONTAINER_ID=$(
    docker run \
    --platform linux/amd64 \
    --cpus="$DEVENV_CPUS" \
    --cpuset-cpus="$DEVENV_CPUSET" \
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
    ghcr.io/hauxir/devenv:latest
  )
fi

docker start $ACTIVE_CONTAINER_ID
# Keep an existing container's limits in sync with the detected core count.
docker update --cpus="$DEVENV_CPUS" --cpuset-cpus="$DEVENV_CPUSET" $ACTIVE_CONTAINER_ID >/dev/null
# attach -d detaches any other client from the session first, so repeated
# `devenv.sh` runs (or terminals that died without detaching) can't pile up as
# stale clients — at most one live client per session.
docker exec -it $ACTIVE_CONTAINER_ID tmux attach-session -d || docker exec -it $ACTIVE_CONTAINER_ID tmux -u new-session

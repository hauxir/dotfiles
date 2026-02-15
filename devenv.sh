#!/bin/bash -i
LOCATION="${LOCATION:=$(pwd)}"

ACTIVE_CONTAINER_ID=$(docker ps -aqf "name=devenv")

docker pull ghcr.io/hauxir/devenv:latest

mkdir -p $HOME/.local/share/fish/
touch $HOME/.local/share/fish/fish_history
touch $HOME/.config/.env

if [ -z "$ACTIVE_CONTAINER_ID" ]
then
  ACTIVE_CONTAINER_ID=$(
    docker run \
    --platform linux/amd64 \
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
docker exec -it $ACTIVE_CONTAINER_ID tmux attach-session || docker exec -it $ACTIVE_CONTAINER_ID tmux -u new-session

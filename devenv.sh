#!/bin/bash -i
LOCATION="${LOCATION:=$(pwd)}"

ACTIVE_CONTAINER_ID=$(docker ps -aqf "name=devenv")
NOCACHE=""

if [ "$1" == "rebuild" ] ; then
    NOCACHE="--no-cache"
fi

docker build $NOCACHE --platform linux/amd64 -t devenv - <<EOF
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get install -y \
    curl \
    cmake \
    g++ \
    gcc \
    git \
    libncurses5-dev \
    docker.io \
    docker-compose \
    libssl-dev \
    xsltproc \
    fop \
    libxml2-utils \
    wget

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

RUN apt-get update

RUN apt-get install -y \
    cmake \
    curl \
    docker-compose \
    docker.io \
    efm-langserver \
    fish \
    fzf \
    g++ \
    gcc \
    git \
    libncurses5-dev \
    nodejs \
    ripgrep \
    tmux \
    unzip \
    python3 \
    python3-pip

SHELL ["/bin/fish", "-lc"]

RUN wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.20.7/tree-sitter-linux-x64.gz
RUN gunzip tree-sitter-linux-x64.gz
RUN mv tree-sitter-linux-x64 /usr/bin/tree-sitter
RUN chmod +x /usr/bin/tree-sitter

RUN wget https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz
RUN tar -xvf nvim-linux64.tar.gz
RUN cp -R nvim-linux64/* /usr/
RUN chmod +x /usr/bin/nvim

RUN git clone --depth=1 https://github.com/savq/paq-nvim.git /root/.local/share/nvim/site/pack/paqs/start/paq-nvim --branch v1.1.0
RUN git clone --depth=1 https://github.com/hauxir/dotfiles.git /root/dotfiles

RUN cp -Rp /root/dotfiles/. /root/
RUN rm -rf /root/dotfiles/

RUN nvim --headless +PaqInstall +10sleep +qall
RUN cd /root/.local/share/nvim/site/pack/paqs/start/telescope-fzf-native.nvim && cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build

RUN nvim --headless +PaqInstall +TSInstall +10sleep +qall
RUN git config --global --add safe.directory '*'
RUN npm install -g typescript-language-server typescript
RUN npm install -g vscode-json-languageserver
RUN npm install -g bash-language-server
RUN npm install -g eslint_d
RUN npm install -g vscode-langservers-extracted

RUN mkdir -p /tools/

RUN curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/download/v0.13.0/elixir-ls.zip
RUN unzip elixir-ls.zip -d /tools/elixir-ls
RUN chmod +x /tools/elixir-ls/language_server.sh
RUN ln -s /tools/elixir-ls/language_server.sh /usr/bin/elixir-ls

RUN git clone --depth=1 https://github.com/asdf-vm/asdf.git /root/.asdf --branch v0.8.1
RUN echo -e '\n. /root/.asdf/asdf.sh' >> /root/.profile
RUN echo -e '\n. /root/.asdf/completions/asdf.bash' >> /root/.bashrc
RUN echo 'source ~/.config/.env' >> /root/.profile

RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

RUN fisher install rstacruz/fish-asdf

RUN echo "N"
ENV KERL_BUILD_DOCS=yes

RUN asdf plugin add elixir
RUN asdf plugin add erlang
RUN asdf install elixir 1.14.3
RUN asdf install erlang 25.3

RUN asdf global elixir 1.14.3
RUN asdf global erlang 25.3

RUN mkdir /home/build/
RUN ln -s /root/.asdf/installs/elixir/1.14.3/ /home/build/elixir

RUN mix local.rebar --force
RUN mix local.hex --force

RUN pip install pyright
RUN pip install shell-gpt
WORKDIR /root/work

CMD ["tmux", "-u", "new-session"]
EOF


mkdir -p $HOME/.local/share/fish/
touch $HOME/.local/share/fish/fish_history
touch $HOME/.config/.env

if [ -n "$NOCACHE" ]
then
    docker kill $ACTIVE_CONTAINER_ID
    docker rm $ACTIVE_CONTAINER_ID
    ACTIVE_CONTAINER_ID=""
fi

if [ -z "$ACTIVE_CONTAINER_ID" ]
then
  ACTIVE_CONTAINER_ID=$(
    docker run \
    --platform linux/amd64 \
    -v "$HOME/.local/share/fish/fish_history:/root/.local/share/fish/fish_history" \
    -v "$HOME/.ssh":/root/.ssh \
    -v "$HOME/.config/github-copilot":/root/.config/github-copilot/ \
    -v "$HOME/.config/.env":/root/.config/.env \
    -v "$LOCATION:/root/work/" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --network host \
    --name devenv \
    -d \
    -it \
    devenv
  )
fi

docker start $ACTIVE_CONTAINER_ID
docker attach $ACTIVE_CONTAINER_ID

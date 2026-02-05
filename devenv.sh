#!/bin/bash -i
LOCATION="${LOCATION:=$(pwd)}"

ACTIVE_CONTAINER_ID=$(docker ps -aqf "name=devenv")
NOCACHE=""

if [ "$1" == "rebuild" ] ; then
    NOCACHE="--no-cache"
fi

docker build $NOCACHE --platform linux/amd64 -t devenv - <<EOF
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

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

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

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
    jq \
    libncurses5-dev \
    nodejs \
    ripgrep \
    tmux \
    unzip \
    python3 \
    python3-pip \
    pipx

SHELL ["/bin/fish", "-lc"]

RUN wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.22.6/tree-sitter-linux-x64.gz
RUN gunzip tree-sitter-linux-x64.gz
RUN mv tree-sitter-linux-x64 /usr/bin/tree-sitter
RUN chmod +x /usr/bin/tree-sitter

RUN wget https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz
RUN tar -xvf nvim-linux-x86_64.tar.gz
RUN cp -R nvim-linux-x86_64/* /usr/
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
RUN npm install -g @anthropic-ai/claude-code

RUN mkdir -p /tools/

RUN curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/download/v0.22.1/elixir-ls-v0.22.1.zip
RUN unzip elixir-ls-v0.22.1 -d /tools/elixir-ls
RUN chmod +x /tools/elixir-ls/language_server.sh
RUN ln -s /tools/elixir-ls/language_server.sh /usr/bin/elixir-ls

RUN git clone --depth=1 https://github.com/asdf-vm/asdf.git /root/.asdf --branch v0.8.1
RUN echo -e '\n. /root/.asdf/asdf.sh' >> /root/.profile
RUN echo -e '\n. /root/.asdf/completions/asdf.bash' >> /root/.bashrc
# Set environment variables for all shells
ENV PATH="/root/.asdf/shims:/root/.asdf/bin:/root/.local/bin:./node_modules/.bin:${PATH}"
ENV EDITOR=nvim

RUN echo 'source ~/.config/.env' >> /root/.profile

RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

RUN fisher install rstacruz/fish-asdf

RUN echo "N"
ENV KERL_BUILD_DOCS=yes

RUN asdf plugin add elixir
RUN asdf plugin add erlang
RUN asdf install erlang 27.2
RUN asdf install elixir 1.18.4-otp-27

RUN asdf global erlang 27.2
RUN asdf global elixir 1.18.4-otp-27

RUN mkdir /home/build/
RUN ln -s /root/.asdf/installs/elixir/1.18.4-otp-27/ /home/build/elixir

RUN mix local.rebar --force
RUN mix local.hex --force

RUN pipx install pyright
RUN pipx install shell-gpt
RUN pipx install ruff
RUN pipx install mypy
RUN pipx install virtualenv
RUN pipx install basedpyright
RUN pipx install git+https://github.com/hauxir/planka-cli.git
RUN pipx install git+https://github.com/hauxir/metabase-cli.git
RUN pipx install git+https://github.com/hauxir/freescout-cli.git
RUN curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz && \
    tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud && \
    rm hcloud-linux-amd64.tar.gz

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh -y

RUN curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list && \
    apt update && \
    apt install -y clickhouse-client
WORKDIR /root/work

CMD tmux -u new-session
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
    -v "$HOME/.aws":/root/.aws \
    -v "$HOME/.config":/root/.config \
    -v "$HOME/.claude":/root/.claude \
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
docker exec -it $ACTIVE_CONTAINER_ID tmux attach-session || docker exec -it $ACTIVE_CONTAINER_ID tmux -u new-session

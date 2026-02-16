ARG FROM=ghcr.io/hauxir/brock_samson:60b7a3
FROM ${FROM}

RUN apt-get update && apt-get install -y \
    fish \
    fzf \
    ripgrep \
    tmux \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/fish", "-lc"]

# Install tree-sitter
RUN wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.22.6/tree-sitter-linux-x64.gz && \
    gunzip tree-sitter-linux-x64.gz && \
    mv tree-sitter-linux-x64 /usr/bin/tree-sitter && \
    chmod +x /usr/bin/tree-sitter

# Install Neovim
RUN wget https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz && \
    tar -xf nvim-linux-x86_64.tar.gz && \
    cp -R nvim-linux-x86_64/* /usr/ && \
    chmod +x /usr/bin/nvim && \
    rm -rf nvim-linux-x86_64*

ENV EDITOR=nvim

# Fish plugin manager + asdf integration
RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
RUN fisher install rstacruz/fish-asdf

# Shell profile setup
RUN echo -e '\n. /root/.asdf/asdf.sh' >> /root/.profile
RUN echo -e '\n. /root/.asdf/completions/asdf.bash' >> /root/.bashrc
RUN echo 'source ~/.config/.env' >> /root/.profile

# Dotfiles + Neovim plugins
RUN git clone --depth=1 https://github.com/savq/paq-nvim.git /root/.local/share/nvim/site/pack/paqs/start/paq-nvim --branch v1.1.0
RUN git clone --depth=1 https://github.com/hauxir/dotfiles.git /root/dotfiles
RUN cp -Rp /root/dotfiles/. /root/
RUN rm -rf /root/dotfiles/

RUN nvim --headless +PaqInstall +10sleep +qall
RUN cd /root/.local/share/nvim/site/pack/paqs/start/telescope-fzf-native.nvim && cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build
RUN nvim --headless +PaqInstall +TSInstall +10sleep +qall

ENTRYPOINT []
WORKDIR /root/work
CMD tmux -u new-session

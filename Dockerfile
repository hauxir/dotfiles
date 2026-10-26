FROM ghcr.io/hauxir/brock_samson:60b7a3
USER root

# The base image's GitHub CLI apt keyring expired (2026-09-05; the repo is now
# signed with key 5612B36462313325), which fails `apt-get update` and with it
# every image build. Fetch the current keyring first.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg

# libegl1 + libgl1 (glvnd): the NVIDIA Vulkan ICD that CDI injects
# (libGLX_nvidia) loads libEGL.so.1 and fails without it ("Could not get
# 'vkCreateInstance' via 'vk_icdGetInstanceProcAddr'"), and Chromium's WebGPU
# then falls back to SwiftShader.
RUN apt-get update && apt-get install -y \
    fish \
    fzf \
    libegl1 libgl1 libvulkan1 \
    ripgrep \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Headless Chromium for the streetsim screenshots and smoke checks. The Playwright
# version pins the Chromium build it downloads; a script that runs
# `uv run --with playwright==<version>` must name the same version.
RUN uv pip install --system --break-system-packages playwright==1.58.0 \
    && playwright install --with-deps chromium \
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
ENV ERL_AFLAGS="-kernel shell_history enabled"

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
# Keep-alive must NOT be a tmux client: devenv.sh (and the client-attached
# hook) detach "other" clients on attach, which would kill PID 1 if it were a
# client and stop the container. Start the session detached and idle on tail so
# only real exec clients are ever culled.
CMD tmux -u new-session -d -s work; exec tail -f /dev/null

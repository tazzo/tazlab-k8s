FROM mcr.microsoft.com/devcontainers/base:debian

# Evitiamo interazioni durante l'installazione
ENV DEBIAN_FRONTEND=noninteractive

# 1. Update e Installazione pacchetti di sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    mc tmux ripgrep fd-find fzf zoxide jq build-essential unzip curl wget git \
    ffmpeg 7zip poppler-utils imagemagick stow \
    iputils-ping dnsutils netcat-openbsd htop btop \
    python3-pip python3-venv \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurazione Locales (UTF-8)
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 2. Installazione Tool Binari

# Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Talosctl
RUN curl -Lo /usr/local/bin/talosctl https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64 \
    && chmod +x /usr/local/bin/talosctl

# SOPS
RUN curl -Lo /usr/local/bin/sops https://github.com/getsops/sops/releases/latest/download/sops-v3.9.4.linux.amd64 \
    && chmod +x /usr/local/bin/sops

# YQ
RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Eza
RUN curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz \
    && tar xf /tmp/eza.tar.gz -C /tmp \
    && mv /tmp/eza /usr/local/bin/eza \
    && chmod +x /usr/local/bin/eza \
    && rm /tmp/eza.tar.gz

# Yazi
RUN YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^" ]*') \
    && curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip" \
    && unzip /tmp/yazi.zip -d /tmp/ \
    && mv /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi \
    && mv /tmp/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/ya \
    && chmod +x /usr/local/bin/yazi /usr/local/bin/ya \
    && rm -rf /tmp/yazi.zip /tmp/yazi-x86_64-unknown-linux-gnu

# Lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && install lazygit /usr/local/bin/ \
    && rm lazygit.tar.gz lazygit

# Neovim
RUN curl -Lo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && tar -C /usr/local -xzf /tmp/nvim.tar.gz --strip-components=1 \
    && rm /tmp/nvim.tar.gz

# Starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# 3. Configurazione Utente 'vscode'
USER vscode
WORKDIR /home/vscode

# Installazione NVM e Node LTS (come utente vscode)
ENV NVM_DIR="/home/vscode/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default lts/* \
    && npm install -g @google/gemini-cli@latest

# Clone LazyVim Starter
RUN git clone https://github.com/LazyVim/starter /home/vscode/.config/nvim \
    && rm -rf /home/vscode/.config/nvim/.git

# Pre-configurazione .bashrc
RUN echo 'eval "$(starship init bash)"' >> ~/.bashrc \
    && echo 'eval "$(zoxide init bash)"' >> ~/.bashrc \
    && echo "alias ls='eza --icons'" >> ~/.bashrc \
    && echo "alias ll='eza -l --icons'" >> ~/.bashrc \
    && echo "alias la='eza -la --icons'" >> ~/.bashrc \
    && echo "alias tree='eza --tree --icons'" >> ~/.bashrc \
    && echo "alias k='kubectl'" >> ~/.bashrc \
    && echo "alias talos='talosctl'" >> ~/.bashrc \
    && echo "alias lg='lazygit'" >> ~/.bashrc \
    && echo "alias vi='nvim'" >> ~/.bashrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

# Torno a root per operazioni finali se servono
USER root

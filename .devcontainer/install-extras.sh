#!/bin/bash
set -e

echo "--- Setup Ambiente TazLab (Completo + Network Utils) ---"

# 0. FIX RETE: Forza IPv4 per APT e configura timeout
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
echo 'Acquire::Retries "3";' | sudo tee -a /etc/apt/apt.conf.d/99force-ipv4
echo 'Acquire::http::Timeout "10";' | sudo tee -a /etc/apt/apt.conf.d/99force-ipv4

# 1. APT tools (Base + Dipendenze Yazi + Network Utils)
sudo apt-get update
sudo apt-get install -y mc tmux ripgrep fd-find fzf zoxide jq build-essential unzip curl \
    ffmpeg 7zip poppler-utils imagemagick stow \
    iputils-ping dnsutils netcat-openbsd htop btop

# 2. Tool binari (Talosctl, SOPS, Neovim, YQ)
command -v talosctl &> /dev/null || (curl -Lo /tmp/talosctl https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64 && sudo install /tmp/talosctl /usr/local/bin/talosctl)
command -v sops &> /dev/null || (curl -Lo /tmp/sops https://github.com/getsops/sops/releases/latest/download/sops-v3.9.4.linux.amd64 && sudo install /tmp/sops /usr/local/bin/sops)
command -v nvim &> /dev/null || (curl -Lo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && sudo tar -C /usr/local -xzf /tmp/nvim.tar.gz --strip-components=1)
command -v yq &> /dev/null || (curl -Lo /tmp/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo install /tmp/yq /usr/local/bin/yq)

# 3. Eza (Modern ls)
if ! command -v eza &> /dev/null; then
    echo "Installazione Eza..."
    curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
    tar xf /tmp/eza.tar.gz -C /tmp
    sudo install /tmp/eza /usr/local/bin/
    rm -rf /tmp/eza /tmp/eza.tar.gz
fi

# 4. Yazi (Terminal File Manager)
if ! command -v yazi &> /dev/null; then
    echo "Installazione Yazi..."
    sudo rm -f /tmp/yazi.zip
    YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^" ]*')
    curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
    unzip /tmp/yazi.zip -d /tmp/
    sudo install /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    sudo install /tmp/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
    rm -rf /tmp/yazi.zip /tmp/yazi-x86_64-unknown-linux-gnu
fi

# 5. NVM e Node.js
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installazione NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v node &> /dev/null; then
    echo "Installazione Node.js (LTS)..."
    nvm install --lts
    nvm use --lts
fi

# 6. Gemini CLI (NPM)
echo "Installazione Gemini CLI ufficiale..."
npm install -g @google/gemini-cli@latest

# 7. Configurazione LazyVim
[ -d "$HOME/.config/nvim" ] || (git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git)

# 8. Starship
command -v starship &> /dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y

# 9. Bashrc Config
if ! grep -q "CLUSTER CONFIG" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# --- CLUSTER CONFIG ---
export KUBECONFIG=/home/vscode/.cluster-configs/kubeconfig
export TALOSCONFIG=/home/vscode/.cluster-configs/talosconfig

# --- NVM SETUP ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- DEV TOOLS ---
eval "$(starship init bash)"
eval "$(zoxide init bash)"
alias k='kubectl'
alias talos='talosctl'
alias lg='lazygit'
alias vi='nvim'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias tree='eza --tree --icons'
EOF
fi

# 10. Dotfiles Setup
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "--- Setup Dotfiles (tazzo/dotfiles) ---"
    # Disabilita exit-on-error temporaneamente per evitare che problemi di stow blocchino il container
    set +e
    git clone https://github.com/tazzo/dotfiles.git "$HOME/.dotfiles"
    
    if command -v stow &> /dev/null; then
        echo "Applicazione configurazioni con Stow..."
    cd "$HOME/.dotfiles"
        # Applica tutto il contenuto come package stow
    stow . --adopt
        # Ripristina lo stato git
    git checkout .
    fi
    # Riabilita exit-on-error
    set -e
fi

echo "--- Setup Completato! ---"

#!/bin/bash
set -e

echo "--- Setup Ambiente TazLab (Debian + NVM + Gemini) ---"

# 1. APT tools
sudo apt-get update
sudo apt-get install -y mc tmux ripgrep fd-find fzf zoxide jq build-essential unzip curl

# 2. Tool binari (Talosctl, SOPS, Neovim)
command -v talosctl &> /dev/null || (curl -Lo /tmp/talosctl https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64 && sudo install /tmp/talosctl /usr/local/bin/talosctl)
command -v sops &> /dev/null || (curl -Lo /tmp/sops https://github.com/getsops/sops/releases/latest/download/sops-v3.9.4.linux.amd64 && sudo install /tmp/sops /usr/local/bin/sops)
command -v nvim &> /dev/null || (curl -Lo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && sudo tar -C /usr/local -xzf /tmp/nvim.tar.gz --strip-components=1)

# 3. NVM e Node.js
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installazione NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Carichiamo NVM per usarlo subito nello script
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v node &> /dev/null; then
    echo "Installazione Node.js (LTS)..."
    nvm install --lts
    nvm use --lts
fi

# 4. Gemini CLI (NPM)
echo "Installazione Gemini CLI ufficiale..."
npm install -g @google/gemini-cli@latest

# 5. Configurazione LazyVim
[ -d "$HOME/.config/nvim" ] || (git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git)

# 6. Starship
command -v starship &> /dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y

# 7. Bashrc Config
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
alias ls='ls --color=auto'
EOF
fi

echo "--- Setup Completato! ---"

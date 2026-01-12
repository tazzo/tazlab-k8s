#!/bin/bash
set -e

echo "--- TazLab Runtime Setup ---"

# 1. Configurazione Variabili Cluster
if [ -d "/home/vscode/.cluster-configs" ]; then
    echo "Cluster Configs rilevati."
    if ! grep -q "KUBECONFIG" ~/.bashrc; then
        echo 'export KUBECONFIG=/home/vscode/.cluster-configs/kubeconfig' >> ~/.bashrc
        echo 'export TALOSCONFIG=/home/vscode/.cluster-configs/talosconfig' >> ~/.bashrc
    fi
fi

# 2. Configurazione PATH per script utente
# Assicuriamoci che ~/.local/bin sia nel PATH
if ! grep -q "export PATH=\"$HOME/.local/bin:\$PATH\"" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
mkdir -p "$HOME/.local/bin"

# 3. Dotfiles
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Clonazione Dotfiles..."
    set +e
    git clone https://github.com/tazzo/dotfiles.git "$HOME/.dotfiles"
    
    if command -v stow &> /dev/null; then
        echo "Applicazione configurazioni con Stow..."
        cd "$HOME/.dotfiles"
        
        for package in *; do
            if [ -d "$package" ] && [ "$package" != ".git" ]; then
                
                # FIX NEOVIM
                if [ "$package" == "nvim" ] && [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
                    echo "  Rilevata config Neovim personalizzata: rimuovo quella di default..."
                    rm -rf "$HOME/.config/nvim"
                fi

                # GESTIONE SPECIALE SCRIPT -> ~/.local/bin
                if [ "$package" == "scripts" ]; then
                    echo "  -> Stowing $package in ~/.local/bin"
                    # Usiamo --target (-t) per cambiare la destinazione solo per gli script
                    stow --target="$HOME/.local/bin" --adopt "$package"
                else
                    # Comportamento standard (nella Home)
                    echo "  -> Stowing $package in ~ /"
                    stow --adopt "$package"
                fi
            fi
        done
        
        git checkout .
    fi
    set -e
fi

echo "--- Runtime Ready! ---"

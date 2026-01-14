#!/bin/bash

echo "--- TazLab Runtime Setup Start ---"

# 1. Configurazione PATH
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
mkdir -p "$HOME/.local/bin"

# 2. Gestione Dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonazione Dotfiles..."
    git clone https://github.com/tazzo/dotfiles.git "$DOTFILES_DIR"
else
    echo "Aggiornamento Dotfiles..."
    cd "$DOTFILES_DIR" && git pull
fi

if [ -d "$DOTFILES_DIR" ] && command -v stow &> /dev/null; then
    echo "Applicazione configurazioni con Stow..."
    cd "$DOTFILES_DIR"
    for package in *; do
        if [ -d "$package" ] && [ "$package" != ".git" ]; then
            echo "  Configurando $package..."
            # Neovim Special Case
            if [ "$package" == "nvim" ] && [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
                rm -rf "$HOME/.config/nvim"
            fi
            
            # Applichiamo stow
            if [ "$package" == "scripts" ]; then
                stow --target="$HOME/.local/bin" --adopt "$package"
            else
                stow --target="$HOME" --adopt "$package"
            fi
        fi
    done
    git checkout . 2>/dev/null
fi

# 4. Starship Preset (Tokyo Night)
echo "Applicazione preset Starship: Tokyo Night..."
mkdir -p "$HOME/.config"
starship preset tokyo-night -o "$HOME/.config/starship.toml"

echo "--- Runtime Ready! ---"

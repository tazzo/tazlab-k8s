#!/bin/bash

# setup-runtime.sh
# Gestisce SOLO il setup statico dell'ambiente (Dotfiles, Starship, Path)

echo "--- TazLab Static Runtime Setup Start ---"

# 1. Configurazione PATH
mkdir -p "$HOME/.local/bin"

# 2. Gestione Dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📦 Clonazione Dotfiles..."
    git clone https://github.com/tazzo/dotfiles.git "$DOTFILES_DIR"
else
    cd "$DOTFILES_DIR" && git pull > /dev/null 2>&1
fi

if command -v stow > /dev/null; then
    echo "🔗 Applicazione link simbolici (Stow)..."
    cd "$DOTFILES_DIR"
    for package in *; do
        if [ -d "$package" ] && [ "$package" != ".git" ]; then
            [ "$package" == "nvim" ] && [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
            
            TARGET_DIR="$HOME"
            [ "$package" == "scripts" ] && TARGET_DIR="$HOME/.local/bin"
            
            stow --target="$TARGET_DIR" --adopt "$package" 2>/dev/null
        fi
    done
    git checkout . 2>/dev/null
fi

# 3. Starship
echo "🚀 Configurazione Starship (Tokyo Night)..."
mkdir -p "$HOME/.config"
starship preset tokyo-night -o "$HOME/.config/starship.toml"

# 4. Assicuriamoci che il file env (se esistente) venga caricato nel bashrc
if ! grep -q "source \$HOME/.tazlab-env" "$HOME/.bashrc"; then
    echo "[ -f \"\$HOME/.tazlab-env\" ] && source \"\$HOME/.tazlab-env\"" >> "$HOME/.bashrc"
fi

echo "--- TazLab Static Runtime Setup Completed! ---"

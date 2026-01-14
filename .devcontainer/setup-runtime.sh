#!/bin/bash

echo "--- TazLab Runtime Setup Start ---"

# 1. Configurazione PATH e File Env
mkdir -p "$HOME/.local/bin"
TAZ_ENV="$HOME/.tazlab-env"

# Funzione per scaricare i segreti in modo sicuro
scarica_segreti() {
    echo "Recupero segreti da Infisical Cloud (Env: dev)..."
    TMP_AGE=$(infisical secrets get SOPS_AGE_KEY --env dev --plain --silent 2>/dev/null)
    TMP_KUBE=$(infisical secrets get KUBECONFIG_CONTENT --env dev --plain --silent 2>/dev/null)
    TMP_TALOS=$(infisical secrets get TALOSCONFIG_CONTENT --env dev --plain --silent 2>/dev/null)

    if [[ $TMP_AGE == AGE-SECRET-KEY-* ]] && [[ $TMP_KUBE == apiVersion:* ]]; then
        echo "$TMP_AGE" > /tmp/age.key
        echo "$TMP_KUBE" > /tmp/kubeconfig
        echo "$TMP_TALOS" > /tmp/talosconfig
        chmod 600 /tmp/age.key /tmp/kubeconfig /tmp/talosconfig
        
        # Generiamo il file delle variabili (Sovrascriviamo ogni volta)
        cat << EOF > "$TAZ_ENV"
# --- TAZLAB CLUSTER SECRETS ---
export SOPS_AGE_KEY_FILE="/tmp/age.key"
export KUBECONFIG="/tmp/kubeconfig"
export TALOSCONFIG="/tmp/talosconfig"
export PATH="$HOME/.local/bin:$PATH"
# Re-importiamo l'alias anche qui per sicurezza
alias unlock='bash .devcontainer/setup-runtime.sh && source $HOME/.tazlab-env'
EOF
        chmod 600 "$TAZ_ENV"
        echo "✅ Ambiente del cluster SBLOCCATO!"
        return 0
    else
        echo "❌ Caveau chiuso o errore Infisical. Fai il login!"
        return 1
    fi
}

# 2. Proviamo il recupero
scarica_segreti > /dev/null 2>&1

# 3. Assicuriamoci che l'alias 'unlock' sia SEMPRE presente nel .bashrc
# anche se il file dei segreti non è ancora stato creato.
if ! grep -q "alias unlock" "$HOME/.bashrc"; then
    echo "Configuro alias 'unlock' permanente..."
    echo "alias unlock='bash .devcontainer/setup-runtime.sh && [ -f $HOME/.tazlab-env ] && source $HOME/.tazlab-env'" >> "$HOME/.bashrc"
fi

# 4. Caricamento automatico delle variabili se loggati
if [ -f "$TAZ_ENV" ]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && ! grep -q "source $HOME/.tazlab-env" "$rc"; then
            echo "[ -f \"$HOME/.tazlab-env\" ] && source \"$HOME/.tazlab-env\"" >> "$rc"
        fi
    done
fi

# 5. Starship e Dotfiles
mkdir -p "$HOME/.config"
starship preset tokyo-night -o "$HOME/.config/starship.toml"

DOTFILES_DIR="$HOME/.dotfiles"
[ -d "$DOTFILES_DIR" ] || git clone https://github.com/tazzo/dotfiles.git "$DOTFILES_DIR"
cd "$DOTFILES_DIR" && git pull > /dev/null 2>&1

if command -v stow > /dev/null; then
    for package in *; do
        if [ -d "$package" ] && [ "$package" != ".git" ]; then
            [ "$package" == "nvim" ] && [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
            if [ "$package" == "scripts" ]; then
                stow --target="$HOME/.local/bin" --adopt "$package"
            else
                stow --target="$HOME" --adopt "$package"
            fi
        fi
done
    git checkout . 2>/dev/null
fi

echo "--- TazLab Runtime Setup Completed! ---"

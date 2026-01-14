#!/bin/bash

echo "--- TazLab Runtime Setup Start ---"

# 1. Configurazione PATH
mkdir -p "$HOME/.local/bin"
SECRETS_FILE="$HOME/.cluster-secrets"

# Funzione per scaricare i segreti in modo sicuro
scarica_segreti() {
    echo "Recupero segreti da Infisical Cloud (Env: dev)..."
    
    # Usiamo variabili temporanee per non corrompere i file in caso di errore
    TMP_AGE=$(infisical secrets get SOPS_AGE_KEY --env dev --plain --silent 2>/dev/null)
    TMP_KUBE=$(infisical secrets get KUBECONFIG_CONTENT --env dev --plain --silent 2>/dev/null)
    TMP_TALOS=$(infisical secrets get TALOSCONFIG_CONTENT --env dev --plain --silent 2>/dev/null)

    # Verifichiamo che i dati ricevuti siano validi (non vuoti e senza messaggi di errore)
    if [[ $TMP_AGE == AGE-SECRET-KEY-* ]] && [[ $TMP_KUBE == apiVersion:* ]]; then
        echo "$TMP_AGE" > /tmp/age.key
        echo "$TMP_KUBE" > /tmp/kubeconfig
        echo "$TMP_TALOS" > /tmp/talosconfig
        chmod 600 /tmp/age.key /tmp/kubeconfig /tmp/talosconfig
        
        # Generiamo il file delle variabili
        cat << EOF > "$SECRETS_FILE"
# --- TAZLAB CLUSTER SECRETS ---
export SOPS_AGE_KEY_FILE="/tmp/age.key"
export KUBECONFIG="/tmp/kubeconfig"
export TALOSCONFIG="/tmp/talosconfig"
export PATH="\$HOME/.local/bin:\$PATH"
EOF
        chmod 600 "$SECRETS_FILE"
        echo "✅ Ambiente del cluster SBLOCCATO in RAM!"
        return 0
    else
        echo "❌ Caveau ancora chiuso. Esegui: infisical login"
        return 1
    fi
}

# 2. Proviamo il recupero silenzioso
scarica_segreti > /dev/null 2>&1

# 3. Definiamo l'alias 'unlock' per l'uso manuale post-login
# Aggiungiamo anche il refresh di Starship per sicurezza
if ! grep -q "alias unlock" ~/.bashrc; then
    echo "alias unlock='bash .devcontainer/setup-runtime.sh && source ~/.cluster-secrets && starship preset tokyo-night -o ~/.config/starship.toml'" >> ~/.bashrc
fi

# 4. Caricamento automatico dei segreti se il file esiste
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q "source \$HOME/.cluster-secrets" "$rc"; then
        echo "[ -f \"\$HOME/.cluster-secrets\" ] && source \"\$HOME/.cluster-secrets\"" >> "$rc"
    fi
done

# 5. Starship Preset (Tokyo Night) - Sempre per ultimo per vincere su Stow
mkdir -p "$HOME/.config"
starship preset tokyo-night -o "$HOME/.config/starship.toml"

# 6. Gestione Dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    git clone https://github.com/tazzo/dotfiles.git "$DOTFILES_DIR"
else
    cd "$DOTFILES_DIR" && git pull > /dev/null 2>&1
fi

if command -v stow > /dev/null; then
    cd "$DOTFILES_DIR"
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
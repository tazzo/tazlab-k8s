#!/bin/bash

echo "--- TazLab Runtime Setup Start ---"

# 1. Configurazione PATH
mkdir -p "$HOME/.local/bin"
SECRETS_FILE="$HOME/.cluster-secrets"

# 2. Gestione Segreti via Infisical (Stateless)
echo "Recupero segreti da Infisical Cloud (Env: dev)..."
AGE_KEY_PATH="/tmp/age.key"
KUBECONFIG_PATH="/tmp/kubeconfig"
TALOSCONFIG_PATH="/tmp/talosconfig"

# Verifichiamo se siamo loggati
if ! infisical user get > /dev/null 2>&1;
then
    echo "ERRORE: Non sei loggato su Infisical."
    echo "Esegui: infisical login --domain https://eu.infisical.com/api"
else
    # Recupero segreti usando --plain E --silent per evitare caratteri di controllo
    infisical secrets get SOPS_AGE_KEY --env dev --plain --silent > "$AGE_KEY_PATH" 2>/tmp/infisical_err
    infisical secrets get KUBECONFIG_CONTENT --env dev --plain --silent > "$KUBECONFIG_PATH" 2>>/tmp/infisical_err
    infisical secrets get TALOSCONFIG_CONTENT --env dev --plain --silent > "$TALOSCONFIG_PATH" 2>>/tmp/infisical_err

    if [ -s "$AGE_KEY_PATH" ] && [ -s "$KUBECONFIG_PATH" ]; then
        echo "Segreti recuperati con successo in RAM."
        chmod 600 "$AGE_KEY_PATH" "$KUBECONFIG_PATH" "$TALOSCONFIG_PATH"
        
        cat << EOF > "$SECRETS_FILE"
# --- TAZLAB CLUSTER SECRETS ---
export SOPS_AGE_KEY_FILE="$AGE_KEY_PATH"
export KUBECONFIG="$KUBECONFIG_PATH"
export TALOSCONFIG="$TALOSCONFIG_PATH"
export PATH="\$HOME/.local/bin:\$PATH"
EOF
        chmod 600 "$SECRETS_FILE"
        
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [ -f "$rc" ] && ! grep -q "source \$HOME/.cluster-secrets" "$rc"; then
                echo "[ -f \"\$HOME/.cluster-secrets\" ] && source \"\$HOME/.cluster-secrets\"" >> "$rc"
            fi
        done
    else
        echo "ERRORE: Recupero segreti fallito. Controlla /tmp/infisical_err"
        cat /tmp/infisical_err
    fi
fi

# 3. StarshipPreset (Tokyo Night)
echo "Applicazione preset Starship: Tokyo Night..."
mkdir -p "$HOME/.config"
starship preset tokyo-night -o "$HOME/.config/starship.toml"

# 4. Gestione Dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonazione Dotfiles (mancanti)..."
    git clone https://github.com/tazzo/dotfiles.git "$DOTFILES_DIR"
else
    echo "Sincronizzazione Dotfiles esistenti..."
    cd "$DOTFILES_DIR" && git pull > /dev/null 2>&1
fi

if [ -d "$DOTFILES_DIR" ] && command -v stow > /dev/null; then
    echo "Applicazione configurazioni con Stow..."
    cd "$DOTFILES_DIR"
    for package in *; do
        if [ -d "$package" ] && [ "$package" != ".git" ]; then
            if [ "$package" == "nvim" ] && [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
                rm -rf "$HOME/.config/nvim"
            fi
            
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
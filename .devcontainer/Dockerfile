FROM tazzo/tazlab.net:devpod-base-gemini

# Immagine finale specifica per il progetto tazlab-k8s.
# Eredita tutto dalla Golden Image (incluso fix ping e clipboard).

USER root

# INFISICAL CLI: Installazione via script ufficiale aggiornato
RUN curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | bash && \
    apt-get update && apt-get install -y infisical && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /home/vscode
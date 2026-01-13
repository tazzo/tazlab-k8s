FROM tazzo/tazlab.net:devpod-base-gemini

USER root

# FIX PING: Diamo i permessi SUID al binario ping.
# In aggiunta, proviamo a configurare il range di gruppi che possono usare i socket ICMP.
RUN chmod u+s /usr/bin/ping &&     echo "net.ipv4.ping_group_range = 0 2147483647" >> /etc/sysctl.conf

# FIX CLIPBOARD: Installiamo utility per la clipboard che possono essere usate come backend.
RUN apt-get update && apt-get install -y --no-install-recommends     xclip wl-clipboard     && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /home/vscode

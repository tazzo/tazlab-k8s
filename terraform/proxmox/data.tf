# Decrypt Proxmox API secrets
data "sops_file" "proxmox_secrets" {
  source_file = "proxmox-secrets.enc.yaml"
}

# Decrypt Talos cluster secrets
data "sops_file" "talos_secrets" {
  source_file = "talos-secrets.enc.yaml"
}

# Decrypt existing reference configs
data "sops_file" "controlplane_secrets" {
  source_file = "../talos/controlplane-reference.yaml"
}

data "sops_file" "worker_secrets" {
  source_file = "../talos/worker-reference.yaml"
}

locals {
  # Proxmox Secrets
  proxmox_token_id     = data.sops_file.proxmox_secrets.data["proxmox_token_id"]
  proxmox_token_secret = data.sops_file.proxmox_secrets.data["proxmox_token_secret"]

  # Talos Secrets
  cluster_secrets = {
    ca_crt_b64    = data.sops_file.talos_secrets.data["talos_ca_crt"]
    admin_crt_b64 = data.sops_file.talos_secrets.data["talos_admin_crt"]
    admin_key_b64 = data.sops_file.talos_secrets.data["talos_admin_key"]
  }

  # The configurations base comes directly from your reference files
  worker_config_base = data.sops_file.worker_secrets.raw
}

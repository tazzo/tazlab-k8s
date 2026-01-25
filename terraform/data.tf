# Decrypt Proxmox API secrets
data "sops_file" "proxmox_secrets" {
  source_file = "proxmox-secrets.enc.yaml"
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

  # Parse the controlplane YAML
  parts = split("---", data.sops_file.controlplane_secrets.raw)
  cp_raw = yamldecode(local.parts[0] == "" ? local.parts[1] : local.parts[0])

  cluster_secrets = {
    token  = trimspace(local.cp_raw.machine.token)
    
    # Raw Base64 from SOPS (removing newlines)
    ca_crt_b64 = replace(replace(local.cp_raw.machine.ca.crt, "\n", ""), " ", "")
    ca_key_b64 = replace(replace(local.cp_raw.machine.ca.key, "\n", ""), " ", "")
    
    # Decoded PEM for YAML patches
    ca_crt_pem = base64decode(replace(replace(local.cp_raw.machine.ca.crt, "\n", ""), " ", ""))
    ca_key_pem = base64decode(replace(replace(local.cp_raw.machine.ca.key, "\n", ""), " ", ""))
  }

  # The configurations base comes directly from your reference files
  worker_config_base = data.sops_file.worker_secrets.raw
}

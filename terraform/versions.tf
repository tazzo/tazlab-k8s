terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "tazlab"
    workspaces {
      name = "tazlab-k8s"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.1.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${local.proxmox_token_id}=${local.proxmox_token_secret}"
  insecure  = true # Self-signed certs in homelab
  
  ssh {
    agent = true
  }
}

provider "talos" {
  # Configuration depends on resources
}

provider "sops" {}

variable "proxmox_endpoint" {
  description = "Proxmox API Endpoint (e.g. https://192.168.1.200:8006)"
  type        = string
  default     = "https://192.168.1.200:8006"
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "talos-proxmox-cluster"
}

variable "control_plane_vip" {
  description = "VIP for Control Plane"
  type        = string
  default     = "https://192.168.1.253:6443"
}

variable "proxmox_node" {
  description = "Proxmox Node Name"
  type        = string
  default     = "proxmox" # Verifica se il tuo nodo si chiama 'proxmox' o 'pve'
}

variable "worker_nodes" {
  description = "Map of worker nodes to create"
  type = map(object({
    ip_address = string
    cpu_cores  = optional(number, 4)
    memory_mb  = optional(number, 4096)
    disk_size  = optional(number, 40)
    data_disk  = optional(number, 100)
  }))
  default = {}
}

variable "gateway" {
  description = "Network Gateway"
  type        = string
  default     = "192.168.1.1"
}

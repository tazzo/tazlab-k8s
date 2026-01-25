resource "proxmox_virtual_environment_vm" "worker_nodes" {
  for_each = var.worker_nodes

  name        = each.key
  description = "Managed by Terraform - Talos Worker"
  tags        = ["talos", "terraform", "worker"] # Reordered to match Proxmox state and avoid drift
  node_name   = var.proxmox_node
  
  agent {
    enabled = true # QEMU Guest Agent is now included in the factory image
  }

  # Hardware alignment
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    size         = each.value.disk_size
    iothread     = true
  }

  # Longhorn Data Disk
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi1"
    size         = each.value.data_disk
    iothread     = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = var.gateway
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  cdrom {
    enabled   = true
    file_id   = "local:iso/nocloud-amd64.iso"
    interface = "ide0"
  }
  
  boot_order = ["scsi0", "ide0"]

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      cdrom,
      initialization
    ]
  }
}

resource "talos_machine_configuration_apply" "worker_config" {
  for_each = var.worker_nodes

  client_configuration = {
    ca_certificate     = local.cluster_secrets.ca_crt_b64
    client_certificate = local.cluster_secrets.ca_crt_b64
    client_key         = local.cluster_secrets.ca_key_b64
  }

  # USE THE REFERENCE FILE DIRECTLY AS INPUT, but remove unknown keys
  machine_configuration_input = replace(split("---", data.sops_file.worker_secrets.raw)[0], "grubUseUKICmdline: true", "")
  
  node = each.value.ip_address
  
  config_patches = [
    # Override hostname and hardware
    yamlencode({
      machine = {
        network = {
            hostname = each.key
        }
        install = {
            image = "factory.talos.dev/installer/e187c9b90f773cd8c84e5a3265c5554ee787b2fe67b508d9f955e90e7ae8c96c:v1.12.0"
        }
        kubelet = {
            extraMounts = [
                {
                    destination = "/var/lib/longhorn"
                    type = "bind"
                    source = "/var/mnt/longhorn"
                    options = ["bind", "rshared", "rw"]
                }
            ]
        }
        disks = [
            {
                device = "/dev/sdb"
                partitions = [{ mountpoint = "/var/mnt/longhorn" }]
            }
        ]
        kernel = {
            modules = [
                { name = "iscsi_tcp" },
                { name = "nbd" },
                { name = "iscsi_generic" },
                { name = "configfs" }
            ]
        }
      }
    })
  ]
  
  lifecycle {
    # Once the node has joined, don't try to re-apply config as it will fail auth
    # and we don't want to accidentally reboot/reconfigure a running node.
    ignore_changes = all
  }

  depends_on = [proxmox_virtual_environment_vm.worker_nodes]
}

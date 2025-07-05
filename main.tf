terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
  ssh {
    agent = true
  }
}

variable "proxmox_api_url" {
  description = "Proxmox API endpoint URL"
  type        = string
  sensitive   = true
}

variable "proxmox_username" {
  description = "Proxmox authentication username"
  type        = string
  default     = "root@pam"
  sensitive   = true
}

variable "proxmox_password" {
  description = "Proxmox authentication password"
  type        = string
  sensitive   = true
}

# Create 2 VMs using count
resource "proxmox_virtual_environment_vm" "ubuntu_vms" {
  count     = 1 # 
  name      = "ubuntu-vm-${count.index + 1}" # Names: ubuntu-vm-1, ubuntu-vm-2
  node_name = "pve"
  vm_id     = 1002 + count.index # Unique VM IDs: 1000, 1001

  clone {
    vm_id = 1000 # Source template
    full  = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2"
  }

  memory {
    dedicated = 2048
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    file_format  = "raw"
    size         = 32
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }

  agent {
    enabled = true
    timeout = "10m"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  on_boot = true
  started = true
}

# Output basic VM information for the external script to use
output "vm_basic_info" {
  value = [
    for i, vm in proxmox_virtual_environment_vm.ubuntu_vms : {
      name = vm.name
      id   = vm.vm_id
    }
  ]
  description = "Basic VM information for external IP retrieval script"
}
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = ">= 2.6.2"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = ">= 0.95.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = ">= 0.10.1"
    }
  }
}

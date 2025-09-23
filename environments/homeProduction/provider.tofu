terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.84.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pveEndpoint
  api_token = var.pveApiToken
  insecure = true
}

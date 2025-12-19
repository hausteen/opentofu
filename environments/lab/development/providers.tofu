terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.89.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.9.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    local = {
      source = "hashicorp/local"
      version = "2.6.1"
    }
    time = {
      source = "hashicorp/time"
      version = "0.13.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_api_token
  insecure = true
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

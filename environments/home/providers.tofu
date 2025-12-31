terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    kustomization = {
      source = "kbst/kustomization"
      version = "0.9.7"
    }
    local = {
      source = "hashicorp/local"
      version = "2.6.1"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = "0.89.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.9.0"
    }
  }
}

provider "kustomization" {
  kubeconfig_raw = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
}

provider "proxmox" {
  endpoint  = var.pve_api_endpoint
  api_token = var.pve_api_token
  insecure = true
}

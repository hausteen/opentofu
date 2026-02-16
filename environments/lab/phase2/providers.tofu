terraform {
  required_providers {
    kustomization = {
      source = "kbst/kustomization"
      version = ">= 0.9.7"
    }
  }
}

provider "kustomization" {
  kubeconfig_path = var.kubernetes_kubeconfig_path
}

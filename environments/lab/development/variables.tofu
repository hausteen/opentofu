variable "alpine_linux_version" {
  type        = string
  description = "Alpine Linux image version"
  default     = "3.23.2"
}

variable "cilium_version" {
  type        = string
  description = "Celium CNI version"
  default     = "1.18.5"
}

variable "kubeconfig_path" {
  type        = string
  description = "path to kubeconfig file"
  default     = "~/Documents/coding/talos-k8s/binaries/kubeconfig"
}

variable "pve_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API"
}

variable "pve_api_token" {
  type        = string
  description = "The OpenTofu token for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "pveHostnames" {
  type        = set(string)
  description = "The Proxmox Virtual Environment node hostnames"
  default = ["pve1"]#, "pve2", "pve3"]
}

variable "talos_cluster_name" {
  type        = string
  description = "Talos cluster name"
  default     = "talosAtHome"
}

variable "talos_cluster_endpoint_vip" {
  type        = string
  description = "Talos cluster endpoint virtual ip"
  default     = "192.168.20.140"
}

variable "talos_default_gateway" {
  type        = string
  description = "Talos cluster default gateway"
  default     = "192.168.20.1"
}

variable "talos_node_data" {
  description = "A map of talos node data"
  type = object({
    control_planes = map(object({
      vm_id        = number
      ip           = string
      proxmox_node = string
    }))
    workers = map(object({
      vm_id        = number
      ip           = string
      proxmox_node = string
    }))
  })
  default = {
    control_planes = {
      talosControlPlane00 = {
        vm_id        = 110,
        ip           = "192.168.20.150",
        proxmox_node = "pve1"
      }
      talosControlPlane01 = {
        vm_id        = 111,
        ip           = "192.168.20.151",
        proxmox_node = "pve1"
      }
      talosControlPlane02 = {
        vm_id        = 112,
        ip           = "192.168.20.152",
        proxmox_node = "pve1"
      }
    }
    workers = {
      talosWorker00 = {
        vm_id        = 120,
        ip           = "192.168.20.160",
        proxmox_node = "pve1"
      }
      talosWorker01 = {
        vm_id        = 121,
        ip           = "192.168.20.161",
        proxmox_node = "pve1"
      }
      talosWorker02 = {
        vm_id        = 122,
        ip           = "192.168.20.162",
        proxmox_node = "pve1"
      }
    }
  }
}

variable "talos_version" {
  type        = string
  description = "Talos image version"
  default     = "1.11.6"
}

variable "talosconfig_path" {
  type        = string
  description = "path to talosconfig file"
  default     = "~/Documents/coding/talos-k8s/binaries/talosconfig"
}

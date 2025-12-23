variable "alpine_linux_version" {
  type        = string
  description = "alpine linux image version"
  default     = "3.23.2"
}

variable "kubernetes_api_endpoint" {
  type        = string
  description = "the external kubernetes api endpoint. will be the same as the talos vip for now"
  default     = "192.168.20.140"
}

variable "kubernetes_cilium_cni_version" {
  type        = string
  description = "cilium cni version"
  default     = "1.18.5"
}

variable "kubernetes_cluster_internal_dns_domain" {
  type        = string
  description = "the dns domain that the cluster will use internally. normally it is cluster.local"
  default     = "kubernetes.internal"
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "kubernetes cluster name"
  default     = "home"
  # cilium cni has these requirements
  validation {
    condition     = length(var.kubernetes_cluster_name) <= 32 && var.kubernetes_cluster_name == lower(var.kubernetes_cluster_name) && var.kubernetes_cluster_name != "default"
    error_message = "cluster name must conform with cilium cni requirements"
  }
}

variable "kubernetes_kubeconfig_path" {
  type        = string
  description = "path to kubeconfig file"
  default     = "~/Documents/coding/talos-k8s/binaries/kubeconfig"
}

variable "pve_api_endpoint" {
  type        = string
  description = "the endpoint for the proxmox virtual environment api"
}

variable "pve_api_token" {
  type        = string
  description = "the opentofu token for the proxmox virtual environment api"
  sensitive   = true
}

variable "pve_hostnames" {
  type        = set(string)
  description = "the proxmox virtual environment node hostnames"
  default     = ["pve1"]#, "pve2", "pve3"]
}

variable "talos_cluster_name" {
  type        = string
  description = "talos cluster name"
  default     = "home"
  validation { # this is only because i want it to be lowercase only
    condition     = var.talos_cluster_name == lower(var.talos_cluster_name)
    error_message = "cluster name must be lowercase"
  }
}

variable "talos_cluster_endpoint_vip" {
  type        = string
  description = "talos cluster endpoint shared virtual ip"
  default     = "192.168.20.140"
}

variable "talos_default_gateway" {
  type        = string
  description = "talos cluster default gateway"
  default     = "192.168.20.1"
}

variable "talos_linux_version" {
  type        = string
  description = "talos image version"
  default     = "1.11.6"
}

variable "talos_node_data" {
  description = "a map of talos node data"
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
    control_planes = { # proxmox restriction: these keys cannot have an underscore in them. use camel case instead
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
    workers = { # proxmox restriction: these keys cannot have an underscore in them. use camel case instead
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

variable "talos_talosconfig_path" {
  type        = string
  description = "path to talosconfig file"
  default     = "~/Documents/coding/talos-k8s/binaries/talosconfig"
}

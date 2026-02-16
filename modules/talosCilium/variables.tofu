variable "kubernetes_api_endpoint_ip" {
  type        = string
  description = "the external kubernetes api endpoint ip. will be the same as the talos vip for now. example: 192.168.20.140"
}

variable "kubernetes_cilium_cni_version" {
  type        = string
  description = "cilium cni version"
  default     = "1.18.6" # 1.19.0 has some sort of bpf program fault. wait for a later version
}

variable "kubernetes_cilium_cni_helm_values_template_file_path" {
  type        = string
  description = "the path to the cilium cni helm values terraform template file. look at the default template file in the module for an example. it must template the kubernetes_cluster_name variable"
  default     = "" # this must stay as "" here since i want it to be optional. the default value is in the cluster.tofu file where this variable is actually used in a conditional
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "kubernetes cluster name"
  # cilium cni has these requirements
  validation {
    condition     = length(var.kubernetes_cluster_name) <= 32 && var.kubernetes_cluster_name == lower(var.kubernetes_cluster_name) && var.kubernetes_cluster_name != "default"
    error_message = "cluster name must conform with cilium cni requirements"
  }
}

variable "kubernetes_kubeconfig_path" {
  type        = string
  description = "path to kubeconfig file. we write the file to this location and read from it as well. it will accept a ~ character"
}

variable "pve_hostnames" {
  type        = set(string)
  description = "the proxmox virtual environment node hostnames. example: ['pve1', 'pve2', 'pve3']"
}

variable "talos_cluster_name" {
  type        = string
  description = "talos cluster name"
  validation { # this is only because i want it to be lowercase only
    condition     = var.talos_cluster_name == lower(var.talos_cluster_name)
    error_message = "cluster name must be lowercase"
  }
}

variable "talos_cluster_endpoint_vip" {
  type        = string
  description = "talos cluster endpoint shared virtual ip. example: 192.168.20.140"
}

variable "talos_default_gateway" {
  type        = string
  description = "talos cluster default gateway ip. example: 192.168.20.1"
}

variable "talos_linux_version" {
  type        = string
  description = "talos image version"
  default     = "1.12.1"
}

variable "talos_node_data" {
  description = "a map of the proxmox talos node data. look at the module's variables file to see an example"
  type = object({
    control_planes = map(object({
      vm_id        = number
      ip           = string
      proxmox_node = string
      name         = string
      tags         = set(string)
    }))
    workers = map(object({
      vm_id        = number
      ip           = string
      proxmox_node = string
      name         = string
      tags         = set(string)
    }))
  })
#   default = {
#     control_planes = {
#       node00 = {
#         vm_id        = 110
#         ip           = "192.168.20.150"
#         proxmox_node = "pve1"
#         name         = "talosControlPlane00"
#         tags         = ["managed by opentofu", "talos control plane"]
#       }
#       node01 = {
#         vm_id        = 111
#         ip           = "192.168.20.151"
#         proxmox_node = "pve2"
#         name         = "talosControlPlane01"
#         tags         = ["managed by opentofu", "talos control plane"]
#       }
#       node02 = {
#         vm_id        = 112
#         ip           = "192.168.20.152"
#         proxmox_node = "pve3"
#         name         = "talosControlPlane02"
#         tags         = ["managed by opentofu", "talos control plane"]
#       }
#     }
#     workers = {
#       node00 = {
#         vm_id        = 120
#         ip           = "192.168.20.160"
#         proxmox_node = "pve1"
#         name         = "talosWorker00"
#         tags         = ["managed by opentofu", " talos worker"]
#       }
#       node01 = {
#         vm_id        = 121
#         ip           = "192.168.20.161"
#         proxmox_node = "pve2"
#         name         = "talosWorker01"
#         tags         = ["managed by opentofu", " talos worker"]
#       }
#       node02 = {
#         vm_id        = 122
#         ip           = "192.168.20.162"
#         proxmox_node = "pve3"
#         name         = "talosWorker02"
#         tags         = ["managed by opentofu", " talos worker"]
#       }
#     }
#   }
}

variable "talos_talosconfig_path" {
  type        = string
  description = "path to talosconfig file. we write the file to this location and read from it as well. it will accept a ~ character"
}

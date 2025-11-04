variable "pveEndpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API"
}

variable "pveApiToken" {
  type        = string
  description = "The OpenTofu token for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "cluster_name" {
  type    = string
  description = "Talos cluster name"
}

variable "default_gateway" {
  type    = string
  description = "Talos cluster default gateway"
}

variable "talos_cp_01_ip_addr" {
  type    = string
  description = "Talos control plane 1 node ip address"
}

variable "talos_worker_01_ip_addr" {
  type    = string
  description = "Talos worker 1 node ip address"
}

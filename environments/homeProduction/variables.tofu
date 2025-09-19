variable "pveEndpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API"
}

variable "pveApiToken" {
  type        = string
  description = "The OpenTofu token for the Proxmox Virtual Environment API"
  sensitive   = true
}

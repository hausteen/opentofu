variable "pveEndpoint" {
  type        = string
  description = "the endpoint for the Proxmox Virtual Environment API"
}

variable "pveApiToken" {
  type        = string
  description = "the opentofu token for the Proxmox Virtual Environment API"
  sensitive   = true
}

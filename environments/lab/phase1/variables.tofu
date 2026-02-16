variable "pve_api_endpoint" {
  type        = string
  description = "the endpoint for the proxmox virtual environment api. example: https://192.168.10.50:8006/"
}

variable "pve_api_token" {
  type        = string
  description = "the opentofu token for the proxmox virtual environment api. example: username@pve!tokenname=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  sensitive   = true
}

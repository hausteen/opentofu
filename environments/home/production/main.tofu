resource "proxmox_virtual_environment_download_file" "cloudInitFile" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve1"
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

# resource "proxmox_virtual_environment_vm" "openbao1" {
#   name = "openbao1"
#   description = "Managed by OpenTofu."
#   tags = ["development", "lab", "opentofu"] # Need to be in alphabetical order
#   node_name = "pve1"
#   vm_id = 100
#   on_boot = true
#   operating_system {
#     type = "l26"
#   }
#   machine = "q35"
#   bios = "ovmf"
#   efi_disk {
#     datastore_id = "local-lvm"
#     pre_enrolled_keys = true
#     type = "4m"
#   }
#   scsi_hardware = "virtio-scsi-single"
#   agent {
#     enabled = true
#     timeout = "1m"
#   }
#   tpm_state {
#     datastore_id = "local-lvm"
#     version = "v2.0"
#   }
#   disk {
#     datastore_id = "local-lvm"
#     import_from  = proxmox_virtual_environment_download_file.cloudInitFile.id
#     interface    = "scsi0"
#     iothread     = true
#     discard      = "on"
#     ssd          = true
#     size         = 10
#   }
#   cpu {
#     cores = 1
#     type  = "x86-64-v2-AES"
#   }
#   memory {
#     dedicated = 1024
#     floating = 1024
#   }
#   network_device {
#     bridge = "vmbr1"
#     vlan_id = 20
#   }
#   network_device {
#     bridge = "vmbr0"
#     vlan_id = 10
#   }
#   boot_order = ["scsi0"]
#   initialization {
#     # ip_config {
#     #   ipv4 {
#     #     address = "dhcp"
#     #   }
#     # }
#     ip_config {
#       ipv4 {
#         address = "192.168.20.2/24"
#         gateway = "192.168.20.1"
#       }
#     }
#     ip_config {
#       ipv4 {
#         address = "192.168.10.100/24"
#       }
#     }
#     user_account {
#       username = "ansible"
#       password = "ansible"
#     }
#     dns {
#       domain = "development.lab.hunt.internal"
#       servers = ["1.1.1.1"]
#     }
#     vendor_data_file_id = "local:snippets/cloud_init_vendor_data_openbao.yml"
#   }
#   # lifecycle {
#   #   ignore_changes = [
#   #     initialization
#   #   ]
#   # }
# }

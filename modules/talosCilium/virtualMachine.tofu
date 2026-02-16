# talos linux - virtual machine creation

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  for_each      = var.talos_node_data.control_planes
  name          = each.value.name
  node_name     = each.value.proxmox_node
  vm_id         = each.value.vm_id
  description   = ""
  tags          = each.value.tags # need to be in alphabetical order
  on_boot       = true
  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi2", "scsi0"]
  operating_system {
    type = "l26"
  }
  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }
  agent {
    enabled = true
    timeout = "2m"
  }
  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }
  cdrom {
    file_id   = proxmox_virtual_environment_download_file.talos_image[each.value.proxmox_node].id
    interface = "scsi0"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi2"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 100
  }
  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 8192
  }
  network_device {
    bridge  = "vmbr1"
    vlan_id = 20
  }
  initialization {
    interface = "scsi1"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.talos_default_gateway
      }
    }
    dns {
      servers = ["1.1.1.1"]
    }
  }
  depends_on = [ resource.proxmox_virtual_environment_download_file.talos_image ]
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each      = var.talos_node_data.workers
  name          = each.value.name
  node_name     = each.value.proxmox_node
  vm_id         = each.value.vm_id
  description   = ""
  tags          = each.value.tags # need to be in alphabetical order
  on_boot       = true
  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi2", "scsi0"]
  operating_system {
    type = "l26"
  }
  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }
  agent {
    enabled = true
    timeout = "2m"
  }
  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }
  cdrom {
    file_id   = proxmox_virtual_environment_download_file.talos_image[each.value.proxmox_node].id
    interface = "scsi0"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi2"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 100
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi3"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 50
  }
  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 8192
  }
  network_device {
    bridge  = "vmbr1"
    vlan_id = 20
  }
  initialization {
    interface = "scsi1"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.talos_default_gateway
      }
    }
    dns {
      servers = ["1.1.1.1"]
    }
  }
  depends_on = [ resource.proxmox_virtual_environment_download_file.talos_image ]
}

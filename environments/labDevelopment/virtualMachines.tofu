resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  for_each = var.talos_node_data.control_planes
  name = "${each.key}"
  description = "Managed by OpenTofu."
  tags = ["kubernetes", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = "${each.value.proxmox_node}"
  vm_id = each.value.vm_id
  on_boot = true
  operating_system {
    type = "l26"
  }
  machine = "q35"
  bios = "ovmf"
  efi_disk {
    datastore_id = "local-lvm"
    type = "4m"
  }
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
    timeout = "1m"
  }
  tpm_state {
    datastore_id = "local-lvm"
    version = "v2.0"
  }
  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_image.id
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
    dedicated = 4096
    floating = 4096
  }
  network_device {
    bridge = "vmbr1"
    vlan_id = 20
  }
  boot_order = ["scsi2", "scsi0"]
  initialization {
    interface = "scsi1"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.talos_default_gateway
      }
    }
    dns {
      #domain = "hunt.internal"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each = var.talos_node_data.workers
  name = "${each.key}"
  description = "Managed by OpenTofu."
  tags = ["kubernetes", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = "${each.value.proxmox_node}"
  vm_id = each.value.vm_id
  on_boot = true
  operating_system {
    type = "l26"
  }
  machine = "q35"
  bios = "ovmf"
  efi_disk {
    datastore_id = "local-lvm"
    type = "4m"
  }
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
    timeout = "1m"
  }
  tpm_state {
    datastore_id = "local-lvm"
    version = "v2.0"
  }
  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_image.id
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
    cores = 2
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 2048
    floating = 2048
  }
  network_device {
    bridge = "vmbr1"
    vlan_id = 20
  }
  boot_order = ["scsi2", "scsi0"]
  initialization {
    interface = "scsi1"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.talos_default_gateway
      }
    }
    dns {
      #domain = "hunt.internal"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
}

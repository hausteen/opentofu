resource "proxmox_virtual_environment_vm" "talos-cp-01" {
  name = "talos-cp-01"
  description = "Managed by OpenTofu."
  tags = ["kubernetes", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = "pve1"
  vm_id = 100
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
        address = "${var.talos_cp_01_ip_addr}/24"
        gateway = var.default_gateway
      }
    }
    dns {
      #domain = "hunt.internal"
      servers = ["1.1.1.1"]
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos-worker-01" {
  name = "talos-worker-01"
  description = "Managed by OpenTofu."
  tags = ["kubernetes", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = "pve1"
  vm_id = 101
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
        address = "${var.talos_worker_01_ip_addr}/24"
        gateway = var.default_gateway
      }
    }
    dns {
      #domain = "hunt.internal"
      servers = ["1.1.1.1"]
    }
  }
}

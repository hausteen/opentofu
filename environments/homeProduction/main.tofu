# the proxmox cloud init virtual machine file that we'll download and use
resource "proxmox_virtual_environment_download_file" "cloudInitFile" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve1"
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

# create the proxmox virutal machine cloud init template which we will later clone for all the other virtual machines
resource "proxmox_virtual_environment_vm" "cloudInitTemplate" {
  node_name = "pve1"
  vm_id = 1000
  name = "debian13CloudInitTemplate"
  on_boot = true
  operating_system {
    type = "l26"
  }
  machine = "q35"
  bios = "ovmf"
  efi_disk {
    datastore_id = "local-lvm"
    pre_enrolled_keys = true
    type = "4m"
  }
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
  }
  tpm_state {
    datastore_id = "local-lvm"
    version = "v2.0"
  }
  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.cloudInitFile.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 10
  }
  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 1024
    floating = 1024
  }
  network_device {
    bridge = "vmbr1"
    firewall = true
    vlan_id = 20
  }
  boot_order = ["scsi0"]
  template = true
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "ansible"
      keys     = [trimspace(file("/home/austin/.ssh/ansibleToVirtualMachines.pub"))]
    }
  }
}

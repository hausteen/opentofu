# Clone everything from VM ID = 1000. Ansible creates it for us.

resource "proxmox_virtual_environment_vm" "dns" {
  name = "dns"
  tags = ["home", "opentofu", "production"]
  description = "Production DNS. Managed by OpenTofu."
  node_name = "pve1"
  clone {
    vm_id = 1000
    full = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.20.2/24"
      }
    }
  }
  disk {
    size = 10
    interface = "scsi0"
    discard = "on"
    iothread = true
    ssd = true
  }
  cpu {
    cores = 1
    type = "x86-64-v2-AES"
  }
  memory {
    dedicated = 1024
    floating = 1024
  }
  network_device {
    vlan_id = 20
    bridge = "vmbr1"
    firewall = true
  }
}

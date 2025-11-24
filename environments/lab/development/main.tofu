####################################################################################################################################################################################
# Talos Linux - image selection and download

# The image factory versions data source provides a list of available talos versions from the image factory.
# Currently its only used in an output.
data "talos_image_factory_versions" "this" {
  filters = {
    stable_versions_only = true
  }
}

# The image factory extensions versions data source provides a list of available extensions for a specific talos version from the image factory.
data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = {
    names = [
      "qemu-guest-agent"
    ]
  }
}

# The image factory schematic resource allows you to create a schematic for a Talos image.
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

# Generates URLs for different assets supported by the Talos image factory.
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "nocloud"
}

# download the Talos image file to Proxmox
resource "proxmox_virtual_environment_download_file" "talos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve1"
  file_name    = "opentofu-managed-talos-${var.talos_version}-${data.talos_image_factory_urls.this.platform}-secureboot.iso"
  url          = data.talos_image_factory_urls.this.urls.iso_secureboot
}

####################################################################################################################################################################################
# Talos Linux - virtual machine creation

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  for_each = var.talos_node_data.control_planes
  name = each.key
  description = "Managed by OpenTofu."
  tags = ["development", "kubernetes", "lab", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = each.value.proxmox_node
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
  name = each.key
  description = "Managed by OpenTofu."
  tags = ["development", "kubernetes", "lab", "opentofu", "talos"] # Need to be in alphabetical order
  node_name = each.value.proxmox_node
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

####################################################################################################################################################################################
# Talos Linux - install and cluster creation

# Create the secrets for the Talos cluster
# Like talosctl gen secrets -o secrets.yaml
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# Get the machine configuration for the control plane nodes
# Like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "control_plane" {
  machine_type     = "controlplane"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.talos_cluster_endpoint_vip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches   = [
    templatefile(
      "templates/talosControlPlanePatches.tftpl",
      {
        image = data.talos_image_factory_urls.this.urls.installer_secureboot,
        vip   = var.talos_cluster_endpoint_vip
      }
    )
  ]
  depends_on = [ resource.talos_machine_secrets.this ]
}

# Get the machine configuration for the worker nodes
# Like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "worker" {
  machine_type     = "worker"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.talos_cluster_endpoint_vip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches   = [
    templatefile(
      "templates/talosWorkerPatches.tftpl",
      {
        image = data.talos_image_factory_urls.this.urls.installer_secureboot
      }
    )
  ]
  depends_on = [ resource.talos_machine_secrets.this ]
}

# Use this to get the talosconfig file
# Set the nodes and endpoints in the talosconfig file
# Like talosctl config endpoint <CONTROL_PLANE_IPs / CLUSTER_ENDPOINT> --talosconfig talosconfig
# Like talosctl config node <CONTROL_PLANE_IPs> --talosconfig talosconfig
data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  endpoints            = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  depends_on = [ resource.talos_machine_secrets.this ]
}

# Apply the control_plane machine configuration to the control plane nodes
# Like talosctl apply-config --insecure --nodes $CONTROL_PLANE_IPs --file controlplane.yaml
resource "talos_machine_configuration_apply" "control_plane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  for_each                    = var.talos_node_data.control_planes
  node                        = each.value.ip
  depends_on                  = [ proxmox_virtual_environment_vm.talos_control_plane ]
}

# Bootstrap the Talos cluster by selecting only 1 control plane node to bootstrap
# Like talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig talosconfig
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
  depends_on           = [ talos_machine_configuration_apply.control_plane ]
}

# Apply the worker machine configuration to the worker nodes
# Like talosctl apply-config --insecure --nodes WORKER_IPs --file worker.yaml
resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.talos_node_data.workers
  node                        = each.value.ip
  depends_on                  = [ resource.talos_machine_bootstrap.this, proxmox_virtual_environment_vm.talos_worker ]
}

# Get the kubeconfig after the cluster is up
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
  depends_on           = [ resource.talos_machine_configuration_apply.worker ]
}

####################################################################################################################################################################################
# Debian Linux - image download

# resource "proxmox_virtual_environment_download_file" "debian_linux_image" {
#   content_type = "import"
#   datastore_id = "local"
#   node_name    = "pve1"
#   url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
#   # url          = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-genericcloud-amd64-20251117-2299.qcow2" # Working image if I need to pin it to specific version
# }

####################################################################################################################################################################################
# Alpine Linux - image download

resource "proxmox_virtual_environment_download_file" "alpine_linux_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve1"
  url          = "https://dl-cdn.alpinelinux.org/alpine/v${substr(var.alpine_linux_version, 0, 4)}/releases/cloud/nocloud_alpine-${var.alpine_linux_version}-x86_64-uefi-cloudinit-r0.qcow2"
}

####################################################################################################################################################################################
# OpenBao - virtual machine creation

# Debian
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
#     import_from  = proxmox_virtual_environment_download_file.debian_linux_image.id
#     interface    = "scsi0"
#     iothread     = true
#     discard      = "on"
#     ssd          = true
#     size         = 10
#   }
#   cpu {
#     cores = 2
#     type  = "x86-64-v2-AES"
#   }
#   memory {
#     dedicated = 2048
#     floating = 2048
#   }
#   network_device {
#     bridge = "vmbr1"
#     vlan_id = 20
#   }
#   boot_order = ["scsi0"]
#   initialization {
#     interface = "scsi1"
#     ip_config {
#       ipv4 {
#         address = "192.168.20.50/24"
#         gateway = "192.168.20.1"
#       }
#     }
#     user_account {
#       username = "debian"
#       password = "debian"
#     }
#     dns {
#       domain = "development.lab.hunt.internal"
#       servers = ["1.1.1.1"]
#     }
#     vendor_data_file_id = "local:snippets/debian_cloud_init_vendor_data.yml"
#   }
#   # lifecycle {
#   #   ignore_changes = [
#   #     initialization
#   #   ]
#   # }
# }

# Alpine
resource "proxmox_virtual_environment_vm" "openbao2" {
  name = "openbao2"
  description = "Managed by OpenTofu."
  tags = ["development", "lab", "opentofu"] # Need to be in alphabetical order
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
    timeout = "2m"
  }
  tpm_state {
    datastore_id = "local-lvm"
    version = "v2.0"
  }
  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.alpine_linux_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 10
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
  boot_order = ["scsi0"]
  initialization {
    interface = "scsi1"
    ip_config {
      ipv4 {
        address = "192.168.20.51/24"
        gateway = "192.168.20.1"
      }
    }
    user_account {
      username = "ansible"
      password = "ansible"
    }
    dns {
      domain = "development.lab.hunt.internal"
      servers = ["1.1.1.1"]
    }
    vendor_data_file_id = "local:snippets/alpine_cloud_init_vendor_data.yml"
  }
  # lifecycle {
  #   ignore_changes = [
  #     initialization
  #   ]
  # }
}

####################################################################################################################################################################################
#

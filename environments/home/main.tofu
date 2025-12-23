####################################################################################################################################################################################
# talos linux - image selection and download

# the image factory versions data source provides a list of available talos versions from the image factory
# currently its only used in an output
data "talos_image_factory_versions" "this" {
  filters = {
    stable_versions_only = true
  }
}

# the image factory extensions versions data source provides a list of available extensions for a specific talos version from the image factory
data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_linux_version
  filters = {
    names = [
      "qemu-guest-agent", # needed for proxmox
      "siderolabs/iscsi-tools", # needed for longhorn
      "siderolabs/util-linux-tools" # needed for longhorn
    ]
  }
}

# the image factory schematic resource allows you to create a schematic for a talos image
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
  depends_on = [ data.talos_image_factory_extensions_versions.this ]
}

# generates URLs for different assets supported by the talos image factory
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_linux_version
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "nocloud"
  depends_on = [ resource.talos_image_factory_schematic.this ]
}

# download the talos linux image file to proxmox hosts
resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each = var.pve_hostnames
  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "opentofu-managed-talos-${var.talos_linux_version}-${data.talos_image_factory_urls.this.platform}-secureboot.iso"
  url          = data.talos_image_factory_urls.this.urls.iso_secureboot
  depends_on = [ data.talos_image_factory_urls.this ]
}

####################################################################################################################################################################################
# talos linux - virtual machine creation

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  for_each      = var.talos_node_data.control_planes
  name          = each.key
  node_name     = each.value.proxmox_node
  vm_id         = each.value.vm_id
  description   = ""
  tags          = ["lab", "managed_by_opentofu", "talos"] # need to be in alphabetical order
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
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
  depends_on = [ resource.proxmox_virtual_environment_download_file.talos_image ]
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each      = var.talos_node_data.workers
  name          = each.key
  node_name     = each.value.proxmox_node
  vm_id         = each.value.vm_id
  description   = ""
  tags          = ["lab", "managed_by_opentofu", "talos"] # need to be in alphabetical order
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
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
  depends_on = [ resource.proxmox_virtual_environment_download_file.talos_image ]
}

####################################################################################################################################################################################
# talos linux - install and cluster creation

# create cilium cni manifest files using helm templates
# these will be injected into the machine config and talos will install it at the right time
data "helm_template" "cilium" {
  chart        = "cilium"
  include_crds = true
  kube_version = "v1.34.0" # I have to specify this for now. Should be resolved once the opentofu helm provider pulls in the patch. Then I can delete this line. https://github.com/helm/helm/pull/31512
  name         = "cilium"
  namespace    = "kube-system"
  repository   = "https://helm.cilium.io/"
  values       = [
    templatefile(
      "templates/cilium_values.tftpl",
      {
        kubernetes_cluster_internal_dns_domain = var.kubernetes_cluster_internal_dns_domain
        kubernetes_cluster_name                = var.kubernetes_cluster_name
        kubernetes_service_host                = var.kubernetes_api_endpoint
      }
    )
  ]
  version      = var.kubernetes_cilium_cni_version
}

# create the secrets for the talos cluster
# like talosctl gen secrets -o secrets.yaml
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_linux_version
}

# get the machine configuration for the control plane nodes
# like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "control_plane" {
  machine_type     = "controlplane"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.kubernetes_api_endpoint}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_linux_version
  config_patches   = [
    templatefile(
      "templates/talosControlPlanePatches.tftpl",
      {
        kubernetes_cluster_internal_dns_domain = var.kubernetes_cluster_internal_dns_domain
        talos_cluster_endpoint_vip             = var.talos_cluster_endpoint_vip
        talos_image                            = data.talos_image_factory_urls.this.urls.installer_secureboot
      }
    ),
    yamlencode(
      {
        cluster = {
          inlineManifests = [
            {
              contents = join("---\n", [data.helm_template.cilium.manifest])
              name     = "cilium"
            }
          ]
        }
      }
    )
  ]
  docs             = true
  examples         = true
  depends_on       = [ resource.talos_machine_secrets.this ]
}

# get the machine configuration for the worker nodes
# like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "worker" {
  machine_type     = "worker"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.kubernetes_api_endpoint}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_linux_version
  config_patches   = [
    templatefile(
      "templates/talosWorkerPatches.tftpl",
      {
        kubernetes_cluster_internal_dns_domain = var.kubernetes_cluster_internal_dns_domain
        talos_image                            = data.talos_image_factory_urls.this.urls.installer_secureboot
      }
    )
  ]
  docs             = true
  examples         = true
  depends_on       = [ resource.talos_machine_secrets.this ]
}

# use this to get the talosconfig file
# set the nodes and endpoints in the talosconfig file
# like talosctl config endpoint <CONTROL_PLANE_IPs / CLUSTER_ENDPOINT> --talosconfig talosconfig
# like talosctl config node <CONTROL_PLANE_IPs> --talosconfig talosconfig
data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  endpoints            = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  depends_on           = [ resource.talos_machine_secrets.this ]
}

# apply the control_plane machine configuration to the control plane nodes
# like talosctl apply-config --insecure --nodes $CONTROL_PLANE_IPs --file controlplane.yaml
resource "talos_machine_configuration_apply" "control_plane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  for_each                    = var.talos_node_data.control_planes
  node                        = each.value.ip
  depends_on                  = [ resource.proxmox_virtual_environment_vm.talos_control_plane ]
  lifecycle {
    # this lifecycle section can be removed when this bug is solved.
    # there's a bug with helm templates where the line endings don't match and/or hashes dont match.
    # i merge the template into the machine config, and opentofu throws a fit here
    # saying there are changes when there have not been any. it happens when there's a 'tofu plan' command.
    # until then, i can't make updates to the machine config here and apply them. i'll have to do it manually.
    # the initial plan and apply is fine. its only the second+ tofu plan where its a problem.
    # https://github.com/hashicorp/terraform-provider-helm/issues/543
    ignore_changes = [
      machine_configuration_input
    ]
  }
}

# bootstrap the talos cluster by selecting only 1 control plane node to bootstrap
# like talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig talosconfig
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
  depends_on           = [ resource.talos_machine_configuration_apply.control_plane ]
}

# apply the worker machine configuration to the worker nodes
# like talosctl apply-config --insecure --nodes WORKER_IPs --file worker.yaml
resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.talos_node_data.workers
  node                        = each.value.ip
  depends_on                  = [ resource.talos_machine_bootstrap.this, resource.proxmox_virtual_environment_vm.talos_worker ]
}

# get the kubeconfig after the cluster is up
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
  depends_on           = [ resource.talos_machine_configuration_apply.worker ]
}

# write the kubeconfig to disk so helm provider can use it below
resource "local_sensitive_file" "kubeconfig" {
  content    = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename   = pathexpand(var.kubernetes_kubeconfig_path)
  depends_on = [ resource.talos_cluster_kubeconfig.this ]
}

# write the talosconfig to disk. this is just because I want it on disk and I don't want to have to use tofu to get it manually.
resource "local_sensitive_file" "talosconfig" {
  content    = data.talos_client_configuration.this.talos_config
  filename   = pathexpand(var.talos_talosconfig_path)
  depends_on = [ data.talos_client_configuration.this ]
}

####################################################################################################################################################################################
# linux image (qcow2) file downloads

# debian linux
# resource "proxmox_virtual_environment_download_file" "debian_linux_image" {
#   for_each     = var.pve_hostnames
#   content_type = "import"
#   datastore_id = "local"
#   node_name    = each.key
#   url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
#   # url          = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-genericcloud-amd64-20251117-2299.qcow2" # Working image if I need to pin it to specific version
# }

# alpine linux
# resource "proxmox_virtual_environment_download_file" "alpine_linux_image" {
#   for_each     = var.pve_hostnames
#   content_type = "import"
#   datastore_id = "local"
#   node_name    = each.key
#   url          = "https://dl-cdn.alpinelinux.org/alpine/v${substr(var.alpine_linux_version, 0, 4)}/releases/cloud/nocloud_alpine-${var.alpine_linux_version}-x86_64-uefi-cloudinit-r0.qcow2"
# }

####################################################################################################################################################################################
# openbao - virtual machine creation

# using debian
# resource "proxmox_virtual_environment_vm" "openbao" {
#   name          = "openbao"
#   description   = ""
#   tags          = ["lab", "managed_by_opentofu", "secrets_management"] # need to be in alphabetical order
#   node_name     = "pve1"
#   vm_id         = 100
#   on_boot       = true
#   machine       = "q35"
#   bios          = "ovmf"
#   scsi_hardware = "virtio-scsi-single"
#   boot_order    = ["scsi0"]
#   operating_system {
#     type = "l26"
#   }
#   efi_disk {
#     datastore_id      = "local-lvm"
#     pre_enrolled_keys = true
#     type              = "4m"
#   }
#   agent {
#     enabled = true
#     timeout = "1m"
#   }
#   tpm_state {
#     datastore_id = "local-lvm"
#     version      = "v2.0"
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
#     floating  = 2048
#   }
#   network_device {
#     bridge  = "vmbr1"
#     vlan_id = 20
#   }
#   initialization {
#     interface           = "scsi1"
#     vendor_data_file_id = "local:snippets/debian_cloud_init_vendor_data.yml"
#     ip_config {
#       ipv4 {
#         address = "192.168.20.50/24"
#         gateway = "192.168.20.1"
#       }
#     }
#     user_account {
#       username = "debian"
#     }
#     dns {
#       domain  = ""
#       servers = [""]
#     }
#   }
# }

# using alpine
# resource "proxmox_virtual_environment_vm" "openbao" {
#   name          = "openbao"
#   description   = ""
#   tags          = ["lab", "managed_by_opentofu", "secrets_management"] # need to be in alphabetical order
#   node_name     = "pve1"
#   vm_id         = 100
#   on_boot       = true
#   machine       = "q35"
#   bios          = "ovmf"
#   scsi_hardware = "virtio-scsi-single"
#   boot_order    = ["scsi0"]
#   operating_system {
#     type = "l26"
#   }
#   efi_disk {
#     datastore_id = "local-lvm"
#     type         = "4m"
#   }
#   agent {
#     enabled = true
#     timeout = "2m"
#   }
#   tpm_state {
#     datastore_id = "local-lvm"
#     version      = "v2.0"
#   }
#   disk {
#     datastore_id = "local-lvm"
#     import_from  = proxmox_virtual_environment_download_file.alpine_linux_image.id
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
#     floating  = 1024
#   }
#   network_device {
#     bridge  = "vmbr1"
#     vlan_id = 20
#   }
#   initialization {
#     interface           = "scsi1"
#     vendor_data_file_id = "local:snippets/alpine_cloud_init_vendor_data.yml"
#     ip_config {
#       ipv4 {
#         address = "192.168.20.50/24"
#         gateway = "192.168.20.1"
#       }
#     }
#     user_account {
#       username = "alpine"
#     }
#     dns {
#       domain  = ""
#       servers = [""]
#     }
#   }
# }

####################################################################################################################################################################################
#

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
  filters       = {
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

# generates urls for different assets supported by the talos image factory
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_linux_version
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "nocloud"
  depends_on    = [ resource.talos_image_factory_schematic.this ]
}

# download the talos linux image file to proxmox hosts
resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each     = var.pve_hostnames
  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "opentofu-managed-${var.talos_cluster_name}-talos-${var.talos_linux_version}-${data.talos_image_factory_urls.this.platform}-secureboot.iso"
  url          = data.talos_image_factory_urls.this.urls.iso_secureboot
  depends_on   = [ data.talos_image_factory_urls.this ]
}

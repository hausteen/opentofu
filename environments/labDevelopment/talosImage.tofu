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

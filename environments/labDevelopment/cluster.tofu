# Generate machine secrets for Talos cluster
resource "talos_machine_secrets" "this" {
  talos_version = element(data.talos_image_factory_versions.this.talos_versions, length(data.talos_image_factory_versions.this.talos_versions) - 1)
}

# Generate a machine configuration for a node type
data "talos_machine_configuration" "cp" {
  machine_type     = "controlplane"
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.talos_cp_01_ip_addr}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = element(data.talos_image_factory_versions.this.talos_versions, length(data.talos_image_factory_versions.this.talos_versions) - 1)
  config_patches   = [
    yamlencode({
      "machine": {
        "install": {
          "image": "${data.talos_image_factory_urls.this.urls.installer_secureboot}"
        },
        "time": {
          "servers": [
            "time.cloudflare.com",
            "time.nist.gov"
          ]
        }
      }
    })
  ]
}

# Generate a machine configuration for a node type
data "talos_machine_configuration" "w" {
  machine_type     = "worker"
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.talos_cp_01_ip_addr}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = element(data.talos_image_factory_versions.this.talos_versions, length(data.talos_image_factory_versions.this.talos_versions) - 1)
    config_patches   = [
    yamlencode({
      "machine": {
        "install": {
          "image": "${data.talos_image_factory_urls.this.urls.installer_secureboot}"
        },
        "time": {
          "servers": [
            "time.cloudflare.com",
            "time.nist.gov"
          ]
        }
      }
    })
  ]
}

# Generate client configuration for a Talos cluster
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [var.talos_cp_01_ip_addr]
  endpoints            = [var.talos_cp_01_ip_addr]
}

# The machine configuration apply resource allows to apply machine configuration to a node
resource "talos_machine_configuration_apply" "cp" {
  depends_on                  = [ proxmox_virtual_environment_vm.talos-cp-01 ]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  node                        = var.talos_cp_01_ip_addr
}

# The machine configuration apply resource allows to apply machine configuration to a node
resource "talos_machine_configuration_apply" "w" {
  depends_on                  = [ proxmox_virtual_environment_vm.talos-worker-01 ]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.w.machine_configuration
  node                        = var.talos_worker_01_ip_addr
}

# The machine bootstrap resource allows you to bootstrap a Talos node
resource "talos_machine_bootstrap" "this" {
  depends_on           = [ talos_machine_configuration_apply.cp ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

# Waits for the Talos cluster to be healthy. Can be used as a dependency before running other operations on the cluster
data "talos_cluster_health" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = data.talos_client_configuration.this.endpoints
  control_plane_nodes  = [ var.talos_cp_01_ip_addr ]
  worker_nodes         = [ var.talos_worker_01_ip_addr ]
}

# Retrieves the kubeconfig for a Talos cluster
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [ talos_machine_bootstrap.this ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

output "talosconfig" {
  value = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "machine_configuration" {
  value = data.talos_machine_configuration.cp.machine_configuration
  sensitive = true
}

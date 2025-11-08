# Create the secrets for the Talos cluster
# Like talosctl gen secrets -o secrets.yaml
resource "talos_machine_secrets" "this" {
  talos_version = element(data.talos_image_factory_versions.this.talos_versions, length(data.talos_image_factory_versions.this.talos_versions) - 1)
}

# Get the machine configuration for the control plane nodes
# Like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "control_plane" {
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

# Get the machine configuration for the worker nodes
# Like talosctl gen config --with-secrets secrets.yaml <CLUSTER_NAME> https://<CLUSTER_ENDPOINT>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "worker" {
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

# Use this to get the talosconfig file
# Set the nodes and endpoints in the talosconfig file
# Like talosctl config endpoint <CONTROL_PLANE_IPs / CLUSTER_ENDPOINT> --talosconfig talosconfig
# Like talosctl config node <CONTROL_PLANE_IPs> --talosconfig talosconfig
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [var.talos_cp_01_ip_addr]
  endpoints            = [var.talos_cp_01_ip_addr]
}

# Apply the control_plane machine configuration to the control plane nodes
# Like talosctl apply-config --insecure --nodes $CONTROL_PLANE_IPs --file controlplane.yaml
resource "talos_machine_configuration_apply" "control_plane" {
  depends_on                  = [ proxmox_virtual_environment_vm.talos-cp-01 ]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = var.talos_cp_01_ip_addr
}

# Bootstrap the Talos cluster by selecting only 1 control plane node to bootstrap
# Like talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig talosconfig
resource "talos_machine_bootstrap" "this" {
  depends_on           = [ talos_machine_configuration_apply.control_plane ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

# Wait for the Talos cluster control plane to be healthy before adding worker nodes.
data "talos_cluster_health" "control_plane" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = data.talos_client_configuration.this.endpoints
  control_plane_nodes  = [ var.talos_cp_01_ip_addr ]
}

# Get the kubeconfig
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [ data.talos_cluster_health.control_plane ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

# Apply the worker machine configuration to the worker nodes
# Like talosctl apply-config --insecure --nodes WORKER_IPs --file worker.yaml
resource "talos_machine_configuration_apply" "worker" {
  depends_on                  = [ data.talos_cluster_health.control_plane, proxmox_virtual_environment_vm.talos-worker-01 ]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.talos_worker_01_ip_addr
}

# Wait for the whole Talos cluster to be healthy; both control plane and workers.
data "talos_cluster_health" "whole_cluster" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = data.talos_client_configuration.this.endpoints
  control_plane_nodes  = [ var.talos_cp_01_ip_addr ]
  worker_nodes         = [ var.talos_worker_01_ip_addr ]
}

# Provide output variables
output "kubeconfig" {
  value = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value = data.talos_client_configuration.this.talos_config
  sensitive = true
}

# output "control_plane_machine_configuration" {
#   value = data.talos_machine_configuration.control_plane.machine_configuration
#   sensitive = true
# }

# output "worker_machine_configuration" {
#   value = data.talos_machine_configuration.worker.machine_configuration
#   sensitive = true
# }

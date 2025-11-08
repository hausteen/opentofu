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
  cluster_endpoint = var.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
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
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = var.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
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
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  endpoints            = [ for k, v in var.talos_node_data.control_planes: v.ip ]
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
  depends_on           = [ talos_machine_configuration_apply.control_plane ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
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

# Wait for the whole Talos cluster to be healthy; both control plane and workers.
data "talos_cluster_health" "whole_cluster" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = data.talos_client_configuration.this.endpoints
  control_plane_nodes  = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  worker_nodes         = [ for k, v in var.talos_node_data.workers: v.ip ]
}

# Get the kubeconfig after whole cluster is set up.
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [ data.talos_cluster_health.whole_cluster ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
}

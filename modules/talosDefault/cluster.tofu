# talos linux - install and cluster creation

# create the secrets for the talos cluster
# like talosctl gen secrets -o secrets.yaml
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_linux_version
}

# get the machine configuration for the control plane nodes
# like talosctl gen config --with-secrets secrets.yaml <cluster_name> https://<cluster_endpoint>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "control_plane" {
  machine_type     = "controlplane"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.kubernetes_api_endpoint_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_linux_version
  config_patches   = [
    templatefile("${path.module}/templates/talosPatches/talosImageInstall.tftpl", {
        talos_image = data.talos_image_factory_urls.this.urls.installer_secureboot
      }
    ),
    templatefile("${path.module}/templates/talosPatches/layer2Vip.tftpl", {
        talos_cluster_endpoint_vip = var.talos_cluster_endpoint_vip
      }
    )
  ]
  docs             = true
  examples         = true
  depends_on       = [ resource.talos_machine_secrets.this ]
}

# get the machine configuration for the worker nodes
# like talosctl gen config --with-secrets secrets.yaml <custer_name> https://<cluster_endpoint>:6443 --install-image factory.talos.dev/<nocloud>-installer-<secureboot>/<hash>:v<version>
data "talos_machine_configuration" "worker" {
  machine_type     = "worker"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.kubernetes_api_endpoint_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_linux_version
  config_patches   = [
    templatefile("${path.module}/templates/talosPatches/talosImageInstall.tftpl", {
        talos_image = data.talos_image_factory_urls.this.urls.installer_secureboot
      }
    )
  ]
  docs             = true
  examples         = true
  depends_on       = [ resource.talos_machine_secrets.this ]
}

# use this to get the talosconfig file
# set the nodes and endpoints in the talosconfig file
# like talosctl config endpoint <control_plane_ip / cluster_endpoint> --talosconfig talosconfig
# like talosctl config node <control_plane_ip> --talosconfig talosconfig
data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  endpoints            = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  depends_on           = [ resource.talos_machine_secrets.this ]
}

# apply the control_plane machine configuration to the control plane nodes
# like talosctl apply-config --insecure --nodes $control_plane_ip --file controlplane.yaml
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
# like talosctl bootstrap --nodes $control_plane_ip --talosconfig talosconfig
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [ for k, v in var.talos_node_data.control_planes: v.ip ][0]
  depends_on           = [ resource.talos_machine_configuration_apply.control_plane ]
}

# apply the worker machine configuration to the worker nodes
# like talosctl apply-config --insecure --nodes worker_ips --file worker.yaml
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

# write the talosconfig to disk. this is just because i want it on disk and i don't want to have to use tofu to get it manually.
resource "local_sensitive_file" "talosconfig" {
  content    = data.talos_client_configuration.this.talos_config
  filename   = pathexpand(var.talos_talosconfig_path)
  depends_on = [ data.talos_client_configuration.this ]
}

# wait for the whole cluster to be healthy before continuing
data "talos_cluster_health" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  control_plane_nodes  = [ for k, v in var.talos_node_data.control_planes: v.ip ]
  worker_nodes         = [ for k, v in var.talos_node_data.workers: v.ip ]
  depends_on           = [ resource.talos_machine_configuration_apply.worker ]
}

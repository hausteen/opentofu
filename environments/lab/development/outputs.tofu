# command to get these outputs on the cli = tofu output -raw <name>
output "kubeconfig" {
  value = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

# output "latest_talos_image_factory_version" {
#   value = element(data.talos_image_factory_versions.this.talos_versions, length(data.talos_image_factory_versions.this.talos_versions) - 1)
# }

output "talosconfig" {
  value = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "talos_machine_configuration_control_plane" {
  value = data.talos_machine_configuration.control_plane.machine_configuration
  sensitive = true
}

output "talos_machine_configuration_worker" {
  value = data.talos_machine_configuration.worker.machine_configuration
  sensitive = true
}

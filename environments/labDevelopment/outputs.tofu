output "kubeconfig" {
  value = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "talos_image_factory_versions" {
  value = data.talos_image_factory_versions.this.talos_versions
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

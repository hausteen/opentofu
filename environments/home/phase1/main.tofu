module "talos_cilium" {
  source                     = "../../../modules/talosCilium"
  pve_hostnames              = ["pve1"]
  kubernetes_cluster_name    = "home"
  kubernetes_api_endpoint_ip = "192.168.20.10"
  kubernetes_kubeconfig_path = "~/Documents/coding/binaries/kubeconfig"
  talos_cluster_name         = "home"
  talos_cluster_endpoint_vip = "192.168.20.10"
  talos_talosconfig_path     = "~/Documents/coding/binaries/talosconfig"
  talos_default_gateway      = "192.168.20.1"
  talos_node_data = {
    control_planes = {
      node00 = {
        vm_id        = 111
        ip           = "192.168.20.11"
        proxmox_node = "pve1"
        name         = "talosControlPlane00"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
      node01 = {
        vm_id        = 112
        ip           = "192.168.20.12"
        proxmox_node = "pve1"
        name         = "talosControlPlane01"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
      node02 = {
        vm_id        = 113
        ip           = "192.168.20.13"
        proxmox_node = "pve1"
        name         = "talosControlPlane02"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
    }
    workers = {
      node00 = {
        vm_id        = 114
        ip           = "192.168.20.14"
        proxmox_node = "pve1"
        name         = "talosWorker00"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
      node01 = {
        vm_id        = 115
        ip           = "192.168.20.15"
        proxmox_node = "pve1"
        name         = "talosWorker01"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
      node02 = {
        vm_id        = 116
        ip           = "192.168.20.16"
        proxmox_node = "pve1"
        name         = "talosWorker02"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
    }
  }
}

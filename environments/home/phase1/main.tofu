module "talos_cilium" {
  source                     = "../../../modules/talosCilium"
  pve_hostnames              = ["pve1"]
  kubernetes_cluster_name    = "home"
  kubernetes_api_endpoint_ip = "192.168.30.100"
  kubernetes_kubeconfig_path = "~/Documents/coding/binaries/kubeconfigHome"
  talos_cluster_name         = "home"
  talos_cluster_endpoint_vip = "192.168.30.100"
  talos_talosconfig_path     = "~/Documents/coding/binaries/talosconfigHome"
  talos_default_gateway      = "192.168.30.1"
  talos_node_data = {
    control_planes = {
      node00 = {
        vm_id        = 111
        ip           = "192.168.30.120"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane00"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
      node01 = {
        vm_id        = 112
        ip           = "192.168.30.121"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane01"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
      node02 = {
        vm_id        = 113
        ip           = "192.168.30.122"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane02"
        tags         = ["home", "managed-by-opentofu", "talos-control-plane"]
      }
    }
    workers = {
      node00 = {
        vm_id        = 114
        ip           = "192.168.30.160"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker00"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
      node01 = {
        vm_id        = 115
        ip           = "192.168.30.161"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker01"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
      node02 = {
        vm_id        = 116
        ip           = "192.168.30.162"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker02"
        tags         = ["home", "managed-by-opentofu", "talos-worker"]
      }
    }
  }
}

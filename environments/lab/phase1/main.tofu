module "talos_cilium" {
  source                     = "../../../modules/talosCilium"
  pve_hostnames              = ["pve1"]
  kubernetes_cluster_name    = "lab"
  kubernetes_api_endpoint_ip = "192.168.30.101"
  kubernetes_kubeconfig_path = "~/Documents/coding/binaries/kubeconfigLab"
  talos_cluster_name         = "lab"
  talos_cluster_endpoint_vip = "192.168.30.101"
  talos_talosconfig_path     = "~/Documents/coding/binaries/talosconfigLab"
  talos_default_gateway      = "192.168.30.1"
  talos_node_data = {
    control_planes = {
      node00 = {
        vm_id        = 121
        ip           = "192.168.30.123"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane00"
        tags         = ["lab", "managed-by-opentofu", "talos-control-plane"]
      }
      node01 = {
        vm_id        = 122
        ip           = "192.168.30.124"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane01"
        tags         = ["lab", "managed-by-opentofu", "talos-control-plane"]
      }
      node02 = {
        vm_id        = 123
        ip           = "192.168.30.125"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosControlPlane02"
        tags         = ["lab", "managed-by-opentofu", "talos-control-plane"]
      }
    }
    workers = {
      node00 = {
        vm_id        = 124
        ip           = "192.168.30.163"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker00"
        tags         = ["lab", "managed-by-opentofu", "talos-worker"]
      }
      node01 = {
        vm_id        = 125
        ip           = "192.168.30.164"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker01"
        tags         = ["lab", "managed-by-opentofu", "talos-worker"]
      }
      node02 = {
        vm_id        = 126
        ip           = "192.168.30.165"
        vlan_id      = 30
        proxmox_node = "pve1"
        name         = "talosWorker02"
        tags         = ["lab", "managed-by-opentofu", "talos-worker"]
      }
    }
  }
}

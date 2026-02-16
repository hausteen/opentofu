# Purpose

This module creates a highly available Talos cluster install running 3 control plane nodes and 3 worker nodes.

This is a customized version of Talos Linux, which installs Cilium as the CNI provider.
You can provide your own Cilium values file to customize Cilium to your liking.

It sets the pod security admission enforced default to "Restricted".

# How to use it

Call this module with all the variables in the variables.tofu file, which do not have a default value assigned.

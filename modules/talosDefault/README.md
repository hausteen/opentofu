# Purpose

This module creates a highly available Talos cluster install running 3 control plane nodes and 3 worker nodes.

It does try to keep the default Talos Linux cluster settings as much as possible.

The module does set the Talos control plane virtual ip, which is not by default present.

# How to use it

Call this module with all the variables in the variables.tofu file, which do not have a default value assigned.

# Purpose

This is my home network that the family relies on all day every day.

This is built for reliability and resilency since I can't have this cluster having problems.

# How to use it

Create "phases" (folders) for different terraform state files that will be managed independently.

Make sure that variables have the same value in each of the phases.

Go into each phase folder and run the normal tofu init, tofu plan, tofu apply.

# Reasoning

I'm doing it this way because there are issues with timing and destroying assets defined in the state file such that its easier for me
to split the work into different state files. Specifically destroying applications in the right order with Argo CD is the tricky point.
So currently, phase 1 creates the virtual machine and installs Talos Linux. Phase 2 installs Argo CD and starts the app of apps application
which deploys all the other applications on Kubernetes.

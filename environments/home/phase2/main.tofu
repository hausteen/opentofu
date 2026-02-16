####################################################################################################################################################################################
# Disclaimer:
  # this is the most elegant solution i could come up with. if you have a better way, let me know please.

# Purpose:
  # to allow opentofu to finish bootstrapping the kubernetes cluster by installing argocd and getting the argocd app of apps application deployed.
  # the intention is to run this phase once and then delete the state file, never to use or care about this phase again.

# Install method:
  # kustomize / kustomization

# Reasoning:
  # tofu fails to destroy the argocd app of apps resource (deployed with kustomize. destroy fails either due to 10 minute timeout or because of resource finalizers).
      # i don't want to deal with that so we put the argocd code over here and we'll essentially abandon this state file after it runs initially.
      # that way the main tofu environment works reliably and we don't have the destruction problem.
  # helm can't deploy my custom manifest file without me repackaging it.
  # i don't want tofu trying to reconcile the state every time i make a change to other infrastructure. the argocd
      # app of apps model may make changes to itself over time which could cause config drift.
  # null resources to run a custom script don't work well since i don't want to hardcode the paths to the tofu binary, kubeconfig path,
      # and manifest file locations.

####################################################################################################################################################################################
# install argocd
module "bootstrap_argocd" {
  source = "../../../modules/bootstrapArgocd"
}

# kustomize build argocd app of apps
data "kustomization_build" "argocd_app_of_apps" {
  path = "./kustomize/argocdAppOfApps/"
}

# kustomize install/ deploy argocd app of apps
resource "kustomization_resource" "argocd_app_of_apps_p1" {
  for_each   = data.kustomization_build.argocd_app_of_apps.ids_prio[1]
  manifest   = data.kustomization_build.argocd_app_of_apps.manifests[each.value]
  depends_on = [ data.kustomization_build.argocd_app_of_apps, module.bootstrap_argocd ]
}

####################################################################################################################################################################################
# Disclaimer:
  # this is the most elegant solution i could come up with. if you have a better way, let me know please.

# Purpose:
  # to allow opentofu to finish bootstrapping the kubernetes cluster by installing argocd and 
  # getting the argocd app of apps application deployed. 

# Install method:
  # kustomize / kustomization

# Reasoning:
  # tofu fails to destroy the argocd app of apps resource (deployed with kustomize. destroy fails either due to 10 minute timeout or because of resource finalizers).
      # i don't want to deal with that so we put the argocd code over here and we'll essentially abandon this state file after it runs initially.
      # that way the main tofu environment works reliably and we don't have the destruction problem.
  # the tofu kubernetes provider won't work since it requires the kubeconfig to exist before the tofu planning stage, which my
      # environment does not have the file at the planning stage.
  # helm can't deploy my custom manifest file without me repackaging it.
  # i don't want tofu trying to reconcile the state every time i make a change to other infrastructure. the argocd 
      # app of apps model may make changes to itself over time which could cause config drift.
  # null resources to run a custom script don't work well since i don't want to hardcode the paths to the tofu binary, kubeconfig path, 
      # and manifest file locations.

####################################################################################################################################################################################
# install argocd on the kubernetes cluster so gitops can take over

# create the argocd namespace
# kustomize build argocd namespace
# do not put a depends_on line in this data block or else tofu will complain about
# not knowing the identifiers before runtime.
data "kustomization_build" "argocd_namespace" {
  path = "kustomize/argocdNamespace/"
}

# kustomize deploy argocd namespace
# https://search.opentofu.org/provider/kbst/kustomization/latest/docs/datasources/build#attribute-reference
  # ids_prio - List of Kustomize resource IDs grouped into three sets.
  #     ids_prio[0]: Kind: Namespace and Kind: CustomResourceDefinition
  #     ids_prio[1]: All Kinds not in ids_prio[0] or ids_prio[2]
  #     ids_prio[2]: Kind: MutatingWebhookConfiguration and Kind: ValidatingWebhookConfiguration
resource "kustomization_resource" "argocd_namespace_p0" {
  for_each   = data.kustomization_build.argocd_namespace.ids_prio[0]
  manifest   = data.kustomization_build.argocd_namespace.manifests[each.value]
  depends_on = [ data.kustomization_build.argocd_namespace ]
}

# install argocd
# kustomize build argocd
data "kustomization_build" "argocd" {
  path = "kustomize/argocd/"
}

# kustomize deploy argocd
resource "kustomization_resource" "argocd_p0" {
  for_each   = data.kustomization_build.argocd.ids_prio[0]
  manifest   = data.kustomization_build.argocd.manifests[each.value]
  depends_on = [ data.kustomization_build.argocd, resource.kustomization_resource.argocd_namespace_p0 ]
}

resource "kustomization_resource" "argocd_p1" {
  for_each   = data.kustomization_build.argocd.ids_prio[1]
  manifest   = data.kustomization_build.argocd.manifests[each.value]
  depends_on = [ resource.kustomization_resource.argocd_p0 ]
}

resource "kustomization_resource" "argocd_p2" {
  for_each   = data.kustomization_build.argocd.ids_prio[2]
  manifest   = data.kustomization_build.argocd.manifests[each.value]
  depends_on = [ resource.kustomization_resource.argocd_p1 ]
}

# install argocd app of apps
# kustomize build argocd app of apps
data "kustomization_build" "argocd_app_of_apps" {
  path = "kustomize/argocdAppOfApps/"
}

# kustomize deploy argocd app of apps
resource "kustomization_resource" "argocd_app_of_apps_p1" {
  for_each   = data.kustomization_build.argocd_app_of_apps.ids_prio[1]
  manifest   = data.kustomization_build.argocd_app_of_apps.manifests[each.value]
  depends_on = [ data.kustomization_build.argocd_app_of_apps, resource.kustomization_resource.argocd_p1, resource.kustomization_resource.argocd_p2 ]
}

####################################################################################################################################################################################

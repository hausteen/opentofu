# install argocd on the kubernetes cluster so gitops can take over

# create the argocd namespace
# kustomize build argocd namespace
# do not put a depends_on line in this data block or else tofu will complain about
# not knowing the identifiers before runtime.
data "kustomization_build" "argocd_namespace" {
  path = "${path.module}/kustomize/argocdNamespace/"
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
  path = "${path.module}/kustomize/argocd/"
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

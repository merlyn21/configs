# Service account IAM token from key.json — the helm provider uses it to reach the cluster.
data "yandex_client_config" "client" {}

provider "helm" {
  kubernetes = {
    host                   = yandex_kubernetes_cluster.this.master[0].external_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
}

resource "helm_release" "argocd" {
  count = var.argocd_enabled ? 1 : 0

  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  # The first install pulls images from external registries — the default 5 minutes isn't enough.
  timeout = 900

  values = [yamlencode({
    # CRDs are removed along with the release (kept by default in the chart).
    crds = {
      keep = false
    }

    server = {
      service = {
        type = var.argocd_service_type
      }
    }
  })]

  # Without nodes, Argo CD pods stay Pending and helm_release waits until it times out.
  depends_on = [yandex_kubernetes_node_group.this]
}

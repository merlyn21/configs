resource "helm_release" "ingress_nginx" {
  count = var.ingress_nginx_enabled ? 1 : 0

  name             = "ingress-nginx"
  namespace        = var.ingress_nginx_namespace
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  timeout = 900

  values = [yamlencode({
    controller = {
      replicaCount = 1

      # LoadBalancer — YC creates a network load balancer with a public IP (billed).
      service = {
        type = var.ingress_nginx_service_type
      }

      # An Ingress without an explicit ingressClassName falls through to this controller.
      ingressClassResource = {
        default = true
      }
    }
  })]

  depends_on = [yandex_kubernetes_node_group.this]
}

resource "helm_release" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name             = "cert-manager"
  namespace        = var.cert_manager_namespace
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  timeout = 900

  values = [yamlencode({
    # Without this, the CRDs (Certificate, ClusterIssuer, etc.) won't be installed.
    crds = {
      enabled = true
    }
  })]

  depends_on = [yandex_kubernetes_node_group.this]
}

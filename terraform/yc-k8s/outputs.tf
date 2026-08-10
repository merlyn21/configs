output "cluster_id" {
  description = "Cluster ID"
  value       = yandex_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Cluster name"
  value       = yandex_kubernetes_cluster.this.name
}

output "cluster_external_endpoint" {
  description = "External Kubernetes API address"
  value       = yandex_kubernetes_cluster.this.master[0].external_v4_endpoint
}

output "cluster_internal_endpoint" {
  description = "Internal Kubernetes API address"
  value       = yandex_kubernetes_cluster.this.master[0].internal_v4_endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
  sensitive   = true
}

output "node_group_id" {
  description = "Node group ID"
  value       = yandex_kubernetes_node_group.this.id
}

output "kubeconfig_command" {
  description = "Command to add the cluster to kubeconfig"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.this.id} --external --force"
}

output "argocd_password_command" {
  description = "Command to get the Argo CD admin user's password"
  value = var.argocd_enabled ? join("", [
    "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret ",
    "-o jsonpath='{.data.password}' | base64 -d",
  ]) : null
}

output "argocd_access_command" {
  description = "Command to access the Argo CD UI (https://localhost:8080)"
  value = var.argocd_enabled && var.argocd_service_type == "ClusterIP" ? (
    "kubectl -n ${var.argocd_namespace} port-forward svc/argocd-server 8080:443"
  ) : null
}

output "vault_access_command" {
  description = "Command to access the Vault UI (http://localhost:8200)"
  value = var.vault_enabled && var.vault_service_type == "ClusterIP" ? (
    "kubectl -n ${var.vault_namespace} port-forward svc/vault-ui 8200:8200"
  ) : null
}

output "vault_root_token" {
  description = "Vault root token in dev mode"
  value       = var.vault_enabled && var.vault_dev_mode ? var.vault_dev_root_token : null
}

output "ingress_ip_command" {
  description = "Command to get the ingress controller's external address"
  value = var.ingress_nginx_enabled ? (
    "kubectl -n ${var.ingress_nginx_namespace} get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  ) : null
}

output "vault_init_command" {
  description = "Vault initialization and unseal (needed when vault_dev_mode = false)"
  value = var.vault_enabled && !var.vault_dev_mode ? join("", [
    "kubectl -n ${var.vault_namespace} exec -ti vault-0 -- vault operator init && ",
    "kubectl -n ${var.vault_namespace} exec -ti vault-0 -- vault operator unseal",
  ]) : null
}

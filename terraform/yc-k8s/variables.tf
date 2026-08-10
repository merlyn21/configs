variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "ID of the folder resources are created in"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "k8s-ai"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "release_channel" {
  description = "Update channel: RAPID, REGULAR or STABLE"
  type        = string
  default     = "REGULAR"
}

variable "network_id" {
  description = "ID of the existing VPC network"
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing subnet for the master and nodes"
  type        = string
}

variable "cluster_ipv4_range" {
  description = "CIDR for pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "service_ipv4_range" {
  description = "CIDR for services"
  type        = string
  default     = "10.30.0.0/16"
}

variable "node_cores" {
  description = "Number of vCPUs per node"
  type        = number
  default     = 2
}

variable "node_memory" {
  description = "Amount of RAM per node, GB"
  type        = number
  default     = 2
}

variable "node_core_fraction" {
  description = "Guaranteed vCPU share (5, 20, 50 or 100)"
  type        = number
  default     = 100
}

variable "node_disk_size" {
  description = "Node boot disk size, GB"
  type        = number
  default     = 64
}

variable "node_disk_type" {
  description = "Node disk type"
  type        = string
  default     = "network-ssd"
}

variable "node_count" {
  description = "Number of nodes in the group"
  type        = number
  default     = 1
}

variable "node_preemptible" {
  description = "Preemptible VMs (cheaper, live no longer than 24 hours)"
  type        = bool
  default     = false
}

variable "node_nat" {
  description = "Assign a public IP to nodes"
  type        = bool
  default     = false
}

variable "argocd_enabled" {
  description = "Install Argo CD into the cluster"
  type        = bool
  default     = true
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
  default     = "10.2.3"
}

variable "argocd_service_type" {
  description = "argocd-server service type: ClusterIP (access via port-forward) or LoadBalancer (public IP, billed)"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.argocd_service_type)
    error_message = "Allowed values: ClusterIP, NodePort or LoadBalancer."
  }
}

variable "vault_enabled" {
  description = "Install HashiCorp Vault into the cluster"
  type        = bool
  default     = true
}

variable "vault_namespace" {
  description = "Namespace for Vault"
  type        = string
  default     = "vault"
}

variable "vault_chart_version" {
  description = "vault Helm chart version"
  type        = string
  default     = "0.34.0"
}

variable "vault_dev_mode" {
  description = "dev mode: in-memory storage, automatic unseal, data is lost when the pod restarts. false — file-based storage on disk and manual unseal after every start"
  type        = bool
  default     = true
}

variable "vault_dev_root_token" {
  description = "Root token in dev mode (not used in prod — there the token is issued on initialization)"
  type        = string
  default     = "root"
}

variable "vault_storage_size" {
  description = "Disk size for Vault data (only when vault_dev_mode = false)"
  type        = string
  default     = "10Gi"
}

variable "vault_injector_enabled" {
  description = "Install the agent-injector — a sidecar that injects secrets into pods based on annotations"
  type        = bool
  default     = true
}

variable "vault_service_type" {
  description = "vault-ui service type: ClusterIP (access via port-forward) or LoadBalancer (public IP, billed)"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.vault_service_type)
    error_message = "Allowed values: ClusterIP, NodePort or LoadBalancer."
  }
}

variable "ingress_nginx_enabled" {
  description = "Install ingress-nginx into the cluster"
  type        = bool
  default     = true
}

variable "ingress_nginx_namespace" {
  description = "Namespace for ingress-nginx"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.15.1"
}

variable "ingress_nginx_service_type" {
  description = "Controller service type: LoadBalancer (YC creates a load balancer with a public IP, billed), NodePort (via the node's public IP) or ClusterIP"
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.ingress_nginx_service_type)
    error_message = "Allowed values: ClusterIP, NodePort or LoadBalancer."
  }
}

variable "cert_manager_enabled" {
  description = "Install cert-manager (TLS certificate issuance, including Let's Encrypt)"
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.21.1"
}

variable "ssh_public_key" {
  description = "Public SSH key for node access (empty — SSH access is not configured)"
  type        = string
  default     = ""
}

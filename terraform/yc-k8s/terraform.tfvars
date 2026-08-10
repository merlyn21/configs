cloud_id  = ""
folder_id = ""
zone      = "ru-central1-a"

# Existing network and subnet (vpc-kub-ru-central1-a)
network_id = ""
subnet_id  = ""

cluster_name = "k8s-test"

# Node: 2 vCPU / 4 GB
node_cores       = 2
node_memory      = 4
node_count       = 1
node_preemptible = true

# Public IP on the node: the vpc-kub subnet has no NAT gateway, so without a
# public address the node won't be able to pull images. ~0.26 RUB/hour (~192 RUB/month).
node_nat = true

# What to install into the cluster: true — installed, false — not installed
# (and removed on the next apply if it was previously installed)
argocd_enabled        = true
vault_enabled         = false
ingress_nginx_enabled = false
cert_manager_enabled  = false

# LoadBalancer — YC creates a network load balancer with a public IP (billed).
# NodePort — access via the node's own public IP, no load balancer.
ingress_nginx_service_type = "LoadBalancer"

# SSH access to nodes (optional)
ssh_public_key = ""

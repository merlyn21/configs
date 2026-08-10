# The network and subnet already exist in the folder — Terraform doesn't
# create or modify them, only reads them.
data "yandex_vpc_network" "this" {
  network_id = var.network_id
}

data "yandex_vpc_subnet" "this" {
  subnet_id = var.subnet_id
}

resource "yandex_vpc_security_group" "k8s_main" {
  name        = "${var.cluster_name}-sg"
  description = "Rules for the master and nodes of cluster ${var.cluster_name}"
  network_id  = data.yandex_vpc_network.this.id

  ingress {
    protocol          = "TCP"
    description       = "Health checks from the load balancer subnets"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Traffic between the master and nodes within the group"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol       = "ANY"
    description    = "Traffic between pods and services"
    v4_cidr_blocks = concat(data.yandex_vpc_subnet.this.v4_cidr_blocks, [var.cluster_ipv4_range, var.service_ipv4_range])
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "ICMP"
    description    = "ICMP from internal networks"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "External access to the cluster API (port 443)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "External access to the cluster API (port 6443)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # The YC load balancer forwards client traffic to node NodePorts, so this
  # range needs to be open externally — otherwise ingress-nginx would only
  # get health checks, and user requests would time out.
  dynamic "ingress" {
    for_each = var.ingress_nginx_enabled && var.ingress_nginx_service_type != "ClusterIP" ? [1] : []

    content {
      protocol       = "TCP"
      description    = "NodePort range for ingress-nginx"
      v4_cidr_blocks = ["0.0.0.0/0"]
      from_port      = 30000
      to_port        = 32767
    }
  }

  dynamic "ingress" {
    for_each = var.ssh_public_key == "" ? [] : [1]

    content {
      protocol       = "TCP"
      description    = "SSH to nodes"
      v4_cidr_blocks = ["0.0.0.0/0"]
      port           = 22
    }
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_kubernetes_cluster" "this" {
  name        = var.cluster_name
  description = "Managed Kubernetes cluster ${var.cluster_name}"

  network_id = data.yandex_vpc_network.this.id

  cluster_ipv4_range = var.cluster_ipv4_range
  service_ipv4_range = var.service_ipv4_range

  master {
    version   = var.k8s_version
    public_ip = true

    # Zonal master — the cheapest option.
    # For high availability, switch to regional with three zones.
    zonal {
      zone      = data.yandex_vpc_subnet.this.zone
      subnet_id = data.yandex_vpc_subnet.this.id
    }

    security_group_ids = [yandex_vpc_security_group.k8s_main.id]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "23:00"
        duration   = "3h"
      }
    }
  }

  release_channel         = var.release_channel
  service_account_id      = yandex_iam_service_account.cluster.id
  node_service_account_id = yandex_iam_service_account.nodes.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_agent,
    yandex_resourcemanager_folder_iam_member.cluster_vpc,
    yandex_resourcemanager_folder_iam_member.cluster_logging,
    yandex_resourcemanager_folder_iam_member.nodes_puller,
  ]
}

resource "yandex_kubernetes_node_group" "this" {
  cluster_id  = yandex_kubernetes_cluster.this.id
  name        = "${var.cluster_name}-ng"
  description = "Node group: ${var.node_cores} vCPU / ${var.node_memory} GB"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = var.node_nat
      subnet_ids         = [data.yandex_vpc_subnet.this.id]
      security_group_ids = [yandex_vpc_security_group.k8s_main.id]
    }

    resources {
      cores         = var.node_cores
      memory        = var.node_memory
      core_fraction = var.node_core_fraction
    }

    boot_disk {
      type = var.node_disk_type
      size = var.node_disk_size
    }

    scheduling_policy {
      preemptible = var.node_preemptible
    }

    container_runtime {
      type = "containerd"
    }

    metadata = var.ssh_public_key == "" ? {} : {
      "ssh-keys" = "ubuntu:${var.ssh_public_key}"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = data.yandex_vpc_subnet.this.zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      start_time = "23:00"
      duration   = "3h"
    }
  }
}

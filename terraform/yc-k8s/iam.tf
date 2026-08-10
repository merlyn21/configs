resource "yandex_iam_service_account" "cluster" {
  name        = "${var.cluster_name}-cluster-sa"
  description = "Service account for the master of cluster ${var.cluster_name}"
}

resource "yandex_iam_service_account" "nodes" {
  name        = "${var.cluster_name}-nodes-sa"
  description = "Service account for the nodes of cluster ${var.cluster_name}"
}

# Manages cluster resources (networks, load balancers, disks).
resource "yandex_resourcemanager_folder_iam_member" "cluster_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

# Assigns public addresses to LoadBalancer-type service load balancers.
resource "yandex_resourcemanager_folder_iam_member" "cluster_vpc" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

# Writes cluster logs to Cloud Logging.
resource "yandex_resourcemanager_folder_iam_member" "cluster_logging" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

# Pulls images from Yandex Container Registry.
resource "yandex_resourcemanager_folder_iam_member" "nodes_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.nodes.id}"
}

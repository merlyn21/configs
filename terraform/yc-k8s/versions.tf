terraform {
  required_version = ">= 1.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  # Authentication: the YC_TOKEN environment variable (OAuth/IAM)
  # or YC_SERVICE_ACCOUNT_KEY_FILE for a service account key.
}

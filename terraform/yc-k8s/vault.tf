resource "helm_release" "vault" {
  count = var.vault_enabled ? 1 : 0

  name             = "vault"
  namespace        = var.vault_namespace
  create_namespace = true

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.vault_chart_version

  timeout = 900

  # Two separate yamlencode calls instead of one object with a ternary inside:
  # ? : branches with different sets of fields make Terraform unify them into
  # map(string), so boolean values end up in the chart as strings ("got string,
  # want boolean"). A condition between already-rendered strings avoids this.
  values = [
    yamlencode({
      injector = {
        enabled = var.vault_injector_enabled
      }

      ui = {
        enabled     = true
        serviceType = var.vault_service_type
      }
    }),

    # dev mode: in-memory storage, Vault unseals itself on startup.
    # standalone: file-based storage on disk, requires manual unseal after
    # every pod start (see output vault_init_command).
    var.vault_dev_mode ? yamlencode({
      server = {
        dev = {
          enabled      = true
          devRootToken = var.vault_dev_root_token
        }
      }
      }) : yamlencode({
      server = {
        standalone = {
          enabled = true
        }

        dataStorage = {
          enabled = true
          size    = var.vault_storage_size
        }
      }
    }),
  ]

  depends_on = [yandex_kubernetes_node_group.this]
}

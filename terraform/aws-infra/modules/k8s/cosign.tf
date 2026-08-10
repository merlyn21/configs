data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # 123456789012.dkr.ecr.us-east-2.amazonaws.com/*
  ecr_image_reference = format(
    "%s.dkr.ecr.%s.%s/*",
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.name,
    data.aws_partition.current.dns_suffix
  )
}

resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  namespace        = "kyverno"
  create_namespace = true
  version          = var.kyverno_version

  values = [
    yamlencode({
      features = {
        forceFailurePolicyIgnore = {
          enabled = true
        }
      }

      admissionController = {
        replicas = 3

        priorityClassName = "system-cluster-critical"

        extraVolumes = [
            {
            name     = "ecr-cache"
            emptyDir = {}
            }
        ]
        extraVolumeMounts = [
            {
            name      = "ecr-cache"
            mountPath = "/home/nonroot/.ecr"
            }
        ]

        podDisruptionBudget = {
          enabled      = true
          minAvailable = 2
        }

        resources = {
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }

        apiPriorityAndFairness = false
      }

      backgroundController = {
        replicas = 2
        priorityClassName = "system-cluster-critical"
        podDisruptionBudget = {
          enabled      = true
          minAvailable = 1
        }
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }

      reportsController = {
        replicas = 2
        priorityClassName = "system-cluster-critical"
        podDisruptionBudget = {
          enabled      = true
          minAvailable = 1
        }
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }

      cleanupController = {
        replicas = 2
        priorityClassName = "system-cluster-critical"
        podDisruptionBudget = {
          enabled      = true
          minAvailable = 1
        }
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "300m", memory = "512Mi" }
        }
      }
    })
  ]
}

locals {
  validation_action = var.kyverno_enforce ? "Enforce" : "Audit"

  kyverno_policy = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "verify-images-keyless"
      annotations = {
        "policies.kyverno.io/title"       = "Verify container images with cosign (keyless)"
        "policies.kyverno.io/description" = "Verifies ECR images signed via GitHub Actions OIDC. Audit by default."
      }
    }
    spec = {
      validationFailureAction = local.validation_action
      background              = false
      webhookTimeoutSeconds   = 30

      rules = [
        {
          name = "verify-ecr-images-in-selected-namespaces"
          match = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = var.kyverno_target_namespaces
                }
              }
            ]
          }

          verifyImages = [
            {
              imageReferences = [local.ecr_image_reference]
              mutateDigest    = false
              verifyDigest    = false

              attestors = [
                {
                  entries = [
                    {
                      keyless = {
                        issuer        = var.cosign_oidc_issuer
                        subjectRegExp = var.cosign_subject_regexp
                        rekor = {
                            url = "https://rekor.sigstore.dev"
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "kyverno_verify_images" {
  count      = var.enable_kyverno_policy ? 1 : 0
  manifest   = local.kyverno_policy
  depends_on = [helm_release.kyverno]
}
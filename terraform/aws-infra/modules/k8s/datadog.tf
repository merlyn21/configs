locals {
  rds_host = split(":", var.db_primary_endpoint)[0]
}

resource "kubernetes_namespace" "datadog" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name = "datadog"
  }
}

resource "helm_release" "datadog_operator" {
  count = (var.stage != "dev1") ? 1 : 0
  name       = "datadog-operator"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog-operator"
  namespace  = kubernetes_namespace.datadog[0].metadata[0].name
  version    = "2.15.0" 

  depends_on = [kubernetes_namespace.datadog]
}

resource "kubernetes_secret" "datadog_secret" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name      = "datadog-secret"
    namespace = kubernetes_namespace.datadog[0].metadata[0].name
  }

  data = {
    api-key = var.datadog_api_key
  }

  type = "Opaque"
  
  depends_on = [kubernetes_namespace.datadog]
}

resource "kubectl_manifest" "datadog_agent" {
  count = (var.stage != "dev1") ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "datadoghq.com/v2alpha1"
    kind       = "DatadogAgent"
    metadata = {
      name      = "datadog"
      namespace = kubernetes_namespace.datadog[0].metadata[0].name
    }
    spec = {
      global = {
        clusterName = "${var.project}-eks"
        site        = "us5.datadoghq.com"
        credentials = {
          apiSecret = {
            secretName = kubernetes_secret.datadog_secret[0].metadata[0].name
            keyName    = "api-key"
          }
        }
        tags = [
          "env:${var.stage}",
          "cluster:${var.project}-eks",
          "project:${var.project}",
          "team:acmeparts",
          "aws_account:${data.aws_caller_identity.current.account_id}"
        ]
        kubernetesNodeLabelsAsTags = {
          "karpenter.sh/nodepool"       = "karpenter_nodepool"
          "topology.kubernetes.io/zone" = "kube_zone"
          "karpenter.sh/nodepool" = "karpenter_nodepool"
          "topology.kubernetes.io/zone" = "kube_zone"
          "node.kubernetes.io/instance-type" = "node_instance_type"
          "kubernetes.io/arch" = "node_arch"
          "kubernetes.io/os" = "node_os"
        }
        kubernetesPodLabelsAsTags = {
          "app"  = "kube_app"
          "tier" = "kube_tier"
          "env"  = "kube_env"
          "version" = "kube_version"
          "component"  = "kube_component"
          "app.kubernetes.io/name" = "kube_app_name"
          "app.kubernetes.io/instance" = "kube_app_instance"
          "app.kubernetes.io/version" = "kube_app_version"
          "app.kubernetes.io/component" = "kube_app_component"
        }
      }
      features = {
        logCollection = {
          enabled            = true
          containerCollectAll = true
        }
        apm = {
          enabled = false
        }
        liveProcessCollection = {
          enabled = false
        }
        liveContainerCollection = {
          enabled = true
        }
        npm = {
          enabled = false
        }
        openMetricsCollection = {
          enabled = true
        }
        orchestratorExplorer = { 
          enabled = false
        }
        kubeStateMetricsCore    = { 
          enabled = true 
          config = {
            labelsAsTags = {
              "app.kubernetes.io/instance"  = "kube_instance"
              "app"                         = "service"
              "component"                   = "component"
              "tier"                        = "stack"
              "env"                         = "env"
              "version"                     = "version"
              "app.kubernetes.io/name"      = "service"
              "app.kubernetes.io/component" = "component"
              "app.kubernetes.io/version"   = "version"
              "app.kubernetes.io/instance"  = "kube_instance"
            }
          }
        }
        cws = { 
          enabled = false
        }
        cspm = { 
          enabled = false
        }
        compliance = { 
          enabled = false
        }
        clusterChecks = {
          enabled = true
        }
        databaseMonitoring = {
          enabled = true
        }
      }
      override = {
        clusterAgent = {
          image = {
            name = "cluster-agent"
            tag  = "7.76.0"
          }
          extraConfd = {
            configMap = {
              name = kubernetes_config_map.datadog_karpenter_cluster_config[0].metadata[0].name
            }
          }
          env = [
          {
            name  = "DD_CLUSTER_CHECKS_ENABLED"
            value = "true"
          },
          {
            name  = "DD_EXTRA_CONFIG_PROVIDERS"
            value = "clusterchecks"
          },
          {
            name  = "DD_CLOUD_PROVIDER_METADATA"
            value = "aws"
          },
          {
            name  = "DD_SECRET_BACKEND_COMMAND"
            value = "/readsecret_multiple_providers.sh"
          },
          {
            name  = "DD_SECRET_BACKEND_ARGUMENTS"
            value = "--provider=k8s_secret --fail-on-missing"
          }
          ]
          replicas = 2
        }
        clusterChecksRunner = {
          image = {
            name = "agent"
            tag  = "7.76.0"
          }
          enabled  = true
          replicas = 1
          env = [
            {
              name  = "DD_CLOUD_PROVIDER_METADATA"
              value = "aws"
            },
            {
              name  = "DD_SECRET_BACKEND_COMMAND"
              value = "/readsecret_multiple_providers.sh"
            },
            {
              name  = "DD_SECRET_BACKEND_ARGUMENTS"
              value = "--provider=k8s_secret --fail-on-missing"
            }
          ]
          resources = {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
        securityAgent = {
          enabled = false
        }
        nodeAgent = {
          image = {
            name = "agent"
            tag  = "7.76.0"
          }
          systemProbe = {
            enabled = false
          }
          env = [
            {
              name  = "DD_METRICS_ENABLED"
              value = "false"
            },
            {
              name  = "DD_SYSTEM_PROBE_ENABLED"
              value = "false"
            },
            {
              name  = "DD_PROCESS_AGENT_ENABLED"
              value = "false"
            },
            {
              name  = "DD_NETWORK_MONITORING_ENABLED"
              value = "false"
              },
            { 
              name = "DD_DOGSTATSD_PORT"            
              value = "8125" 
              },
            { 
              name = "DD_DOGSTATSD_TAG_CARDINALITY"
              value = "low" 
              },
            { 
              name = "DD_CONTAINER_INCLUDE_METRICS"
              value = "kube_namespace:backend" 
              },
            { 
              name = "DD_CONTAINER_INCLUDE_LOGS"
              value = "kube_namespace:backend" 
              },
            {
              name = "DD_CONTAINER_EXCLUDE"
              value = "kube_namespace:datadog kube_namespace:default kube_namespace:kafkaui kube_namespace:karpenter kube_namespace:kube-node-lease kube_namespace:kube-public kube_namespace:kube-system kube_namespace:pgadmin kube_namespace:pgbouncer kube_namespace:kyverno"
            },
            {
              name = "DD_CONTAINER_EXCLUDE_METRICS"
              value = "kube_namespace:datadog kube_namespace:default kube_namespace:kafkaui kube_namespace:karpenter kube_namespace:kube-node-lease kube_namespace:kube-public kube_namespace:kube-system kube_namespace:pgadmin kube_namespace:pgbouncer kube_namespace:kyverno"
            },
            { 
              name = "DD_COLLECT_EC2_TAGS"
              value = "true" 
            },
            { 
              name = "DD_EC2_PREFER_IMDSV2"
              value = "true" 
            },
            {
              name  = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC"
              value = "true"
            },
            {
              name  = "DD_KUBERNETES_POD_LABELS_AS_TAGS"
              value = jsonencode({
                "app"                         = "service"
                "component"                   = "component"
                "tier"                        = "stack"
                "env"                         = "env"
                "version"                     = "version"
                "app.kubernetes.io/name"      = "service"
                "app.kubernetes.io/component" = "component"
                "app.kubernetes.io/version"   = "version"
              })
              },
              {
                name  = "DD_KUBERNETES_NODE_LABELS_AS_TAGS"
                value = jsonencode({
                  "topology.kubernetes.io/zone"      = "availability_zone"
                  "node.kubernetes.io/instance-type" = "instance_type"
                })
              },
              {
                name  = "DD_KUBERNETES_NAMESPACE_LABELS_AS_TAGS"
                value = jsonencode({
                  "project" = "project"
                  "env"     = "env"
                })
              },
              {
                name  = "DD_CHECKS_TAG_CARDINALITY"
                value = "orchestrator"
              },
              {
                name = "DD_HOSTNAME"
                valueFrom = {
                  fieldRef = {
                    apiVersion = "v1"
                    fieldPath  = "spec.nodeName"
                  }
                }
              }
          ]

          resources = {
            limits = {
              cpu    = "50m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  })
  depends_on = [
    helm_release.datadog_operator,
    kubernetes_secret.datadog_secret,
    kubernetes_config_map.datadog_karpenter_cluster_config
  ]
}

resource "kubernetes_config_map" "datadog_karpenter_cluster_config" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name      = "datadog-karpenter-cluster-config"
    namespace = kubernetes_namespace.datadog[0].metadata[0].name
  }

  data = {
    "karpenter.yaml" = <<-EOT
cluster_check: true
init_config: {}
instances:
  - openmetrics_endpoint: "http://karpenter.karpenter.svc.cluster.local:8000/metrics"
    namespace: "karpenter"
    metrics:
    metrics:
      - "karpenter_nodes_created_total"
      - "karpenter_nodes_terminated_total"
      - "karpenter_nodes_allocatable_cpu_cores"
      - "karpenter_nodes_allocatable_memory_bytes"
      - "karpenter_pods_startup_duration_seconds"
      - "karpenter_provisioner_scheduling_queue_depth"
      - "karpenter_provisioner_scheduling_simulation_duration_seconds"
    tags:
      - "karpenter:true"
      - "env:${var.stage}"
      - "cluster:${var.project}-eks"
      - "service:karpenter"
      - "component:autoscaler"
      - "stack:infrastructure"
      - "project:${var.project}"
      - "region:${var.region}"
      - "account:${data.aws_caller_identity.current.account_id}"
EOT
    "postgres.yaml" = <<-EOT
cluster_check: true
init_config:
instances:
  - host: "${local.rds_host}"
    port: 5432
    username: datadog
    password: "ENC[k8s_secret@datadog/datadog-postgres-secret/password]"
    dbm: true
    dbname: postgres
    sslmode: require

    database_autodiscovery:
      enabled: true
    collect_schemas:
      enabled: true


    aws:
      instance_endpoint: "${local.rds_host}"
      region: "${var.region}"
    
    tags:
      - "env:${var.stage}"
      - "cluster:${var.project}-eks"
      - "project:${var.project}"
      - "team:acmeparts"
      - "service:postgres"
      - "component:database"
      - "stack:data"
      - "region:${var.region}"
      - "account:${data.aws_caller_identity.current.account_id}"
    
    query_metrics:
      enabled: true
      run_sync: false
      collection_interval: 10
    
    query_samples:
      enabled: true
      collection_interval: 1
    
    query_activity:
      enabled: true
      collection_interval: 10
    
    settings:
      enabled: true
      collection_interval: 600
EOT
  }
}

resource "kubernetes_secret" "datadog_postgres_secret" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name      = "datadog-postgres-secret"
    namespace = kubernetes_namespace.datadog[0].metadata[0].name
  }

  data = {
    password = var.datadog_postgres_password  
  }

  type = "Opaque"
  
  depends_on = [kubernetes_namespace.datadog]
}

resource "kubernetes_service_account" "datadog_cluster_checks_runner" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name      = "datadog-cluster-checks-runner"
    namespace = kubernetes_namespace.datadog[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "datadog-agent-deployment"
      "app.kubernetes.io/instance"   = "datadog-cluster-checks-runner"
      "app.kubernetes.io/component"  = "cluster-checks-runner"
      "app.kubernetes.io/managed-by" = "datadog-operator"
    }
  }
  depends_on = [kubernetes_namespace.datadog]
}

resource "kubernetes_cluster_role" "datadog_cluster_checks_runner" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name = "datadog-cluster-checks-runner"
    labels = {
      "app.kubernetes.io/name"       = "datadog-agent-deployment"
      "app.kubernetes.io/managed-by" = "datadog-operator"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "endpoints", "services"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "datadog_cluster_checks_runner" {
  count = (var.stage != "dev1") ? 1 : 0
  metadata {
    name = "datadog-cluster-checks-runner"
    labels = {
      "app.kubernetes.io/name"       = "datadog-agent-deployment"
      "app.kubernetes.io/managed-by" = "datadog-operator"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.datadog_cluster_checks_runner[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.datadog_cluster_checks_runner[0].metadata[0].name
    namespace = kubernetes_namespace.datadog[0].metadata[0].name
  }
}

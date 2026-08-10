data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_name
}

locals {
  db_name = "*"
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)
  db_password    = local.db_credentials.password
  db_username    = local.db_credentials.username
  db_port        = "5432"
  db_host        = split(":", var.db_primary_endpoint)[0]
}

resource "kubernetes_namespace" "pgbouncer" {
  metadata {
    name = "pgbouncer"
  }
}

# resource "kubernetes_config_map" "pgbouncer_ini" {
#   metadata {
#     name      = "pgbouncer-ini"
#     namespace = kubernetes_namespace.pgbouncer.metadata[0].name
#   }

#   data = {
#     "pgbouncer.ini" = <<-EOT
#       [databases]
#       ${local.db_name} = host=${local.db_host} port=${local.db_port}

#       [pgbouncer]
#       listen_addr       = 0.0.0.0
#       listen_port       = 6432
#       auth_type         = md5
#       auth_file         = /etc/pgbouncer/userlist.txt
#       pool_mode         = transaction
#       max_client_conn   = 1000
#       default_pool_size = 25
#       logfile           = /dev/stdout
#     EOT
#   }
# }

resource "kubernetes_secret" "pgbouncer_auth_file" {
  metadata {
    name      = "pgbouncer-auth"
    namespace = kubernetes_namespace.pgbouncer.metadata[0].name
  }
  type = "Opaque"

  data = {
    "userlist.txt" = "\"${local.db_username}\" \"${local.db_password}\""
  }
}


resource "helm_release" "pgbouncer" {
  name       = "pgbouncer"
  namespace  = kubernetes_namespace.pgbouncer.metadata[0].name
  chart      = "${path.module}/pgbouncer-helm-chart"

  values = [
    yamlencode({
      replicaCount: 2

    userlist = {
      enabled: true
      secret: kubernetes_secret.pgbouncer_auth_file.metadata[0].name  
    }

    pgbouncerExporter = {
      enabled: false
    }
  
    databases = {
      "${local.db_name}" = {
        host = local.db_host
        port = local.db_port
      }
    }

    pgbouncer = { 
      listen_addr = "0.0.0.0"
      listen_port = "6432"
      pool_mode = "transaction"
      default_pool_size = "30"
      min_pool_size = "10"
      reserve_pool_size = "20"
      reserve_pool_timeout = "3"
      max_client_conn = "2000"
      max_db_connections = "150"

      server_idle_timeout = "600"        
      server_lifetime = "3600"            
      server_connect_timeout = "15"      
      query_timeout = "0"                
      query_wait_timeout = "120"         
      client_idle_timeout = "0"          

      auth_type = "scram-sha-256"
      auth_file = "/etc/pgbouncer/userlist.txt"
      server_tls_sslmode = "require"
      ignore_startup_parameters = "extra_float_digits"
      
    }

    # extraVolumes = [
    #     {
    #       name      = "pgbouncer-ini"
    #       mountPath = "/etc/pgbouncer/pgbouncer.ini"
    #       subPath   = "pgbouncer.ini"
    #       readOnly  = true
    #       configMap = {
    #         name = kubernetes_config_map.pgbouncer_ini.metadata[0].name
    #       }
    #     }
    #   ]

    })
  ]

  depends_on = [
    kubernetes_namespace.pgbouncer,
    kubernetes_secret.pgbouncer_auth_file
  ]
}
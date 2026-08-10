project = "acmeparts"
region = "us-east-2"
stage = "stage"

db_read_replicas_count = 0
db_backup_retention_period = 7
db_instance_class = "db.m7g.2xlarge"
db_version = "17.9"
db_storage = "300"
db_multiaz = "false"
db_immediately = "true"
db_skip_final_snapshot = "true"

rds_parameters = {
  "max_connections"        = "1000"
  "shared_preload_libraries"  = "pg_stat_statements"
  "pg_stat_statements.track"  = "all"
  "pg_stat_statements.max"    = "10000"
  "track_activity_query_size" = "4096"
}

eks_version = "1.34"
eks_desired_capacity = 2
eks_min_instances = 1
eks_max_instances = 4
eks_instance_type = "r6a.xlarge"
eks_metric_version = "3.12.2"

kafka_version = "3.6.0"
kafka_instance_type = "kafka.m7g.large"
kafka_number_of_broker_nodes = 2
kafka_volume_size = 150
kafka_volume_type = "gp3"
kafka_monitoring = "DEFAULT"
kafka_server_properties = {
  "num.partitions"                 = 6
  "min.insync.replicas"            = 1
  "compression.type"               = "lz4"
  "auto.create.topics.enable"      = "true"
  "delete.topic.enable"            = "true"
  "socket.send.buffer.bytes"       = "131072"
  "replica.fetch.max.bytes"        = "10485760"
  "message.max.bytes"              = "5242880"
  "unclean.leader.election.enable" = "false"
  "log.retention.hours"            = "168"
  "log.segment.bytes"              = "1073741824"
}

s3_imports = "acmeparts-stage-imports"
s3_buckets = {
  s3_export_sources = "acmeparts-stage-export-sources"
  s3_exports = "acmeparts-stage-exports"
  s3_delta = "acmeparts-stage-delta"
  s3_images = "acmeparts-stage-images"
  s3_files = "acmeparts-stage-files"
  s3_dqc = "acmeparts-stage-dq-results"
  s3_raw = "acmeparts-stage-raw"
  s3_ods = "acmeparts-stage-ods"
}
aws_cloudfront_images_arn = "arn:aws:cloudfront::333333333333:distribution/E3R03G3SCB9Q92"

opensearch_engine_version = "OpenSearch_2.17"
opensearch_node_type  = "om2.large.search"
opensearch_node_count = 3
opensearch_master_type = "r7g.medium.search"
opensearch_dedicated_master_enabled = false
opensearch_master_count = 1
opensearch_availability_zone_count = 3
opensearch_volume_size = 50

redis_node_type = "cache.t3.micro"
redis_parameter_group_name = "default.redis6.x"
redis_num_cache_nodes = 1

vpc_cidr = "10.20.0.0/16"
domain_name = "acmeparts-stage.acmeparts.example"

cloudfront_domain_name = "api.acmeparts-stage.acmeparts.example"
domain_name_alb = "alb.acmeparts-stage.acmeparts.example"
certificate_arn = ""

cloudfront_domain_name_iag = "api-iag.acmeparts-stage.acmeparts.example"
domain_name_alb_iag = "alb-iag.acmeparts-stage.acmeparts.example"
certificate_arn_iag = ""
cloudfront_domain_name_files = "files.acmeparts-stage.acmeparts.example"
certificate_arn_files = ""

cloudfront_domain_name_dqc = "data-quality-checker.acmeparts-stage.acmeparts.example"
domain_name_alb_dqc = "data-quality-checker.acmeparts-stage.acmeparts.example"
certificate_arn_dqc = ""

waf_limit = 2000
auth_user = "admin-pf-stage"
create_waf = true
waf_allowed_ip = "203.0.113.14"

datadog_external_id = "8c0252cd87374f218125cd8d14652e7e"
oidc_host = "login-staging.acmeparts.example"

# See schedule documented: https://acme-corp.atlassian.net/wiki/spaces/TRP/pages/2010579012/DS+Schedule#Tasks-to-run
scheduled_exporters = {
  "exporter-mapping-akas" = {
    exporter_name       = "exporter-mapping-akas"
    schedule_expression = "cron(30 10 * * ? *)"
    enabled             = true
    description         = "Generates AKAs file from both Legacy DB and New DB (admins may create new AKAs for products)"
  }

  "products-exporter" = {
    exporter_name       = "exporter-products"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Legacy products exporter. After AKAs finishes"
  }

  "superseding-exporter" = {
    exporter_name       = "exporter-superseding"
    schedule_expression = "cron(0 11 * * ? *)"
    enabled             = true
    description         = "Legacy superseding exporter"
  }

  "legacy-offers-exporter" = {
    exporter_name       = "exporter-offers"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Legacy offers exporter. After AKAs finishes"
  }

  "users-exporter" = {
    exporter_name       = "exporter-user"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = false
    description         = "Users exporter (directly from Legacy DB into New DB). No dependencies"
  }

  "users-csv-companies-exporter" = {
    exporter_name       = "exporter-user-csv-companies"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Users CSV companies exporter. No dependencies"
  }

  "users-csv-subscriptions-exporter" = {
    exporter_name       = "exporter-user-csv-subscriptions"
    schedule_expression = "cron(0 11 * * ? *)"
    enabled             = true
    description         = "Users CSV subscriptions exporter. No dependencies"
  }

  "users-csv-users-exporter" = {
    exporter_name       = "exporter-user-csv-users"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Users CSV users exporter. After Users CSV companies import finishes"
  }

  "users-csv-company-administrators-exporter" = {
    exporter_name       = "exporter-user-csv-company_administrators"
    schedule_expression = "cron(0 12 * * ? *)"
    enabled             = true
    description         = "Users CSV company administrators exporter. After Users CSV users import finishes"
  }

  "documents-exporter" = {
    exporter_name       = "exporter-documents"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Documents exporter. No dependencies"
  }

  "company-markups-exporter" = {
    exporter_name       = "exporter-company"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "Company markups exporter. No dependencies"
  }

  "user-part-notes-exporter" = {
    exporter_name       = "exporter-user-part-notes"
    schedule_expression = "cron(0 13 * * ? *)"
    enabled             = true
    description         = "User part notes. After Legacy offers import finishes"
  }

  "company-prices-map-exporter" = {
    exporter_name       = "exporter-company-prices-map"
    schedule_expression = "cron(0 13 * * ? *)"
    enabled             = true
    description         = "Company prices map exporter (price lists). After Legacy offers import finishes"
  }

  "company-prices-price-exporter" = {
    exporter_name       = "exporter-company-prices-price"
    schedule_expression = "cron(30 13 * * ? *)"
    enabled             = true
    description         = "Company prices price exporter (prices for price lists). Only after company prices map import finishes"
  }

  "oem-types-exporter" = {
    exporter_name       = "exporter-oem-types"
    schedule_expression = "cron(40 10 * * ? *)"
    enabled             = true
    description         = "OEM types exporter. No dependencies"
  }

  "oem-data-exporter" = {
    exporter_name       = "exporter-oem-data"
    schedule_expression = "cron(0 14 * * ? *)"
    enabled             = true
    description         = "OEM data exporter (VINs + products). After all products imported and after OEM types import finishes"
  }

  "superseding-exporter" = {
    exporter_name       = "exporter-superseding"
    schedule_expression = "cron(0 13 * * ? *)"
    enabled             = true
    description         = "Superseding parts exporter. After all products imported"
  }

  "company1-api-full-exporter" = {
    exporter_name       = "exporter-company1-api-full"
    schedule_expression = "cron(0 6 ? * SAT *)"
    enabled             = true
    description         = "Company1 API exporter (full dataset: plenty of archives), downloads ZIPs. No dependencies"
  }

  "company1-unzip-s3-full-exporter" = {
    exporter_name       = "exporter-company1-unzip-s3-full"
    schedule_expression = "cron(0 9 ? * SAT *)"
    enabled             = true
    description         = "Unzipping of downloaded archives (full dataset: plenty of archives). Requires Company1 API full exporter to finish"
  }

  "company1-api-delta-exporter" = {
    exporter_name       = "exporter-company1-api-delta"
    schedule_expression = "cron(0 6 ? * SAT *)"
    enabled             = true
    description         = "Company1 API exporter (delta archive). No dependencies"
  }

  "company1-unzip-s3-delta-exporter" = {
    exporter_name       = "exporter-company1-unzip-s3-delta"
    schedule_expression = "cron(15 6 ? * SAT *)"
    enabled             = true
    description         = "Unzipping of downloaded delta archive. Requires Company1 API delta exporter to finish"
  }

  "company1-process-offers-full-exporter" = {
    exporter_name       = "exporter-company1-process-offers-full"
    schedule_expression = "cron(0 8 ? * MON *)"
    enabled             = true
    description         = "Company1 processor of downloaded (full dataset) for offers. Requires data to be downloaded and unzipped first, otherwise has nothing to process"
  }

  "company1-process-oem-types-full-exporter" = {
    exporter_name       = "exporter-company1-process-oem-types-full"
    schedule_expression = "cron(0 8 ? * MON *)"
    enabled             = true
    description         = "Company1 processor of downloaded (full dataset) for OEM types. Requires data to be downloaded and unzipped first, otherwise has nothing to process"
  }

  "company1-process-oem-product-full-exporter" = {
    exporter_name       = "exporter-company1-process-oem-product-full"
    schedule_expression = "cron(0 9 ? * MON *)"
    enabled             = true
    description         = "Company1 processor of downloaded (full dataset) for OEM-products relations. Requires data to be downloaded and unzipped first, otherwise has nothing to process"
  }

  "company2-exporter" = {
    exporter_name       = "exporter-company2"
    schedule_expression = "cron(30 13 * * ? *)"
    enabled             = true
    description         = "Company2 exporter. Company2 updates inventory twice a day"
  }
}

#cosign
kyverno_version = "3.7.1"
kyverno_enforce = false
kyverno_target_namespaces = ["backend", "oidc"]
cosign_oidc_issuer    = "https://token.actions.githubusercontent.com"
cosign_subject_regexp = "^https://github.com/acme-corp/Acmeparts-Helm-Charts/"
enable_kyverno_policy = truse

ecr_number_images = 20
ecr_repo_names  = [
                 "brightpearl-connector",
                 "catalog-consumer",
                 "catalog-grpc",
                 "catalog-migration",
                 "catalog-ds-consumer",
                 "catalog-ds-grpc",
                 "exporter-delta",
                 "exporter-company1",
                 "exporter-oem",
                 "exporter-offers",
                 "exporter-user",
                 "graphql"
                ]

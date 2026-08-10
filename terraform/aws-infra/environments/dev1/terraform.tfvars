project = "acmeparts"
region = "us-east-2"
stage = "dev1"

db_read_replicas_count = 0
db_backup_retention_period = 7
db_instance_class = "db.t3.small"
db_version = "17.9"
db_storage = "20"
db_multiaz = "false"
db_immediately = "true"
db_skip_final_snapshot = "true"

rds_parameters = {
  
  max_connections        = "500"
  work_mem               = "1024"
  shared_buffers         = "65536"
  effective_cache_size   = "1536000"
  maintenance_work_mem   = "65536"
}

eks_version = "1.34"
eks_desired_capacity = 4
eks_min_instances = 3
eks_max_instances = 5
eks_instance_type = "t3.medium"
eks_metric_version = "3.12.2"

kafka_version = "3.6.0"
kafka_instance_type = "kafka.t3.small"
kafka_number_of_broker_nodes = 2
kafka_volume_size = 50
kafka_volume_type = "gp3"
kafka_monitoring = "DEFAULT"
kafka_server_properties = {
  "num.partitions"                 = 10
  "min.insync.replicas"            = 2
  "compression.type"               = "lz4"
  "auto.create.topics.enable"      = "true"
  "delete.topic.enable"            = "true"
  "socket.send.buffer.bytes"       = "65536"
  "replica.fetch.max.bytes"        = "4194304"
  "message.max.bytes"              = "2097152"
  "unclean.leader.election.enable" = "false"
  "log.retention.hours"            = "48"
  "log.segment.bytes"              = "536870912"
}

s3_imports = "acme-corp-test-acmeparts-imports"

s3_buckets = {
  s3_export_sources = "acmeparts-dev1-export-sources"
  s3_exports = "acmeparts-dev1-exports"
  s3_delta = "acmeparts-dev1-delta"
  s3_images = "acmeparts-dev1-images"
  s3_files = "acmeparts-dev1-files"
  s3_raw = "acmeparts-dev1-raw"
  s3_ods = "acmeparts-dev1-ods"
}
aws_cloudfront_images_arn = ""

opensearch_engine_version = "OpenSearch_2.17" 
opensearch_node_type  = "or1.large.search"
opensearch_node_count = 2     
opensearch_master_type = "r7g.medium.search"
opensearch_dedicated_master_enabled = false
opensearch_master_count = 1             
opensearch_availability_zone_count = 2
opensearch_volume_size = 20

redis_node_type = "cache.t3.micro"
redis_parameter_group_name = "default.redis6.x"
redis_num_cache_nodes = 1

vpc_cidr = "10.0.0.0/16"
domain_name = "api-acmeparts.acme-corp.example"
cloudfront_domain_name = "api-acmeparts.acme-corp.example"
domain_name_alb = "alb-api-acmeparts.acme-corp.example"
certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/d04a64e4-fa5c-4674-93b3-0ccbaede33bc"

cloudfront_domain_name_iag = "api-internal-acmeparts.acme-corp.example"
domain_name_alb_iag = "alb-internal-acmeparts.acme-corp.example"
certificate_arn_iag = "arn:aws:acm:us-east-1:111111111111:certificate/e13ea5ca-918d-41bb-b70c-d169ce5b6e81"

cloudfront_domain_name_files = "files.acme-corp.example"
certificate_arn_files = "arn:aws:acm:us-east-1:111111111111:certificate/36568375-c923-40d9-8f7b-21cb5edb5ca6"

cloudfront_domain_name_dqc = "data-quality-checker.acme-corp.example"
domain_name_alb_dqc = "data-quality-checker.acme-corp.example"
certificate_arn_dqc = "arn:aws:acm:us-east-1:111111111111:certificate/e7575091-1be1-4165-960e-6ec8ec89e988"

waf_limit = 5000
auth_user = "admin-pf"
create_waf = true
waf_allowed_ip = "203.0.113.11"
oidc_host = "login-dev.acmeparts.example"

datadog_external_id = "8c0252cd87374f218125cd8d14652e7e"

ecs_cpu = 1024
ecs_memory = 2048
scheduled_exporters = {}

#cosign
kyverno_version = "3.7.1"
kyverno_enforce = false
kyverno_target_namespaces = ["backend", "oidc"]
cosign_oidc_issuer    = "https://token.actions.githubusercontent.com"
cosign_subject_regexp = "^https://github.com/acme-corp/Acmeparts-Helm-Charts/"
enable_kyverno_policy = true

ecr_number_images = 20
ecr_repo_names  = [
                 "brightpearl-connector",
                 "catalog-consumer",
                 "catalog-grpc",
                 "catalog-migration",
                 "catalog-ds-consumer",
                 "catalog-ds-grpc",
                 "catalog-seeds",
                 "data-quality-checker",
                 "exporter-delta",
                 "exporter-company1",
                 "exporter-oem",
                 "exporter-offers",
                 "exporter-user",
                 "files",
                 "files-migration",
                 "graphql"
                ]

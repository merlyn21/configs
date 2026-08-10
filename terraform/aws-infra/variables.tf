variable "project" {
  type        = string
}

variable "stage" {
  type        = string
}

variable "region" {
  description = "Region for AWS resources"
  type        = string
}

variable "db_read_replicas_count" {
  description = "Number of read replicas"
  type        = number
}

variable "db_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
}

variable "db_version" {
  description = "RDS version"
  type        = string
}

variable "db_storage" {
  description = "Size of postgres storage"
  type        = string
}

variable "db_multiaz" {
  description = "Multi AZ"
  type        = string
}

variable "db_immediately" {
  description = "apply_immediately"
  type        = string
}

variable "db_skip_final_snapshot" {
  description = "skip final snapshot"
  type        = bool
}

variable "rds_parameters" {
  type = map(string)
  description = "Custom RDS PostgreSQL parameters per environment"
}

variable "eks_version" {
  type = string
}

variable "eks_desired_capacity" {
  type = number
}

variable "eks_min_instances" {
  type = number
}

variable "eks_max_instances" {
  type = number
}

variable "eks_instance_type" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "waf_allowed_ip" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "domain_name_alb" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "cloudfront_domain_name_iag" {
  type = string
}

variable "domain_name_alb_iag" {
  type = string
}

variable "certificate_arn_iag" {
  type = string
}

variable "cloudfront_domain_name_dqc" {
  type = string
}

variable "domain_name_alb_dqc" {
  type = string
}

variable "certificate_arn_dqc" {
  type = string
}

variable "cloudfront_domain_name_files" {
  type = string
}

variable "certificate_arn_files" {
  type = string
}

variable "waf_limit" {
  type        = number
}

variable "oidc_host" {
  description = "domain name oidc"
  type        = string
}

variable "ecr_repo_names" {
  description = "List of ECR repository names"
  type        = list(string)
}

variable "ecr_number_images" {
  type = number
}

variable "eks_metric_version" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "kafka_version" {
  type = string
}

variable "kafka_instance_type" {
  type = string
}

variable "kafka_number_of_broker_nodes" {
  type = number
}

variable "kafka_volume_size" {
  type = number
}

variable "kafka_volume_type" {
  type = string
}

variable "kafka_server_properties" {
  description = "Kafka server.properties map"
  type        = map(any)
  default     = {}
}

variable "kafka_monitoring" {
  description = "kafka monitoring type"
  type = string
}

variable "opensearch_engine_version" {
  type = string
}

variable "opensearch_node_type" {
  type = string
}

variable "opensearch_node_count" {
  type = number
}

variable "opensearch_dedicated_master_enabled" {
  type = bool
}

variable "opensearch_master_type" {
  type = string
}


variable "opensearch_master_count" {
  type = number
}

variable "opensearch_availability_zone_count" {
  type = number
}

variable "opensearch_volume_size" {
  type = number
}

variable "redis_node_type" {
  type        = string
}

variable "redis_parameter_group_name" {
  type        = string
}

variable "redis_num_cache_nodes"{
  type        = number
}

variable "s3_imports" {
  type        = string
}

variable "auth_user" {
  type        = string
}

variable "create_waf" {
  type        = bool
}

variable "datadog_api_key" {
  description = "datadog API access token from GitHub Secrets"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  type        = string
  sensitive   = true
  description = "datadog app token"
}

variable "datadog_external_id" {
  type        = string
}

variable "datadog_postgres_password" {
  description = "datadog password from GitHub Secrets"
  type        = string
  sensitive   = true
}

variable "s3_buckets" {
  description = "Map of S3 bucket ETL"
  type        = map(string)
}

variable "aws_cloudfront_images_arn" {
  type        = string
}
# variable "ecs_cpu" {
#   description = "CPU"
#   type        = number
# }

# variable "ecs_memory" {
#   description = "Memory"
#   type        = number
# }

variable "scheduled_exporters" {
  description = "Configuration for scheduled exporters"
  type = map(object({
    exporter_name       = string
    schedule_expression = string
    enabled             = bool
    description         = optional(string, "")
  }))
  default = {}
}

#cosign
variable "kyverno_version" {
  type = string
}

variable "kyverno_enforce" {
  type = bool
}

variable "kyverno_target_namespaces" {
  type = list(string)
}

variable "cosign_oidc_issuer" {
  type = string
}

variable "cosign_subject_regexp" {
  type = string
}

variable "enable_kyverno_policy" {
  type    = bool
  default = true
}
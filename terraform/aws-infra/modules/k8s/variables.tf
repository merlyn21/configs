variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the network module"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs from the network module"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
}

variable "autoscaling_policy" {
  description = "Autoscaling policy for EKS nodes"
  type = object({
    desired_capacity = number
    min_size         = number
    max_size         = number
  })
}

variable "rds_security_group_id" {
  description = "Security group ID allowing access to RDS"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

variable "service_name" {
  description = "Name of service serving http requests inside cluster"
  type = string
  default = "api-gateway"
}

variable "eks_version" {
  description = "Version of EKS cluster"
  type = string
  default = "1.31"
}

variable "eks_metric_version" {
  description = "metric version"
  type = string
}

variable "opensearch_domain_endpoint" {
  description = "opensearch domain endpoint"
  type        = string
}

variable "opensearch_domain_arn" {
  description = "opensearch domain arn"
  type        = string
}

variable "s3_imports" {
  description = "s3 backet for imports"
  type        = string
}

variable "s3_buckets" {
  description = "Map of S3 bucket ETL"
  type        = map(string)
}

variable "stage" {
  description = "stage name"
  type        = string
}

variable "datadog_api_key" {
  type        = string
  sensitive   = true
  description = "datadog access token"
}

variable "db_primary_endpoint" {
  description = "primary endpoint db"
  type        = string
}

variable "db_password_secret_name" {
  description = "secret db"
  type        = string
}

variable "pgbouncer_chart_version" {
  description = "Version Helm chart PgBouncer"
  type        = string
  default     = "2.0.0"
}

variable "replica_count" {
  description = "replic count PgBouncer"
  type        = number
  default     = 2
}

variable "enable_monitoring" {
  description = "monitoring"
  type        = bool
  default     = true
}

variable "datadog_postgres_password" {
  type        = string
  sensitive   = true
  description = "datadog postgres password"
}

variable "rds_endpoint" {
  description = "rsd endpoint"
  type        = string
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
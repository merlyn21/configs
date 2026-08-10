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

variable "stage" {
  description = "stage name"
  type        = string
}

# variable "s3_bucket_name" {
#   description = "Name of the existing S3 bucket"
#   type        = string
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

variable "s3_buckets" {
  description = "Map of S3 bucket ETL"
  type        = map(string)
}
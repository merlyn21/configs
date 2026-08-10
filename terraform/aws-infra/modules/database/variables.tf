variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "stage" {
  description = "stage name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "read_replicas_count" {
  description = "Number of read replicas"
  type        = number
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.small"
}


variable "db_version" {
  description = "Version of postgres engin"
  type        = string
}

variable "db_storage" {
  description = "Version of postgres engin"
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

variable "rds_parameters" {
  type = map(string)
  description = "Custom RDS PostgreSQL parameters per environment"
}

variable "skip_final_snapshot" {
  description = "skip final snapshot"
  type        = bool
}
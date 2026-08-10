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

variable "subnet_ids" {
  description = "List of subnet IDs from the network module"
  type        = list(string)
}

variable "opensearch_engine_version" {
  description = "opensearch engine version"
  type = string
}

variable "opensearch_node_type" {
  description = "opensearch instance type"
  type = string
}

variable "opensearch_node_count" {
  description = "opensearch instance count"
  type = number
}

variable "opensearch_availability_zone_count" {
  description = "opensearch availability zone count"
  type = number
}

variable "opensearch_volume_size" {
  description = "opensearch volume size"
  type = number
}

variable "stage" {
  description = "stage name"
  type        = string
}

variable "opensearch_master_type" {
  type = string
}

variable "opensearch_master_count" {
  description = "opensearch instance count"
  type = number
}

variable "eks_irsa_role_arn" {
  description = "eks_irsa_role_arn"
  type = string
}

variable "ecs_task_role_arn" {
  description = "ecs_task_role_arn"
  type = string
}
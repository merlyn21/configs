variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "stage" {
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

variable "redis_node_type" {
  description = "redis node type"
  type        = string
}

variable "redis_parameter_group_name" {
  description = "redis parameter group name"
  type        = string
}

variable "redis_num_cache_nodes"{
  description = "num cache nodes"
  type        = number
}


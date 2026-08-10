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

variable "kafka_version" {
  description = "kafka version"
  type = string
}

variable "kafka_instance_type" {
  description = "kafka instance type"
  type = string
}

variable "kafka_number_of_broker_nodes" {
  description = "kafka number of broker nodes"
  type = number
}

variable "kafka_volume_size" {
  description = "kafka volume size"
  type = number
}

variable "kafka_volume_type" {
  description = "kafka volume type"
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
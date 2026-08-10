variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
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

variable "datadog_app_key" {
  type        = string
  sensitive   = true
  description = "datadog app token"
}

variable "external_id" {
  type        = string
  default = "8c0252cd87374f218125cd8d14652e7e"
  
}

# variable "datadog_external_id" {
#   type        = string
# }
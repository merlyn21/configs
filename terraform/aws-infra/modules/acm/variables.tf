variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "cloudfront_distribution" {
  type = string
}

variable "domain_name_alb" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "cloudfront_domain_name_iag" {
  type = string
}

variable "cloudfront_distribution_iag" {
  type = string
}

variable "domain_name_alb_iag" {
  description = "Domain name for the internal ALB IAG"
  type        = string
}

variable "domain_name_alb_dqc" {
  description = "Domain name for the internal ALB DQC"
  type        = string
}

variable "cloudfront_domain_name_files" {
  type = string
}

variable "cloudfront_distribution_files" {
  type = string
}

variable "stage" {
  type = string
}

variable "create_waf" {
  description = "Whether to create WAF and associate with ALB"
  type        = bool
}
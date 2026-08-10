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

variable "domain_name" {
  description = "Domain name for"
  type        = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

variable "domain_name_alb" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "cloudfront_domain_name_iag" {
  type = string
}

variable "certificate_arn_iag" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

variable "domain_name_alb_iag" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "cloudfront_domain_name_files" {
  type = string
}

variable "certificate_arn_files" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

variable "domain_name_alb_dqc" {
  description = "Domain name for the internal ALB"
  type        = string
}

variable "waf_limit" {
  description = "Rate Limit"
  type        = number
}

variable "auth_user" {
  description = "auth user name"
  type        = string
}

variable "create_waf" {
  description = "Whether to create WAF and associate with ALB"
  type        = bool
}


variable "waf_allowed_ip" {
  description = "domain name trekwood"
  type        = string
}

variable "oidc_host" {
  description = "domain name oidc"
  type        = string
}
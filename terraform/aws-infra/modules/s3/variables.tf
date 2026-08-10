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

variable "s3_imports" {
  type        = string
}

variable "notification_endpoint" {
  type        = string
}

variable "s3_buckets" {
  description = "Map of S3 bucket ETL"
  type        = map(string)
}

variable "aws_cloudfront_images_arn" {
  type        = string
}
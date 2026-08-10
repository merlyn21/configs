variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "repo_name" {
  description = "Name of the ECR repository"
  type        = string
}


variable "ecr_number_images" {
  description = "Number of the ECR images"
  type        = number
}
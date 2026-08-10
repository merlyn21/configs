variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "initial_config" {
  description = "Initial configuration to load into AppConfig"
  type        = map(any)
}

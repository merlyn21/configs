output "opensearch_domain_endpoint" {
  description = "Endpoint for OpenSearch domain"
  value       = module.opensearch.domain_endpoint
}

output "opensearch_dashboard_url" {
  description = "URL for OpenSearch Dashboards"
  value       = "https://${module.opensearch.domain_endpoint}/_dashboards/"
}

output "opensearch_arn" {
  description = "ARN for OpenSearch domain"
  value       = module.opensearch.domain_arn
}

variable "opensearch_dedicated_master_enabled" {
  type = bool
}
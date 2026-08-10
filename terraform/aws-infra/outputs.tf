output "msk_bootstrap_brokers" {
  value = module.msk.msk_bootstrap_brokers
}

output "ecr_repository_urls" {
  description = "URLs of the created ECR repositories"
  value       = { for repo in module.ecr_repo : repo.repository_url => repo.repository_url }
}

output "redis_endpoint" {
  value = module.redis.redis_endpoint
}

output "opensearch_endpoint" {
  value = module.opensearch.opensearch_domain_endpoint
}

output "opensearch_arn" {
  value = module.opensearch.opensearch_arn
}
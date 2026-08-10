output "client_security_group" {
  description = "Security group for clients"
  value = aws_security_group.clients.id
}

output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "read_endpoints" {
  value = [for replica in aws_db_instance.replicas : replica.endpoint]
}

output "db_password_secret_name" {
  value       = aws_secretsmanager_secret.master_password.name
  sensitive   = true
}
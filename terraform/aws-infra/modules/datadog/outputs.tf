
output "datadog_aws_namespaces" {
  value = data.datadog_integration_aws_available_namespaces.all.aws_namespaces
}         
output "lambda_arn" {
  description = "ARN of the health checker Lambda function"
  value       = aws_lambda_function.health_to_slack.arn
}


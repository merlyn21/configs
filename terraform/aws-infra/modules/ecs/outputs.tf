output "ecs_task_role_arn" {
  description = "ARN of the ecs task role"
  value       = aws_iam_role.ecs_task_role.arn
}
output "eks_irsa_role_arn" {
  description = "ARN of the EKS IRSA role"
  value       = module.eks_irsa.iam_role_arn
}
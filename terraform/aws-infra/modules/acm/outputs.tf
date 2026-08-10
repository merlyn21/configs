output "cloudfront_certificate_arn" {
  description = "cloudfront_cert arn"
  value       = aws_acm_certificate.cloudfront_cert.arn
}

output "cloudfront_certificate_arn_iag" {
  description = "cloudfront_cert arn iag"
  value       = var.stage != "dev1" ? aws_acm_certificate.cloudfront_cert_iag[0].arn : null
}

output "cloudfront_certificate_arn_files" {
  description = "cloudfront_cert arn files"
  value       = var.stage != "dev1" ? aws_acm_certificate.cloudfront_cert_files[0].arn : null
}

output "cloudfront_distribution" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.alb_distribution.domain_name
}

output "cloudfront_distribution_iag" {
  description = "Domain name of the CloudFront distribution IAG"
  value       = aws_cloudfront_distribution.alb_distribution_iag.domain_name
}

output "cloudfront_distribution_files" {
  description = "Domain name of the CloudFront distribution files"
  value       = aws_cloudfront_distribution.distribution_files.domain_name
}

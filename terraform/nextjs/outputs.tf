output "hvt_frontend_cloudfront_url" {
  value = aws_cloudfront_distribution.hvt_frontend.domain_name
}

# output "hdcnext_storybook_cloudfront_url" {
#   value = aws_cloudfront_distribution.hdcnext_storybook.domain_name
# }

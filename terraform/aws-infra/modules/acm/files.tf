resource "aws_acm_certificate" "cloudfront_cert_files" {
  count = var.stage != "dev1" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.cloudfront_domain_name_files
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_route53_record" "cloudfront_cert_validation_files" {
  
  for_each = var.stage != "dev1" ? {
    for dvo in aws_acm_certificate.cloudfront_cert_files[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.child_zone[0].zone_id

}


resource "aws_acm_certificate_validation" "cloudfront_domain_cert_files" {
  count  = var.stage != "dev1" ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert_files[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation_files : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}



resource "aws_route53_record" "cloudfront_cname_files" {
  count  = var.stage != "dev1" ? 1 : 0
  
  zone_id = aws_route53_zone.child_zone[0].zone_id
  name    = var.cloudfront_domain_name_files
  type    = "CNAME"
  ttl     = 300
  records = [var.cloudfront_distribution_files]
}

resource "aws_acm_certificate" "domain_cert_dqc" {
  count  = var.stage != "dev1" ? 1 : 0
  domain_name               = var.domain_name_alb_dqc
  subject_alternative_names = ["*.${var.domain_name_alb_dqc}"]
  validation_method         = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
}


resource "aws_route53_record" "cert_validation_dqc" {

  for_each = var.stage != "dev1" ? {
    for dvo in aws_acm_certificate.domain_cert_dqc[0].domain_validation_options : dvo.domain_name => {
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


resource "aws_acm_certificate_validation" "domain_cert_dqc" {
  count  = var.stage != "dev1" ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain_cert_dqc[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_dqc : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}


resource "aws_route53_record" "www_cname_dqc" {
  count = (var.stage != "dev1" && var.create_waf) ? 1 : 0
  
  zone_id = aws_route53_zone.child_zone[0].zone_id
  name    = var.domain_name_alb_dqc
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.ingress_alb[0].dns_name]
}

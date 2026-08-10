provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "alb_cert" {
  count = var.stage == "dev1" ? 1 : 0
  domain_name       = var.domain_name_alb
  validation_method = "DNS"
}

resource "aws_acm_certificate" "cloudfront_cert" {
  # count = 1
  # var.stage == "dev1" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.cloudfront_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "child_zone" {
  count  = var.stage != "dev1" ? 1 : 0
  name = var.domain_name
}

resource "aws_acm_certificate" "domain_cert" {
  count  = var.stage != "dev1" ? 1 : 0
  domain_name               = var.domain_name_alb
  subject_alternative_names = ["*.${var.domain_name_alb}"]
  validation_method         = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
}


resource "aws_route53_record" "cert_validation" {

  for_each = var.stage != "dev1" ? {
    for dvo in aws_acm_certificate.domain_cert[0].domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "cloudfront_cert_validation" {
  
  for_each = var.stage != "dev1" ? {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "domain_cert" {
  count  = var.stage != "dev1" ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}

resource "aws_acm_certificate_validation" "cloudfront_domain_cert" {
  count  = var.stage != "dev1" ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}

data "aws_lb" "ingress_alb" {
  count = var.create_waf ? 1 : 0
  # tags = {
  #   "ingress.k8s.aws/stack" = "backend/acmeparts-graphql-root-ingress"
  # }
}

resource "aws_route53_record" "www_cname" {
  count = (var.stage != "dev1" && var.create_waf) ? 1 : 0
  
  zone_id = aws_route53_zone.child_zone[0].zone_id
  name    = var.domain_name_alb
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.ingress_alb[0].dns_name]
}

resource "aws_route53_record" "cloudfront_cname" {
  count  = var.stage != "dev1" ? 1 : 0
  
  zone_id = aws_route53_zone.child_zone[0].zone_id
  name    = var.cloudfront_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cloudfront_distribution]
}
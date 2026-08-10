provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# data "aws_ssm_parameter" "origin_auth_token" {
#   name = aws_ssm_parameter.origin_auth_token.name
#   with_decryption = true
# }

# locals {
#   alb_dns_name = data.aws_lb.ingress_alb.dns_name
#   alb_zone_id  = data.aws_lb.ingress_alb.zone_id
# }

resource "aws_cloudfront_distribution" "alb_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for EKS ALB Ingress"
#  default_root_object = "/"
  aliases = [var.cloudfront_domain_name]
  # var.stage == "dev1" ? [var.domain_name] : []
  
  origin {
    domain_name = var.domain_name_alb
    origin_id   = "EKS-ALB-Origin"
    
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only" 
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }

    custom_header {
      name  = "x-origin-auth"
      value = data.aws_ssm_parameter.origin_auth_token.value

    }
  }

 # logging_config {
 #   include_cookies = false
 #   bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
 #   prefix          = "cloudfront-logs/"
 # }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EKS-ALB-Origin"


    forwarded_values {
      query_string = true
      headers      = ["Origin", "Authorization", "X-Forwarded-For", "X-Forwarded-Proto", "X-API-Key"]
      cookies {
        forward = "all"
      }
    }

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.basic_auth.qualified_arn
      include_body = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "/graphql*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "EKS-ALB-Origin"


    forwarded_values {
      query_string = true
      headers      = ["User-Agent", "Accept", "Content-Type", "Authorization", "X-Apollo-Tracing", "X-Forwarded-For", "X-Forwarded-Proto", "X-API-Key"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/s3*" 
    target_origin_id       = "EKS-ALB-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"] 
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = false 
    
    forwarded_values {
      query_string = true
      headers      = ["User-Agent", "Accept", "Content-Type", "Authorization", "X-Apollo-Tracing", "X-Forwarded-For", "X-Forwarded-Proto", "X-API-Key"]
      cookies {
        forward = "all"
      }
    }
    
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  ordered_cache_behavior {
    path_pattern           = "/delta*" 
    target_origin_id       = "EKS-ALB-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"] 
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = false 
    
    forwarded_values {
      query_string = true
      headers      = ["User-Agent", "Accept", "Content-Type", "Authorization", "X-Apollo-Tracing", "X-Forwarded-For", "X-Forwarded-Proto", "X-API-Key"]
      cookies {
        forward = "all"
      }
    }
    
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # viewer_certificate {
  #   # cloudfront_default_certificate = true
  #   acm_certificate_arn      = var.certificate_arn
  #   ssl_support_method       = "sni-only"
  #   minimum_protocol_version = "TLSv1.2_2021"
  # }

  # viewer_certificate {
  #   acm_certificate_arn            = var.stage == "dev1" ? var.certificate_arn : null
  #   ssl_support_method             = var.stage == "dev1" ? "sni-only" : null
  #   minimum_protocol_version       = var.stage == "dev1" ? "TLSv1.2_2021" : null
  #   cloudfront_default_certificate = var.stage != "dev1" ? true : null
  # }

  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }
  
  depends_on = [
    aws_s3_bucket_acl.cloudfront_logs,
    aws_s3_bucket_ownership_controls.cloudfront_logs
  ]
}


resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.project}-${var.stage}-cloudfront-logs-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_versioning.cloudfront_logs]
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = "cloudfront-logs/" 
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
  bucket     = aws_s3_bucket.cloudfront_logs.id
  acl        = "private"
}
resource "aws_cloudfront_distribution" "alb_distribution_iag" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for IAG ALB Ingress"
#  default_root_object = "/"
  aliases = [var.cloudfront_domain_name_iag]
  # var.stage == "dev1" ? [var.domain_name] : []
  
  origin {
    domain_name = var.domain_name_alb_iag
    origin_id   = "EKS-IAG-ALB-Origin"
    

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

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "EKS-IAG-ALB-Origin"


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



  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn_iag
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
    aws_s3_bucket_acl.cloudfront_logs_iag,
    aws_s3_bucket_ownership_controls.cloudfront_logs_iag
  ]
}


resource "aws_s3_bucket" "cloudfront_logs_iag" {
  bucket = "${var.project}-${var.stage}-cloudfront-logs-iag-${random_id.bucket_suffix_iag.hex}"
}

resource "aws_s3_bucket_versioning" "cloudfront_logs_iag" {
  bucket = aws_s3_bucket.cloudfront_logs_iag.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix_iag" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_iag" {
  bucket = aws_s3_bucket.cloudfront_logs_iag.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_iag" {
  bucket = aws_s3_bucket.cloudfront_logs_iag.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs_iag" {
  depends_on = [aws_s3_bucket_versioning.cloudfront_logs_iag]
  bucket = aws_s3_bucket.cloudfront_logs_iag.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = "cloudfront-logs/" 
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 20
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_iag" {
  bucket = aws_s3_bucket.cloudfront_logs_iag.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs_iag" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs_iag]
  bucket     = aws_s3_bucket.cloudfront_logs_iag.id
  acl        = "private"
}
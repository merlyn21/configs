# data "aws_s3_bucket" "files_bucket" {
#   bucket = "${var.project}-${var.stage}-files"
# }

locals {
  files_bucket_name = "${var.project}-${var.stage}-files"
  files_bucket_arn  = "arn:aws:s3:::${local.files_bucket_name}"

  files_bucket_domain = "${local.files_bucket_name}.s3.${var.region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "distribution_files" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for files s3 bucket"
#  default_root_object = "/"
  aliases = [var.cloudfront_domain_name_files]
  # var.stage == "dev1" ? [var.domain_name] : []
  
  
  origin {
    domain_name              = local.files_bucket_domain
    origin_id                = "S3-FILES-Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-FILES-Origin"


    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }



  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn_files
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs_files.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }
  
  depends_on = [
    aws_s3_bucket_acl.cloudfront_logs_files,
    aws_s3_bucket_ownership_controls.cloudfront_logs_files
  ]
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project}-${var.stage}-s3-oac"
  description                       = "OAC for S3 files bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "files_bucket" {
  bucket = local.files_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${local.files_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.distribution_files.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "cloudfront_logs_files" {
  bucket = "${var.project}-${var.stage}-cloudfront-logs-files-${random_id.bucket_suffix_files.hex}"
}

resource "aws_s3_bucket_versioning" "cloudfront_logs_files" {
  bucket = aws_s3_bucket.cloudfront_logs_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix_files" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_files" {
  bucket = aws_s3_bucket.cloudfront_logs_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_files" {
  bucket = aws_s3_bucket.cloudfront_logs_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs_files" {
  depends_on = [aws_s3_bucket_versioning.cloudfront_logs_files]
  bucket = aws_s3_bucket.cloudfront_logs_files.id

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

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_files" {
  bucket = aws_s3_bucket.cloudfront_logs_files.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs_files" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs_files]
  bucket     = aws_s3_bucket.cloudfront_logs_files.id
  acl        = "private"
}
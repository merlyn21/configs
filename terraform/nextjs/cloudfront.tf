
# Access S3 from cloudfront
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket-static-946.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.bucket-static-946_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.bucket-static-946.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.bucket-static-946_access_identity.iam_arn}"]
    }
  }
}

# Add S3 bucket policy
resource "aws_s3_bucket_policy" "bucket-static-946" {
  bucket = aws_s3_bucket.bucket-static-946.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Cache policy for static assets
resource "aws_cloudfront_cache_policy" "hvt_frontend" {
  name        = "hvt_frontend-cache-policy"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# Cloudfront setup
resource "aws_cloudfront_distribution" "hvt_frontend" {
  origin {
    domain_name = aws_s3_bucket.bucket-static-946.bucket_regional_domain_name
    origin_id   = local.cloudfront_s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.bucket-static-946_access_identity.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "HVT frontend cloudfront"
  #default_root_object = "index"
  #  wait_for_deployment = var.CLOUDFRONT_WAIT_FOR_DEPLOYMENT
  #  aliases             = data.terraform_remote_state.core_devops_infrastructure.outputs.aws_acm_certificate.domain_name != null ? ["hdc.${data.terraform_remote_state.core_devops_infrastructure.outputs.aws_acm_certificate.domain_name}"] : []

  aliases = [""]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.cloudfront_s3_origin_id
    cached_methods   = ["GET", "HEAD"]
    min_ttl          = 0
    default_ttl      = 0
    max_ttl          = 31536000

    forwarded_values {
      query_string = true

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["accessToken", "idToken", "redirectPath", "isAuthorizing", "codeVerifier"]
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.tf-lambda-ssr.qualified_arn
      include_body = true
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.tf-lambda-ssr.qualified_arn
      include_body = false
    }
  }


  # ordered_cache_behavior {
  #   path_pattern           = "${var.BASE_PATH}/assets/*"
  #   allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods         = ["GET", "HEAD", "OPTIONS"]
  #   target_origin_id       = local.cloudfront_s3_origin_id
  #   cache_policy_id        = aws_cloudfront_cache_policy.hdcnext_frontend.id
  #   compress               = true
  #   viewer_protocol_policy = "redirect-to-https"
  # }

  ordered_cache_behavior {
    path_pattern           = "_next/static/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.cloudfront_s3_origin_id
    cache_policy_id        = aws_cloudfront_cache_policy.hvt_frontend.id
    compress               = true
    viewer_protocol_policy = "https-only"
  }

  ordered_cache_behavior {
    path_pattern           = "static/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.cloudfront_s3_origin_id
    cache_policy_id        = aws_cloudfront_cache_policy.hvt_frontend.id
    compress               = true
    viewer_protocol_policy = "https-only"
  }

  ordered_cache_behavior {
    path_pattern     = "_next/data/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.cloudfront_s3_origin_id

    forwarded_values {
      query_string = true
      headers      = ["Origin"]

      cookies {
        forward = "all"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.tf-lambda-ssr.qualified_arn
      include_body = true
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.tf-lambda-ssr.qualified_arn
      include_body = false
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "https-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.hvt-stage-cert.arn
    #    cloudfront_default_certificate = aws_acm_certificate.arn == null ? true : false
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
    #cloudfront_default_certificate = true
  }


}

resource "aws_acm_certificate" "hvt-stage-cert" {
  private_key       = file("./ssl/private.key")
  certificate_body  = file("./ssl/certificate.srt")
  certificate_chain = file("./ssl/fullchain.crt")
}

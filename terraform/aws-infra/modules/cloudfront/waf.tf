resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider    = aws.us_east_1
  name        = "${var.project}-cloudfront-protect"
  description = "WAF for Cloudfront"
  scope       = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "rule-limit"
    priority = 0
    
    action {
      count {}
    }
    
    statement {
      rate_based_statement {
        limit              = var.waf_limit
        aggregate_key_type = "IP"
        evaluation_window_sec = 60
        
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
              }
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudFrontProtection"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_ip_set" "allowed_ips" {
  provider           = aws.us_east_1
  name               = "${var.project}-allowed-ips"
  description        = "IP addresses to exclude from rate limiting"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = [
    "${var.waf_allowed_ip}/32"
  ]
}

resource "random_password" "origin_auth_token" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "origin_auth_token" {
  name        = "/cloudfront/origin-auth-token"
  description = "Secret token used for CloudFront -> ALB authentication"
  type        = "SecureString"
  value       = random_password.origin_auth_token.result
}


data "aws_ssm_parameter" "origin_auth_token" {
  name = aws_ssm_parameter.origin_auth_token.name
  with_decryption = true
}

resource "aws_wafv2_web_acl" "alb_acl" {
  name  = "cloudfront-origin-auth"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFBlockedRequests"
    sampled_requests_enabled   = true
  }

rule {
  name     = "AllowOidcNoAuth"

  priority = 1
  action { 
    allow {} 
    }

  statement {
    byte_match_statement {
      search_string         = var.oidc_host
      positional_constraint = "EXACTLY"

      field_to_match {
        single_header { name = "host" } 
      }

      text_transformation {
        priority = 0
        type     = "LOWERCASE"
      }
    }
  }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowOidcNoAuth"
      sampled_requests_enabled   = true
    }
  }

rule {
  name     = "AllowDQCNoAuth"

  priority = 2
  action { 
    allow {} 
    }

  statement {
    byte_match_statement {
      search_string         = var.domain_name_alb_dqc
      positional_constraint = "EXACTLY"

      field_to_match {
        single_header { name = "host" } 
      }

      text_transformation {
        priority = 0
        type     = "LOWERCASE"
      }
    }
  }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowDQCNoAuth"
      sampled_requests_enabled   = true
    }
  }
  
  rule {
    name     = "AllowWithOriginAuth"
    priority = 3
    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string         = data.aws_ssm_parameter.origin_auth_token.value
        positional_constraint = "EXACTLY"

        field_to_match {
          single_header {
            name = "x-origin-auth"
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowWithAuthHeader"
      sampled_requests_enabled   = true
    }
  }
}

# locals {
#   alb_exists = try(data.aws_lb.ingress_alb.arn, null) != null
# }
data "aws_lb" "ingress_alb" {
  count = var.create_waf ? 1 : 0
  # name  = "alb-ingress"
  # tags = {
  #   "ingress.k8s.aws/stack" = "backend/acmeparts-graphql-root-ingress"
  # }
}

resource "aws_wafv2_web_acl_association" "alb_waf" {
  count = var.create_waf ? 1 : 0

  resource_arn = data.aws_lb.ingress_alb[0].arn
  web_acl_arn  = aws_wafv2_web_acl.alb_acl.arn
}

terraform {
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "3.69.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# provider "aws" {
#   region = var.region
# }

# provider "datadog" {
#   api_key = var.datadog_api_key
#   app_key = var.datadog_app_key
#   api_url = "https://api.us5.datadoghq.com/"
# }

data "aws_caller_identity" "current" {}
data "datadog_integration_aws_available_namespaces" "all" {}


data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [
        # var.datadog_external_id
        "${datadog_integration_aws_account.main.auth_config.aws_auth_config_role.external_id}"
        ]
    }
  }
}

resource "aws_iam_policy" "datadog_policy" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.iam_policy.json
}

resource "aws_iam_role" "datadog_role" {
  name               = "DatadogIntegrationRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.datadog_role.name
  policy_arn = aws_iam_policy.datadog_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_sec" {
  role       = aws_iam_role.datadog_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "datadog_integration_aws_account" "main" {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = "aws"

  aws_regions {
    include_all = true
  }

  auth_config {
    aws_auth_config_role {
      role_name = "DatadogIntegrationRole"
    }
  }

  # auth_config {
  #   aws_auth_config_role {
  #     role_name = aws_iam_role.datadog_role.name
  #     external_id = var.datadog_external_id
  #   }
  # }

  resources_config {
    extended_collection = false
    cloud_security_posture_management_collection = false
  }

  metrics_config {
    automute_enabled          = true
    collect_cloudwatch_alarms = true
    collect_custom_metrics    = false
    enabled                   = true
    namespace_filters {
    #   # include_only = data.datadog_integration_aws_available_namespaces.all.aws_namespaces
      include_only = [
        "AWS/EC2",
        "AWS/RDS",
        "AWS/ES",
        "AWS/ELB",
        "AWS/ApplicationELB",
        "AWS/Kafka",
        "AWS/CloudFront"
    ]

    }

    tag_filters {
      namespace = "AWS/EC2"
      tags      = ["datadog_monitoring:true"]
    }
  }

  logs_config {
    lambda_forwarder {
      lambdas = [data.aws_lambda_function.datadog_forwarder.arn]
    }
  }

  traces_config {
    xray_services {
        include_all = true
    }
  }

account_tags = [
    "env:${var.stage}",
    "project:${var.project}",
    "source:aws"
  ]
}

data "aws_iam_policy_document" "iam_policy" {
  statement {
    actions   = [
    "apigateway:GET",
    # CloudWatch
    "cloudwatch:DescribeAlarms",
    "cloudwatch:GetMetricData",
    "cloudwatch:GetMetricStatistics",
    "cloudwatch:ListMetrics",

    # Logs
    "logs:GetLogEvents",
    "logs:DescribeLogGroups",
    "logs:DescribeLogStreams",
    "logs:FilterLogEvents",
    "logs:DescribeSubscriptionFilters",
    "logs:DescribeMetricFilters",
    "logs:TestMetricFilter",

    # Tagging
    "tag:GetResources",
    "tag:GetTagKeys",
    "tag:GetTagValues",

    # EC2
    "ec2:DescribeInstances",
    "ec2:DescribeTags",
    "ec2:DescribeVolumes",
    "ec2:DescribeSnapshots",
    "ec2:DescribeRegions",
    "ec2:DescribeReservedInstances",
    "ec2:DescribeNetworkInterfaces",

    # RDS
    "rds:DescribeDBInstances",
    "rds:DescribeDBClusters",
    "rds:ListTagsForResource",
    "rds:DescribeDBSnapshotAttributes",
    "rds:DescribeDBSnapshots",
    "rds:DescribeDBParameters",
    "rds:DescribeDBParameterGroups",
    "rds:DescribeDBLogFiles",
    "rds:DownloadDBLogFilePortion",

    # OpenSearch
    "es:ListDomainNames",
    "es:DescribeElasticsearchDomains",
    "es:DescribeDomain",
    "es:ListTags",

    # Kafka (MSK)
    "kafka:ListClusters",
    "kafka:DescribeCluster",
    "kafka:ListNodes",
    "kafka:DescribeConfiguration",

    # Lambda
    "lambda:ListFunctions",
    "lambda:GetFunctionConfiguration",
    "lambda:CreateFunction",
    "lambda:GetFunction",
    "lambda:UpdateFunctionConfiguration",
    "lambda:DeleteFunction",
    "lambda:InvokeFunction",
    "lambda:AddPermission",
    "lambda:RemovePermission",

    # ELB/NLB
    "elasticloadbalancing:DescribeLoadBalancers",
    "elasticloadbalancing:DescribeTags",
    "elasticloadbalancing:DescribeTargetGroups",

    # Auto Scaling
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:DescribeAutoScalingInstances",

    # ECS
    "ecs:ListClusters",
    "ecs:DescribeClusters",
    "ecs:ListServices",
    "ecs:DescribeServices",
    "ecs:ListContainerInstances",
    "ecs:DescribeContainerInstances",
    "ecs:DescribeTaskDefinition",

    # EKS
    "eks:ListClusters",
    "eks:DescribeCluster",

    # IAM
    "iam:GetRole",
    "iam:ListRoles",
    "iam:ListAttachedRolePolicies",
    "iam:PassRole",

    # Secrets Manager 
    "secretsmanager:ListSecrets",
    "secretsmanager:DescribeSecret",

    # Config
    "config:BatchGetResourceConfig",
    "config:ListDiscoveredResources",

    "s3:GetObject",
    "s3:ListBucket",
    "sqs:SendMessage",
    "sns:Publish",

    "health:DescribeEvents",
    "health:DescribeEventDetails",
    "health:DescribeAffectedEntities",
    "health:DescribeEventAggregates",
    "health:DescribeEventTypes"

  ]
    resources = ["*"]
  }
}

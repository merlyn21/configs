provider "aws" {
  region = var.region
}

locals { 
  opensearch_claster_name  = "${var.project}-opensearch"
}

locals {
  is_dev1_stage  = var.stage == "dev1"
  is_prod_stage = contains(["stage", "prod"], var.stage)
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}


resource "aws_iam_user" "opensearch_user" {
  name = "${var.project}-opensearch-user"
}

resource "aws_iam_policy" "opensearch_access_policy" {
  name        = "${var.project}-opensearch-access-policy"
  description = "Policy for accessing OpenSearch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpDelete",
          "es:ESHttpHead",
          "es:Describe*",
          "es:List*",
          "es:ClusterHealth",
          "es:ClusterState",
          "es:ClusterStats",
          "es:CreateIndex"
        ]
        Resource = "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_claster_name}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "opensearch_user_attach" {
  user       = aws_iam_user.opensearch_user.name
  policy_arn = aws_iam_policy.opensearch_access_policy.arn
}

module "opensearch" {
  source  = "terraform-aws-modules/opensearch/aws"
  version = "~> 1.6.0" 

  domain_name    = local.opensearch_claster_name
  engine_version = "${var.opensearch_engine_version}" 

  cluster_config = {
    instance_type  = var.opensearch_node_type
    instance_count = var.opensearch_node_count                  
    zone_awareness_enabled = true  
    zone_awareness_config  = {
      availability_zone_count = var.opensearch_availability_zone_count   
    }

    dedicated_master_enabled = var.opensearch_dedicated_master_enabled
    master_instance_type     = var.opensearch_dedicated_master_enabled ? var.opensearch_master_type : ""
    master_instance_count    = var.opensearch_dedicated_master_enabled ? var.opensearch_master_count : ""
  }

 cloudwatch_log_group_retention_in_days = 3

 access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = [
             var.eks_irsa_role_arn,
             aws_iam_user.opensearch_user.arn,
             var.ecs_task_role_arn
          ]
        }
        Action    = "es:*"
        Resource  = "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_claster_name}/*"
      }
#      {
#        Effect    = "Allow",
#        Principal = "*",
#        Action    = "es:ESHttpGet",
#        Resource  = "arn:aws:es:${var.region}-:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_claster_name}/_dashboards/*"
#      }
    ]
  })


  ebs_options = {
    ebs_enabled = true
    volume_size = var.opensearch_volume_size
    volume_type = "gp3"
  }

  vpc_options = local.is_prod_stage ? {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.opensearch[0].id]
  } : {}

  # advanced_security_options = {
  #   enabled                        = local.is_dev1_stage
  #   internal_user_database_enabled = false
  #   master_user_options = local.is_dev1_stage ? {
  #     master_user_arn = aws_iam_user.opensearch_user.arn
  #   } : null

    advanced_security_options = {
      enabled                        = true
      internal_user_database_enabled = false
      master_user_options = {
        master_user_arn = aws_iam_user.opensearch_user.arn
      }
    }


  encrypt_at_rest = {
    enabled = true
  }

  node_to_node_encryption = {
    enabled = true
  }

  domain_endpoint_options = {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
    public_access_enabled = local.is_dev1_stage
  }

}

resource "aws_security_group" "opensearch" {
  count = local.is_dev1_stage ? 0 : 1
  name_prefix = "${var.project}-opensearch-"
  vpc_id      = var.vpc_id
  description = "Security group for OpenSearch cluster"

  # HTTPS access from EKS
  ingress {
    description     = "HTTPS from EKS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


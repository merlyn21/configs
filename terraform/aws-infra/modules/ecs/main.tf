provider "aws" {
  region = var.region
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project}-${var.stage}-ecs-tasks"
  vpc_id      = var.vpc_id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All outbound traffic for internet access and AWS services"
  }

  tags = {
    Name = "${var.project}-${var.stage}-ecs-tasks-sg"
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.stage}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.stage}-ecs-task-role"
  }
}

resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project}-${var.stage}-s3-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ] #${var.s3_bucket_name}
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.stage}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.stage}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "eks_nodes_cloudwatch" {
  name = "${var.project}-ecs-cloudwatch-logs"

  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.stage}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project}-${var.stage}-cluster"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}-${var.stage}"
  retention_in_days = 3

  tags = {
    Name = "${var.project}-${var.stage}-logs"
  }
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${var.project}-ecs-secrets-access"
  role = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:CreateSecret",
        "secretsmanager:UpdateSecret",
        "secretsmanager:PutSecretValue"
      ]
      Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
    },
    {
      Effect = "Allow"
      Action = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_secrets_access" {
  name = "${var.project}-ecs-task-secrets-access"
  role = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
    },
    {
      Effect = "Allow"
      Action = ["kms:Decrypt"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_appconfig_access" {
  name = "${var.project}-ecs-appconfig-read-only"

  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "appconfig:GetApplication",
          "appconfig:ListApplications",
          "appconfig:GetEnvironment",
          "appconfig:ListEnvironments",
          "appconfig:GetConfigurationProfile",
          "appconfig:ListConfigurationProfiles",
          "appconfig:GetConfiguration",
          "appconfig:ListConfigurations",
          "appconfig:GetHostedConfigurationVersion",
          "appconfig:ListHostedConfigurationVersions",
          "appconfig:StartConfigurationSession",
          "appconfig:GetLatestConfiguration"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_ES_access" {
  name = "${var.project}-ecs-ES-read"

  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost"
        ],
        Resource = "*"
      }
    ]
  })

}

data "aws_caller_identity" "current" {}
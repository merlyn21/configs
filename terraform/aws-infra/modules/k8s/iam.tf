
resource "aws_iam_role" "eks_nodes_role" {
  name               = "${var.project}-eks-nodes-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eks_nodes_secrets_manager" {
  name = "${var.project}-secrets-manager-read-only"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "eks_nodes_app_config" {
  name = "${var.project}-app-config-read-only"

  role = aws_iam_role.eks_nodes_role.id

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
          "appconfig:ListHostedConfigurationVersions"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_nodes_rds_connect" {
  name = "${var.project}-rds-connect"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:Connect"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "eks_nodes_fargate" {
  name = "${var.project}-fargate-tasks"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_nodes_lambda" {
  name = "${var.project}-lambda-invoke"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_nodes_dynamodb" {
  name = "${var.project}-dynamodb-access"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_nodes_opensearch" {
  name = "${var.project}-opensearch-access"

  role = aws_iam_role.eks_nodes_role.id

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

resource "aws_iam_role_policy" "eks_nodes_cloudwatch" {
  name = "${var.project}-cloudwatch-logs"

  role = aws_iam_role.eks_nodes_role.id

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

resource "aws_iam_role_policy" "eks_nodes_ec2" {
  name = "${var.project}-nodes-ec2"

  role = aws_iam_role.eks_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DescribeVolumes",
        "ec2:DescribeInstances",
        "ec2:CreateTags",
        "ec2:DeleteTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

#IRSA
resource "aws_iam_policy" "eks_access" {
  name        = "${var.project}-eks-access-policy"
  description = "IAM policy for EKS pods"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:ListAllMyBuckets"
        ]
        Resource = [
          "arn:aws:s3:::acme-corp-dev1-acmeparts-imports",
          "arn:aws:s3:::acme-corp-dev1-acmeparts-imports/*",
          "arn:aws:s3:::${var.s3_imports}",
          "arn:aws:s3:::${var.s3_imports}/*",
          "arn:aws:s3:::${var.s3_buckets["s3_export_sources"]}",
          "arn:aws:s3:::${var.s3_buckets["s3_export_sources"]}/*",
          "arn:aws:s3:::${var.s3_buckets["s3_exports"]}",
          "arn:aws:s3:::${var.s3_buckets["s3_exports"]}/*",
          "arn:aws:s3:::${var.s3_buckets["s3_delta"]}",
          "arn:aws:s3:::${var.s3_buckets["s3_delta"]}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_buckets["s3_files"]}",
          "arn:aws:s3:::${var.s3_buckets["s3_files"]}/*"
        ]
      },
      # OpenSearch access
      {
        Effect = "Allow"
        Action = [
          "es:*"
        ]
        Resource = [
                "${var.opensearch_domain_arn}/*",
                "${var.opensearch_domain_arn}"
                 ]
      },
      {
        Effect = "Allow"
        Action = [
          "appconfig:GetConfiguration",
          "appconfig:GetLatestConfiguration",
          "appconfig:StartConfigurationSession"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:*"
      },     
      {
            "Sid": "ListSecrets",
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
      },
      #ECS
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks"
        ]
        Resource = [
          "arn:aws:ecs:${var.region}:${local.account_id}:task-definition/data-quality-checker-ecs:*",
          "arn:aws:ecs:${var.region}:${local.account_id}:task/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${local.account_id}:role/${var.project}-${var.stage}-ecs-execution-role",
          "arn:aws:iam::${local.account_id}:role/${var.project}-${var.stage}-ecs-task-role"
        ]
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }


    ]
  })
  lifecycle {
    ignore_changes = [description]
  }
}



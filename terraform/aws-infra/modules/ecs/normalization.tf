resource "aws_lambda_function" "normalization_exporter" {
  function_name = "${var.project}-ecs-normalization-exporter"
  role          = aws_iam_role.lambda_normalization.arn
  handler       = "normalization.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120

  filename         = "${path.module}/normalization.zip"
  source_code_hash = filebase64sha256("${path.module}/normalization.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.ecs_tasks.id]
  }

  environment {
    variables = {
      PROJECT             = var.project
      STAGE               = var.stage
      ENVIRONMENT         = var.stage
      ECS_CLUSTER         = aws_ecs_cluster.main.name
      ECS_SUBNETS         = join(",", var.private_subnet_ids)
      ECS_SECURITY_GROUPS = aws_security_group.ecs_tasks.id
    }
  }

}

resource "aws_iam_role" "lambda_normalization" {
  name = "${var.project}-ecs-lambda-normalization-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  
}

resource "aws_iam_role_policy_attachment" "lambda_normalization" {
  role       = aws_iam_role.lambda_normalization.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_normalization_vpc_access" {
  role       = aws_iam_role.lambda_normalization.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets_normalization" {
  
  name = "${var.project}-ecs-lambda-normalization-secrets"
  role = aws_iam_role.lambda_normalization.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.stage}/exporter-overrides/*",
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:acmeparts-redis*"
      ]
    },
    {
      Effect = "Allow"
      Action = ["kms:Decrypt"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ecs_normalization" { 
  name = "${var.project}-ecs-lambda-normalization"
  role = aws_iam_role.lambda_normalization.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ecs:RunTask"]
      Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/*"
      Condition = {
        StringLike = {
          "ecs:cluster" = aws_ecs_cluster.main.arn
        }
      }
    },
    {
      Effect = "Allow"
      Action = ["iam:PassRole"]
      Resource = [
        aws_iam_role.ecs_task_execution_role.arn,
        aws_iam_role.ecs_task_role.arn
      ]
    }]
  })
}

# ==================== Lambda Logs ====================

resource "aws_cloudwatch_log_group" "lambda_normalization" {
  name              = "/aws/lambda/${aws_lambda_function.normalization_exporter.function_name}"
  retention_in_days = 7
}

# ==================== CloudWatch Alarms ====================

resource "aws_cloudwatch_metric_alarm" "lambda_errors_normalization" {
  
  alarm_name          = "${var.project}-${var.stage}-normalization-exporter-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "normalization exporter Lambda function failed"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.normalization_exporter.function_name
  }

}

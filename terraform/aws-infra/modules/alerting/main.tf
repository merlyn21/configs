data "aws_secretsmanager_secret" "slack_webhook" {
  name = "slack-webhook-url-alerting"
}

data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = data.aws_secretsmanager_secret.slack_webhook.id
}

resource "aws_iam_role" "lambda_health_role" {
  name = "${var.project}-aws-health-slack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "aws-health-slack-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_health_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project}-secrets-access-policy"
  role = aws_iam_role.lambda_health_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.aws_secretsmanager_secret.slack_webhook.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "aws_health_events" {
  name        = "${var.project}-aws-health-notifications"
  description = "Capture AWS Health events"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
    detail = {
      eventTypeCategory = ["scheduledChange", "issue", "accountNotification"]
    }
  })

  tags = {
    Name = "aws-health-notifications"
  }
}

resource "aws_cloudwatch_event_target" "health_to_lambda" {
  rule      = aws_cloudwatch_event_rule.aws_health_events.name
  target_id = "SendToSlackLambda"
  arn       = aws_lambda_function.health_to_slack.arn
}
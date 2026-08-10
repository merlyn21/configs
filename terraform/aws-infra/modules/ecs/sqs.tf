resource "aws_sqs_queue" "s3_exports_events_dlq" {
  name                      = "${var.project}-${var.stage}-s3-exports-events-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "s3_exports_events" {
  name                       = "${var.project}-${var.stage}-s3-exports-events"
  visibility_timeout_seconds = 180 

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_exports_events_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "allow_s3_send_to_sqs" {
  queue_url = aws_sqs_queue.s3_exports_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.s3_exports_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:s3:::${var.s3_buckets["s3_ods"]}"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

############################
# S3 -> SQS notification
############################

resource "aws_s3_bucket_notification" "s3_exports_to_sqs" {
  bucket = var.s3_buckets["s3_ods"]

  queue {
    queue_arn = aws_sqs_queue.s3_exports_events.arn
    events    = ["s3:ObjectCreated:*"]

  }

  depends_on = [aws_sqs_queue_policy.allow_s3_send_to_sqs]
}

############################
# Lambda rules for SQS (Receive/Delete/etc)
############################

resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.project}-ecs-lambda-delta-sqs"
  role = aws_iam_role.lambda_delta.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.s3_exports_events.arn
      }
    ]
  })
}

############################
# SQS -> Lambda
############################

resource "aws_lambda_event_source_mapping" "s3_exports_sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.s3_exports_events.arn
  function_name    = aws_lambda_function.delta_exporter.arn

  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true

  depends_on = [aws_iam_role_policy.lambda_sqs]
}

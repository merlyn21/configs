resource "aws_sqs_queue" "s3_raw_events_dlq" {
  name                      = "${var.project}-${var.stage}-s3-raw-events-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "s3_raw_events" {
  name = "${var.project}-${var.stage}-s3-raw-events"
  visibility_timeout_seconds = 720 

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_raw_events_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "allow_s3_send_to_sqs_raw" {
  queue_url = aws_sqs_queue.s3_raw_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.s3_raw_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:s3:::${var.s3_buckets["s3_raw"]}"
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

resource "aws_s3_bucket_notification" "s3_raw_to_sqs" {
  bucket = var.s3_buckets["s3_raw"]

  queue {
    queue_arn = aws_sqs_queue.s3_raw_events.arn
    events    = ["s3:ObjectCreated:*"]

  }

  depends_on = [aws_sqs_queue_policy.allow_s3_send_to_sqs_raw]
}

############################
# Lambda rules for SQS (Receive/Delete/etc)
############################

resource "aws_iam_role_policy" "lambda_sqs_raw" {
  name = "${var.project}-ecs-lambda-normalization-sqs"
  role = aws_iam_role.lambda_normalization.id

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
        Resource = aws_sqs_queue.s3_raw_events.arn
      }
    ]
  })
}

############################
# SQS -> Lambda
############################

resource "aws_lambda_event_source_mapping" "s3_raw_sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.s3_raw_events.arn
  function_name    = aws_lambda_function.normalization_exporter.arn

  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true

  depends_on = [aws_iam_role_policy.lambda_sqs_raw]
}

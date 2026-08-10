resource "aws_sns_topic" "s3_notifications" {
  name = "s3-import-object-create-notifications"
  
  tags = {
    Name        = "S3 Object Create Notifications"
  }
}

resource "aws_sns_topic_policy" "s3_notifications_policy" {
  arn = aws_sns_topic.s3_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.s3_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn" = "${aws_s3_bucket.imports_bucket.arn}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.imports_bucket.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events = [
      "s3:ObjectCreated:*"  
    ]
    
  }

  depends_on = [aws_sns_topic_policy.s3_notifications_policy]
}

resource "aws_sns_topic_subscription" "https_notification" {
#   count     = var.notification_endpoint != "" ? 1 : 0
  topic_arn = aws_sns_topic.s3_notifications.arn
  protocol  = "https"
  endpoint  = "https://${var.notification_endpoint}/s3/webhook"
}

#exports2delta
# resource "aws_sns_topic" "s3_notifications_delta" {
#   name = "s3-import-object-create-notifications-delta"
  
#   tags = {
#     Name  = "S3 Object Create Notifications for Delta Exporter"
#   }
# }

# resource "aws_sns_topic_policy" "s3_notifications_policy_delta" {
#   arn = aws_sns_topic.s3_notifications_delta.arn

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "s3.amazonaws.com"
#         }
#         Action = "SNS:Publish"
#         Resource = aws_sns_topic.s3_notifications_delta.arn
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#           }
#           StringLike = {
#             "aws:SourceArn" = "${aws_s3_bucket.buckets["s3_exports"].arn}"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket_notification" "bucket_notification_delta" {
#   bucket = aws_s3_bucket.buckets["s3_exports"].id

#   topic {
#     topic_arn = aws_sns_topic.s3_notifications_delta.arn
#     events = [
#       "s3:ObjectCreated:*" 
#     ]
    

#   }

#   depends_on = [aws_sns_topic_policy.s3_notifications_policy_delta]
# }

# resource "aws_sns_topic_subscription" "https_notification_delta" {
# #   count     = var.notification_endpoint != "" ? 1 : 0
#   topic_arn = aws_sns_topic.s3_notifications_delta.arn
#   protocol  = "https"
#   endpoint  = "https://${var.notification_endpoint}/delta/webhook"
# }

#delta2importer
resource "aws_sns_topic" "s3_notifications_importer" {
  name = "s3-import-object-create-notifications-importer"
  
  tags = {
    Name        = "S3 Object Create Notifications for Importer"
  }
}

resource "aws_sns_topic_policy" "s3_notifications_policy_importer" {
  arn = aws_sns_topic.s3_notifications_importer.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.s3_notifications_importer.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn" = "${aws_s3_bucket.buckets["s3_delta"].arn}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification_importer" {
  bucket = aws_s3_bucket.buckets["s3_delta"].id

  topic {
    topic_arn = aws_sns_topic.s3_notifications_importer.arn
    events = [
      "s3:ObjectCreated:*"  
    ]
    
  }

  depends_on = [aws_sns_topic_policy.s3_notifications_policy_importer]
}

resource "aws_sns_topic_subscription" "https_notification_importer" {
  topic_arn = aws_sns_topic.s3_notifications_importer.arn
  protocol  = "https"
  endpoint  = "https://${var.notification_endpoint}/s3/webhook"
}
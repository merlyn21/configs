resource "local_file" "health_to_slack_py" {
  filename = "${path.module}/lambda_health_to_slack.py"
  content  = <<-EOF
import json
import urllib3
import os
import boto3

http = urllib3.PoolManager()
secretsmanager = boto3.client('secretsmanager')

def get_slack_webhook():
    """Get Slack Webhook URL from Secrets Manager"""
    secret_name = os.environ['SECRET_NAME']
    response = secretsmanager.get_secret_value(SecretId=secret_name)
    
    try:
        secret = json.loads(response['SecretString'])
        return secret.get('webhook_url') or secret.get('url') or secret.get('SLACK_WEBHOOK_URL')
    except json.JSONDecodeError:
        return response['SecretString']

def send_to_slack(event_detail):
    """Send message to Slack"""
    slack_webhook_url = get_slack_webhook()
    
    environment = os.environ.get('ENVIRONMENT', 'unknown').upper()
    event_arn = event_detail.get('arn', 'N/A')
    event_type = event_detail.get('eventTypeCode', 'N/A')
    event_category = event_detail.get('eventTypeCategory', 'N/A')
    service = event_detail.get('service', 'N/A')
    region = event_detail.get('region', 'global')
    start_time = str(event_detail.get('startTime', 'N/A'))
    end_time = str(event_detail.get('endTime', 'N/A'))
    status = event_detail.get('statusCode', 'N/A')
    
    descriptions = event_detail.get('eventDescription', [])
    description = 'No description available'
    if descriptions and len(descriptions) > 0:
        description = descriptions[0].get('latestDescription', 'No description available')
    
    if len(description) > 500:
        description = description[:497] + "..."
    
    if event_category == 'scheduledChange':
        emoji = '⚠️'
        title = 'AWS Health Scheduled Change'
    elif event_category == 'issue':
        emoji = '🔴'
        title = 'AWS Health Issue'
    elif event_category == 'accountNotification':
        emoji = '📢'
        title = 'AWS Health Account Notification'
    else:
        emoji = 'ℹ️'
        title = 'AWS Health Event'
    
    slack_message = {
        'text': f"[{environment}] {emoji} AWS Health: {event_type}",
        'blocks': [
            {
                'type': 'header',
                'text': {
                    'type': 'plain_text',
                    'text': f'{emoji} {title}',
                    'emoji': True
                }
            },
            {
                'type': 'section',
                'fields': [
                    {
                        'type': 'mrkdwn',
                        'text': f"*Environment:*\n{environment}"
                    },               
                    {
                        'type': 'mrkdwn',
                        'text': f"*Event Type:*\n{event_type}"
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f"*Category:*\n{event_category}"
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f"*Service:*\n{service}"
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f"*Region:*\n{region}"
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f"*Status:*\n{status}"
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f"*Start Time:*\n{start_time}"
                    }
                ]
            },
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f"*Description:*\n{description}"
                }
            }
        ]
    }
    
    try:
        encoded_msg = json.dumps(slack_message).encode('utf-8')
        resp = http.request('POST', slack_webhook_url, body=encoded_msg)
        print(f"Slack response: {resp.status}")
        return resp.status == 200
    except Exception as e:
        print(f"Error sending to Slack: {e}")
        return False

def lambda_handler(event, context):
    """Process AWS Health event from EventBridge"""
    print(f"Received event: {json.dumps(event)}")
    
    detail = event.get('detail', {})
    
    if not detail:
        print("No event detail found")
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid event format')
        }
    
    if send_to_slack(detail):
        return {
            'statusCode': 200,
            'body': json.dumps('Message sent to Slack successfully')
        }
    else:
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to send message to Slack')
        }
EOF
}

data "archive_file" "health_to_slack" {
  type        = "zip"
  output_path = "${path.module}/lambda_health_to_slack.zip"
  
  source {
    content  = local_file.health_to_slack_py.content
    filename = "index.py"
  }
  
  depends_on = [local_file.health_to_slack_py]
}

resource "aws_lambda_function" "health_to_slack" {
  filename      = data.archive_file.health_to_slack.output_path
  function_name = "aws-health-to-slack"
  role          = aws_iam_role.lambda_health_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  
  source_code_hash = data.archive_file.health_to_slack.output_base64sha256

  environment {
    variables = {
      SECRET_NAME = "slack-webhook-url-alerting"
      ENVIRONMENT = var.stage
    }
  }

  tags = {
    Name = "aws-health-to-slack"
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_to_slack.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aws_health_events.arn
}
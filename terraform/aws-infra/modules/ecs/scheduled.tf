data "archive_file" "lambda_trigger" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  type        = "zip"
  source_file = "${path.module}/lambda/trigger_exporter.py"
  output_path = "${path.module}/trigger_exporter.zip"

  depends_on = [local_file.lambda_trigger]
}

resource "local_file" "lambda_trigger" {
  count          = length(var.scheduled_exporters) > 0 ? 1 : 0

  content = <<EOF
import json
import os
import boto3

def get_exporter_overrides(project, environment, exporter_name):

    secrets_client = boto3.client('secretsmanager')
    
    secret_name = f"{project}/{environment}/exporter-overrides/{exporter_name}"
    
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        config = json.loads(response['SecretString'])
        
        print(f"Loaded config for {exporter_name}:")
        print(f"  Image tag: {config.get('image_tag')}")
        print(f"  Task Definition: {config.get('task_definition_arn')}")
        print(f"  Last updated: {config.get('last_updated')}")
        
        return config
    except secrets_client.exceptions.ResourceNotFoundException:
        print(f"ERROR: Configuration not found for {exporter_name}")
        print(f"Secret name: {secret_name}")
        print(f"You must run a manual GitHub Actions deploy at least once to create the configuration")
        raise Exception(f"Configuration not found for {exporter_name}. Run manual deploy first.")
    except Exception as e:
        print(f"Error loading config for {exporter_name}: {str(e)}")
        raise

def handler(event, context):
    """
    for ex:
    {
      "exporter_name": "exporter-offers",
      "environment": "prod"
    }
    """
    project = os.environ['PROJECT']
    stage = os.environ['STAGE']
    
    exporter_name = event.get('exporter_name')
    environment = event.get('environment', stage)
    
    print(f"Starting scheduled task: {exporter_name} in {environment}")
    
    config = get_exporter_overrides(project, environment, exporter_name)
    
    ecs_client = boto3.client('ecs')
    
    cluster = os.environ['ECS_CLUSTER']
    task_definition = config['task_definition_arn']
    overrides = config['overrides']
    
    subnets = os.environ['ECS_SUBNETS'].split(',')
    security_groups = [os.environ['ECS_SECURITY_GROUPS']]
    
    try:
        print(f"Running ECS task:")
        print(f"  Cluster: {cluster}")
        print(f"  Task Definition: {task_definition}")
        print(f"  Subnets: {subnets}")
        print(f"  Security Groups: {security_groups}")
        
        response = ecs_client.run_task(
            cluster=cluster,
            taskDefinition=task_definition,
            launchType='FARGATE',
            count=1,
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': subnets,
                    'securityGroups': security_groups,
                    'assignPublicIp': 'DISABLED'
                }
            },
            overrides=overrides
        )
        
        if response.get('failures'):
            print(f"Task failed to start: {response['failures']}")
            raise Exception(f"Failed to start task: {response['failures']}")
        
        task_arn = response['tasks'][0]['taskArn']
        print(f"✓ Successfully started task: {task_arn}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Task started for {exporter_name}',
                'environment': environment,
                'task_arn': task_arn,
                'task_definition': task_definition,
                'image_tag': config.get('image_tag'),
                'last_config_update': config.get('last_updated')
            })
        }
    
    except Exception as e:
        print(f"Error running task: {str(e)}")
        raise
EOF
  filename       = "${path.module}/lambda/trigger_exporter.py"
}

resource "aws_lambda_function" "trigger_scheduled_exporter" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  function_name = "${var.project}-ecs-trigger-scheduled-exporter"
  role          = aws_iam_role.lambda_trigger[0].arn
  handler       = "trigger_exporter.handler"
  runtime       = "python3.11"
  timeout       = 120

  filename         = data.archive_file.lambda_trigger[0].output_path
  source_code_hash = data.archive_file.lambda_trigger[0].output_base64sha256

  environment {
    variables = {
      PROJECT             = var.project
      STAGE               = var.stage
      ECS_CLUSTER         = aws_ecs_cluster.main.name
      ECS_SUBNETS         = join(",", var.private_subnet_ids)
      ECS_SECURITY_GROUPS = aws_security_group.ecs_tasks.id
    }
  }

}

resource "aws_iam_role" "lambda_trigger" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  name = "${var.project}-ecs-lambda-trigger-role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  role       = aws_iam_role.lambda_trigger[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  name = "${var.project}-ecs-lambda-secrets"
  role = aws_iam_role.lambda_trigger[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.stage}/exporter-overrides/*"
    },
    {
      Effect = "Allow"
      Action = ["kms:Decrypt"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ecs" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  name = "${var.project}-ecs-lambda"
  role = aws_iam_role.lambda_trigger[0].id

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

resource "aws_cloudwatch_log_group" "lambda_trigger" {
  count = length(var.scheduled_exporters) > 0 ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.trigger_scheduled_exporter[0].function_name}"
  retention_in_days = 7

}

# ==================== EventBridge ====================

resource "aws_cloudwatch_event_rule" "scheduled_exporter" {
  for_each = var.scheduled_exporters

  name                = "${var.project}-${var.stage}-${each.key}"
  description         = each.value.description != "" ? each.value.description : "Scheduled run for ${each.value.exporter_name}"
  schedule_expression = each.value.schedule_expression
  state               = each.value.enabled ? "ENABLED" : "DISABLED"

  tags = {
    Name        = "${var.project}-${var.stage}-${each.key}"
    Environment = var.stage
    Exporter    = each.value.exporter_name
    ManagedBy   = "terraform"
    Enabled     = tostring(each.value.enabled)
  }
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  for_each = var.scheduled_exporters

  rule      = aws_cloudwatch_event_rule.scheduled_exporter[each.key].name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.trigger_scheduled_exporter[0].arn

  input = jsonencode({
    exporter_name = each.value.exporter_name
    environment   = var.stage
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = var.scheduled_exporters

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_scheduled_exporter[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_exporter[each.key].arn
}

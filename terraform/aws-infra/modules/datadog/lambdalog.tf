resource "aws_cloudformation_stack" "datadog_forwarder" {
  name         = "datadog-forwarder"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  
  parameters = {
    DdApiKey            = var.datadog_api_key
    DdSite              = "us5.datadoghq.com"
    FunctionName        = "datadog-forwarder"
    # ReservedConcurrency = ""
    # DdForwarderLogSampling = "0.1"
    DdTags              = "env:${var.stage},project:${var.project},source:aws"
  }

  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/forwarder/latest.yaml"
}

# data "aws_caller_identity" "current" {}

data "aws_lambda_function" "datadog_forwarder" {
  function_name = "datadog-forwarder"
  # depends_on    = [aws_cloudformation_stack.datadog_forwarder]
}

data "aws_cloudwatch_log_groups" "ecs" {
  log_group_name_prefix = "/ecs"
}

locals {
  ecs_log_groups = toset(data.aws_cloudwatch_log_groups.ecs.log_group_names)
  sanitize       = { for name in local.ecs_log_groups :
    name => replace(replace(name, "/", "-"), ":", "-")
  }
}

# data "aws_cloudwatch_log_group" "existing_logs" {
#   for_each = toset([
#     # "/aws/eks/acmeparts-eks/cluster",
#     # "/aws/msk/acmeparts-${var.stage}-msk-cluster",
#     # "/aws/opensearch/acmeparts-opensearch/INDEX_SLOW_LOGS",
#     # "/aws/opensearch/acmeparts-opensearch/SEARCH_SLOW_LOGS"
#   ])
  
#   name = each.value
# }

resource "aws_cloudwatch_log_subscription_filter" "existing_logs_filter" {
  # for_each = data.aws_cloudwatch_log_group.existing_logs
  for_each        = local.ecs_log_groups
  
  name            = "datadog-log-filter-${local.sanitize[each.value]}"
  # "datadog-log-filter-${replace(each.key, "/", "-")}"
  log_group_name  = each.value
  filter_pattern = ""
  destination_arn = data.aws_lambda_function.datadog_forwarder.arn
  
  depends_on      = [aws_lambda_permission.allow_cloudwatch_logs_existing]
}

resource "aws_lambda_permission" "allow_cloudwatch_logs_existing" {
  for_each = local.ecs_log_groups
  # data.aws_cloudwatch_log_group.existing_logs
  
  statement_id  = "AllowExecutionFromCloudWatchLogs-${local.sanitize[each.value]}"
  # "AllowExecutionFromCloudWatchLogs-${replace(each.key, "/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.datadog_forwarder.function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${each.value}:*"
  # "${each.value.arn}:*"
    
}


resource "aws_appconfig_application" "this" {
  name        = "${var.project}-appconfig"
  description = "AppConfig application for ${var.project}"
}

resource "aws_appconfig_environment" "this" {
  application_id = aws_appconfig_application.this.id
  name           = "${var.project}-env"
  description    = "AppConfig environment for ${var.project}"
}

resource "aws_appconfig_configuration_profile" "this" {
  application_id = aws_appconfig_application.this.id
  name           = "${var.project}-config-profile"
  description    = "Configuration profile for ${var.project}"
  location_uri   = "hosted"
}

resource "aws_appconfig_hosted_configuration_version" "this" {
  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.this.configuration_profile_id
  content                  = jsonencode(var.initial_config)
  content_type             = "application/json"

  lifecycle {
    ignore_changes = [content]
  }
}

resource "aws_appconfig_deployment_strategy" "this" {
  name                = "${var.project}-deployment-strategy"
  description         = "Deployment strategy for ${var.project}"
  deployment_duration_in_minutes = "0"
  growth_factor       = 50
  replicate_to        = "NONE"
}

resource "aws_appconfig_deployment" "this" {
  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.this.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.this.version_number
  environment_id           = aws_appconfig_environment.this.environment_id
  deployment_strategy_id   = aws_appconfig_deployment_strategy.this.id
}

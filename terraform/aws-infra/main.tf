terraform {

  required_version = "~> 1.10.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    datadog = {
      source = "datadog/datadog"
      version = "3.69.0"
    }
  }
}


provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.stage
      Project     = var.project
      stack       = "backend"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.us5.datadoghq.com/"
}

module "network" {
  source = "./modules/network"
  project = var.project
  region = var.region
  vpc_cidr = var.vpc_cidr
  stage = var.stage
}

module "configuration" {
  source = "./modules/configuration"
  project = var.project
  initial_config = {}
}

module "database" {
  source = "./modules/database"
  project = var.project
  region = var.region
  db_version = var.db_version
  db_storage = var.db_storage
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  read_replicas_count = var.db_read_replicas_count
  backup_retention_period = var.db_backup_retention_period
  instance_class = var.db_instance_class
  db_multiaz = var.db_multiaz
  db_immediately = var.db_immediately
  rds_parameters = var.rds_parameters
  stage = var.stage
  skip_final_snapshot = var.db_skip_final_snapshot
}

module "k8s" {
  source = "./modules/k8s"
  region = var.region
  project = var.project
  stage = var.stage
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  instance_type = var.eks_instance_type
  autoscaling_policy = {
    desired_capacity = var.eks_desired_capacity
    min_size = var.eks_min_instances
    max_size = var.eks_max_instances
  }
  rds_security_group_id = module.database.client_security_group
  eks_version = var.eks_version
  certificate_arn = var.certificate_arn
  domain_name = var.domain_name
  eks_metric_version = var.eks_metric_version
  opensearch_domain_endpoint = module.opensearch.opensearch_domain_endpoint
  opensearch_domain_arn = module.opensearch.opensearch_arn
  s3_imports = var.s3_imports
  s3_buckets = var.s3_buckets
  datadog_api_key = var.datadog_api_key
  db_primary_endpoint = module.database.primary_endpoint
  db_password_secret_name = module.database.db_password_secret_name
  datadog_postgres_password = var.datadog_postgres_password
  rds_endpoint = module.database.primary_endpoint
  #cosign
  kyverno_version = var.kyverno_version
  kyverno_enforce = var.kyverno_enforce
  kyverno_target_namespaces = var.kyverno_target_namespaces
  cosign_oidc_issuer = var.cosign_oidc_issuer
  cosign_subject_regexp = var.cosign_subject_regexp
  enable_kyverno_policy = var.enable_kyverno_policy
}

module "opensearch" {
  source = "./modules/opensearch"
  region = var.region
  project = var.project
  stage = var.stage
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  eks_irsa_role_arn = module.k8s.eks_irsa_role_arn
  ecs_task_role_arn = module.ecs.ecs_task_role_arn
  opensearch_engine_version = var.opensearch_engine_version
  opensearch_node_type  = var.opensearch_node_type
  opensearch_node_count = var.opensearch_node_count  
  opensearch_dedicated_master_enabled = var.opensearch_dedicated_master_enabled
  opensearch_master_type = var.opensearch_master_type
  opensearch_master_count = var.opensearch_master_count
  opensearch_availability_zone_count = var.opensearch_availability_zone_count
  opensearch_volume_size = var.opensearch_volume_size
}

module "msk" {
  source = "./modules/msk"
  region = var.region
  project = var.project
  stage = var.stage
  vpc_id = module.network.vpc_id
  private_subnet_ids = slice(module.network.private_subnet_ids, 0, 2)
  kafka_version = var.kafka_version
  kafka_instance_type = var.kafka_instance_type
  kafka_number_of_broker_nodes = var.kafka_number_of_broker_nodes
  kafka_volume_size = var.kafka_volume_size
  kafka_volume_type = var.kafka_volume_type
  kafka_server_properties = var.kafka_server_properties
  kafka_monitoring = var.kafka_monitoring
}

resource "aws_appconfig_hosted_configuration_version" "opensearch_endpoint" {
  application_id           = module.configuration.application_id
  configuration_profile_id = module.configuration.configuration_profile_id
  content                  = jsonencode({
    //opensearch_endpoint = module.search.os_endpoint
    db_write_endpoint = module.database.primary_endpoint
    db_read_endpoints = module.database.read_endpoints
    msk_bootstrap_brokers = module.msk.msk_bootstrap_brokers
    opensearch_endpoint = module.opensearch.opensearch_domain_endpoint
    redis_endpoint = module.redis.redis_endpoint
  })
  content_type             = "application/json"
}

module "ecr_repo" {
  source = "./modules/ecr"

  for_each = toset(var.ecr_repo_names)

  repo_name = each.value
  region = var.region
  project = var.project
  ecr_number_images = var.ecr_number_images
}

module "redis" {
  source = "./modules/redis"
  region = var.region
  project = var.project
  stage = var.stage
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  redis_node_type = var.redis_node_type
  redis_parameter_group_name = var.redis_parameter_group_name
  redis_num_cache_nodes = var.redis_num_cache_nodes
}

module "acm" {
  source = "./modules/acm"
  region = var.region
  project = var.project
  domain_name = var.domain_name
  cloudfront_domain_name = var.cloudfront_domain_name
  cloudfront_domain_name_iag = var.cloudfront_domain_name_iag
  cloudfront_domain_name_files = var.cloudfront_domain_name_files
  domain_name_alb = var.domain_name_alb
  domain_name_alb_iag = var.domain_name_alb_iag
  domain_name_alb_dqc = var.domain_name_alb_dqc
  stage = var.stage
  create_waf = var.create_waf
  cloudfront_distribution = module.cloudfront.cloudfront_distribution
  cloudfront_distribution_iag = module.cloudfront.cloudfront_distribution_iag
  cloudfront_distribution_files = module.cloudfront.cloudfront_distribution_files
}

module "cloudfront" {
  source = "./modules/cloudfront"
  region = var.region
  project = var.project
  domain_name = var.domain_name
  cloudfront_domain_name = var.cloudfront_domain_name
  domain_name_alb = var.domain_name_alb
  certificate_arn = var.stage == "dev1" ? var.certificate_arn : module.acm.cloudfront_certificate_arn
  cloudfront_domain_name_iag = var.cloudfront_domain_name_iag
  domain_name_alb_iag = var.domain_name_alb_iag
  certificate_arn_iag = var.stage == "dev1" ? var.certificate_arn_iag : module.acm.cloudfront_certificate_arn_iag
  domain_name_alb_dqc = var.domain_name_alb_dqc
  cloudfront_domain_name_files = var.cloudfront_domain_name_files
  certificate_arn_files = var.stage == "dev1" ? var.certificate_arn_files : module.acm.cloudfront_certificate_arn_files
  waf_limit = var.waf_limit
  auth_user = var.auth_user
  stage = var.stage
  create_waf = var.create_waf
  waf_allowed_ip = var.waf_allowed_ip
  oidc_host = var.oidc_host
}

module "s3" {
  source = "./modules/s3"
  count = (var.stage != "dev1" && var.create_waf) ? 1 : 0
  region = var.region
  project = var.project
  stage = var.stage
  s3_imports = var.s3_imports
  s3_buckets = var.s3_buckets
  notification_endpoint = var.cloudfront_domain_name
  aws_cloudfront_images_arn = var.aws_cloudfront_images_arn
}

module "datadog" {
  count  = (var.stage != "dev1") ? 1 : 0
  source = "./modules/datadog"
  region = var.region
  project = var.project
  stage = var.stage
  datadog_api_key = var.datadog_api_key
  datadog_app_key = var.datadog_app_key
}

module "ecs" {
  source = "./modules/ecs"
  region = var.region
  project = var.project
  stage = var.stage
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  scheduled_exporters = var.scheduled_exporters
  s3_buckets = var.s3_buckets
}

module "alerting" {
  source = "./modules/alerting"
  region = var.region
  project = var.project
  stage = var.stage
}
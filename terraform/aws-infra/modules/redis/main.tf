provider "aws" {
  region = var.region
}

locals { 
  redis_cluster_name  = "${var.project}-elasticache"
  redis_password      = random_password.redis_password.result
}

resource "random_password" "redis_password" {
  length           = 32
  special          = true
  override_special = "!&#$^<>-"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

resource "aws_secretsmanager_secret" "redis_password" {
  name        = "${var.project}-redis"
  description = "Authentication password for ${var.project} Redis cluster"
}

resource "aws_secretsmanager_secret_version" "redis_password_version" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = jsonencode({
    username = "default"
    password = local.redis_password
    host     = aws_elasticache_replication_group.redis_cluster.primary_endpoint_address
    port     = "${aws_elasticache_replication_group.redis_cluster.port}"
  })
}

resource "aws_elasticache_parameter_group" "redis_params" {
  family      = "redis7"
  name        = "${var.project}-redis-params"
  description = "Custom parameter group for Redis with AUTH enabled"

  parameter {
    name  = "timeout"
    value = "300"
  }
}

resource "aws_elasticache_replication_group" "redis_cluster" {

  replication_group_id       = local.redis_cluster_name
  description = "Redis cluster for ${var.project}"
  
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_clusters   = 1 
  parameter_group_name = aws_elasticache_parameter_group.redis_params.name
  port                 = 6379
  
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = local.redis_password
  
  automatic_failover_enabled = false 
  
  apply_immediately = var.stage == "prod" ? false : true
  
  snapshot_retention_limit = var.stage == "prod" ? 7 : 0
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }

  tags = {
    Name        = "${var.project}-redis"
  }
}

data "aws_vpc" "our_vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.project}-redis-security-group"
  description = "Security group for Redis ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project}-redis-sg"
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project}-${var.stage}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-redis-subnet-group"
  }
}
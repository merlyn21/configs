provider "aws" {
  region = var.region
}

locals {
  enable_enhanced_monitoring = var.stage == "stage" || var.stage == "prod"
}

resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "_"
}

locals {
  db_password = random_password.master_password.result
}

data "aws_vpc" "our_vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "postgres" {
  name        = "${var.project}-postgres-sg"
  description = "Allow traffic to RDS from clients"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.clients.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "clients" {
  name        = "${var.project}-clients-sg"
  description = "Allow clients to connect to RDS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "primary" {
  identifier         = "${var.project}-primary"
  engine             = "postgres"
  engine_version     = var.db_version
  auto_minor_version_upgrade = false
  apply_immediately  = var.db_immediately
  instance_class     = var.instance_class
  allocated_storage  = var.db_storage
  storage_type       = "gp3"

  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  multi_az          = var.db_multiaz
  storage_encrypted = true
  username          = var.project
  password          = local.db_password
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:05:00-mon:06:00"
  skip_final_snapshot     = var.skip_final_snapshot
  parameter_group_name = aws_db_parameter_group.postgres_parameter_group.name
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = local.enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn = local.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports = ["postgresql"]
  # lifecycle {
  #   ignore_changes = [
  #     engine_version,
  #   ]
  # }
}

resource "aws_db_instance" "replicas" {
  count                = var.read_replicas_count
  identifier           = "${var.project}-replica-${count.index + 1}"
  engine               = aws_db_instance.primary.engine
  instance_class       = var.instance_class
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  replicate_source_db  = aws_db_instance.primary.arn
  auto_minor_version_upgrade = false
  storage_encrypted    = true
  storage_type         = "gp3"
  skip_final_snapshot  = true
  apply_immediately    = var.db_immediately
  backup_window           = "01:00-02:00"
  maintenance_window      = "mon:03:00-mon:04:00"
}

resource "aws_secretsmanager_secret" "master_password" {
  name        = "${var.project}-db"
  description = "Master password for ${var.project} database"
}

resource "aws_secretsmanager_secret_version" "master_password_version" {
  secret_id     = aws_secretsmanager_secret.master_password.id
  secret_string = jsonencode({
    username = var.project
    password = local.db_password
  })
}

resource "aws_db_parameter_group" "postgres_parameter_group" {
  name   = "postgres-17-production-params"
  family = "postgres17"

  dynamic "parameter" {
    for_each = var.rds_parameters
    content {
      name  = parameter.key
      value = parameter.value
      apply_method = "pending-reboot"
    }
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "250"
  }
  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "60000"
  }
  parameter {
    name  = "log_temp_files"
    value = "512"
  }
  parameter {
    name  = "log_autovacuum_min_duration"
    value = "0"
  }
  parameter {
    name  = "random_page_cost"
    value = "1.1"
  }
  parameter {
    name         = "max_slot_wal_keep_size"
    value        = "10240"
    apply_method = "immediate"
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "rds-enhanced-monitoring-role"
  count = local.enable_enhanced_monitoring ? 1 : 0
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = local.enable_enhanced_monitoring ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

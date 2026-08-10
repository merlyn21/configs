provider "aws" {
  region = var.region
}

data "aws_vpc" "our_vpc" {
  id = var.vpc_id
}

module "msk" {
  source  = "terraform-aws-modules/msk-kafka-cluster/aws"
  version = "2.11.0"

  name = "${var.project}-${var.stage}-msk-cluster"
  kafka_version = "${var.kafka_version}"
  number_of_broker_nodes = var.kafka_number_of_broker_nodes

  broker_node_instance_type = "${var.kafka_instance_type}"
  broker_node_client_subnets = var.private_subnet_ids
  broker_node_security_groups = [aws_security_group.msk_sg.id]

  broker_node_storage_info = {
    ebs_storage_info = { 
      volume_size = var.kafka_volume_size 
      volume_type = var.kafka_volume_type
      iops        = 3000
      }
  }

  enhanced_monitoring = var.kafka_monitoring
  cloudwatch_logs_enabled = true
  cloudwatch_log_group_retention_in_days = 3

  encryption_in_transit_client_broker = "PLAINTEXT"
  encryption_at_rest_kms_key_arn = var.stage == "prod" ? aws_kms_key.msk_kms.arn : null

  create_configuration = true
  configuration_name        = "${var.project}-${var.stage}-msk-cluster-configuration"
  configuration_description = "${var.project}-${var.stage}-msk-cluster configuration"
  configuration_server_properties = var.kafka_server_properties

  tags = {
    Environment = "${var.stage}"
    cluster = "${var.project}-${var.stage}-msk-cluster"
  }
}

resource "aws_security_group" "msk_sg" {
  name        = "msk-security-group-${var.stage}"
  description = "Security group for AWS MSK"
  vpc_id      = var.vpc_id

    ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }
  
  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }


  ingress {
    from_port   = 2182
    to_port     = 2182
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.our_vpc.cidr_block]
  }

  tags = {
    Name        = "msk-security-group"
    Environment = "${var.stage}"
  }
}

resource "aws_kms_key" "msk_kms" {
  description             = "MSK encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
terraform {
  backend "s3" {
    bucket         = "unical_name_s3_backet"
    key            = "NAME/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "name-terraform-lock"
    encrypt        = true
  }
}




provider "aws" {
  region  = "eu-central-1"
  version = "~> 3.0"
}

locals {
  project_name      = "Project"
  vpc_cidr_block    = "10.1.0.0/16"
  subnet_cidr_block = "10.1.1.0/24"
  az_public_subnet  = "eu-central-1a"

  name          = "instance-name"
  ami           = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  instance_type = "t3.medium"

}

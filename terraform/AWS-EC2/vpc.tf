resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    Name    = format("vpc-%s", local.project_name)
    Project = local.project_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.subnet_cidr_block
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = local.az_public_subnet
  tags = {
    Name    = format("public_subnet-%s", local.project_name)
    Project = local.project_name
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = format("internet_gateway-%s", local.project_name)
    Project = local.project_name
  }
}


resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


resource "aws_route_table_association" "aws_route_table_association_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}

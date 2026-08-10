provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = "${var.project}-vpc"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.project}-igw"
    }
  )
}

resource "aws_eip" "nat" {
  count = 1

  tags = merge(
    {
      Name = "${var.project}-nat-eip-${count.index + 1}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  // @todo for the prod environment we need one nat for each public subnet
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags = merge(
    {
      Name = "${var.project}-nat"
    }
  )
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.this.names, count.index)

  tags = merge(
    {
      Name = "${var.project}-public-subnet-${count.index + 1}"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.project}-public-rt"
    }
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 3)
  availability_zone = element(data.aws_availability_zones.this.names, count.index)

  tags = merge(
    {
      Name = "${var.project}-private-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb" = "1"
      "karpenter.sh/discovery" = "${var.project}-eks"
    }
  )
}

resource "aws_route_table" "private" {
  count = 3

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.project}-private-rt-${count.index + 1}"
    }
  )
}

resource "aws_route" "private" {
  count                 = 3
  route_table_id        = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id        = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

data "aws_availability_zones" "this" {
  state = "available"
}

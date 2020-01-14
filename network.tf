resource "aws_vpc" "main" {
  cidr_block = "${var.vpc-base}.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc-base}.0/25"
  availability_zone = "${var.region}a"
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_subnet" "db-subnet-main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc-base}.128/26"
  availability_zone = "${var.region}a"
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_subnet" "db-subnet-failover" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc-base}.192/26"
  availability_zone = "${var.region}b"
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_internet_gateway" "vpc-internet-gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_route_table" "vpc-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_route_table_association" "public-subnet-route-association" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.vpc-route-table.id}"
}

resource "aws_default_route_table" "vpc-internet-gw" {
  default_route_table_id = "${aws_route_table.vpc-route-table.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc-internet-gw.id}"
  }
  tags = {
    CostCenter = "${var.cost-center}"
  }
}
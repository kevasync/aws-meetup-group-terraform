variable "vpc-base" {
  type = string
  default = "192.168.200"
  description = "First 3 octets for VPC CIDR Block Base address - class C subnet"
}

variable "cost-center" {
  type = string
  default = "tinn"
  description = "Cost Center responsible for operational costs"
}

variable "region" {
  type = string
  default = "us-east-1"
  description = "Region to create resources in"
}

variable "db-user" {
  type = string
  default = "meetupdbuser"
  description = "Master DB Username"
}

variable "db-password" {
  type = string
  default = "awsmeetupdbPwd!0"
  description = "Master DB Password"
}

variable "ssh-location" {
  type = string
  default = "0.0.0.0/0"
  description = "Allowed locations for SSH"
}

variable "instance-type" {
  type = string
  default = "t2.small"
  description = "Type of EC2 instance"
}

variable "ec2-key-name" {
  type = string
  default = "aws-meetup-group-key"
  description = "Name of EC2 key to use for SSH connectivity to EC2 instance"
}


provider "aws" {
  version = "~> 2.0"
  region  = var.region
}


### Netwokring

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc-base}.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${var.vpc-base}.0/25"
  availability_zone = "${var.region}a"
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_subnet" "db-subnet-main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${var.vpc-base}.128/26"
  availability_zone = "${var.region}a"
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_subnet" "db-subnet-failover" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${var.vpc-base}.192/26"
  availability_zone = "${var.region}b"
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_internet_gateway" "vpc-internet-gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_route_table" "vpc-route-table" {
  vpc_id = aws_vpc.main.id
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_route_table_association" "public-subnet-route-association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.vpc-route-table.id
}

resource "aws_default_route_table" "vpc-internet-gw" {
  default_route_table_id = aws_route_table.vpc-route-table.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-internet-gw.id
  }
  tags = {
    CostCenter = var.cost-center
  }
}


### DB 

resource "aws_db_subnet_group" "db-subnet-group" {
  subnet_ids = [aws_subnet.db-subnet-main.id, aws_subnet.db-subnet-failover.id]
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "defaultdb"
  username             = var.db-user
  password             = var.db-password
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.id
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  multi_az = true
  tags = {
    CostCenter = var.cost-center
  }
}


### EC2

data "aws_ami" "amzn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [
    "amazon",
    "self",
  ]
}

resource "aws_security_group" "ec2-sg" {
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh-location]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    CostCenter = var.cost-center
  }
}

resource "aws_instance" "web" {
  instance_type               = var.instance-type
  ami                         = data.aws_ami.amzn.id
  key_name                    = var.ec2-key-name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  security_groups             = [aws_security_group.ec2-sg.id]
  tags = {
    CostCenter = var.cost-center
  }
}




    





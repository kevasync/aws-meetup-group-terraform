variable "vpc-base" {
  type = "string"
  default = "192.168.200"
  description = "First 3 octets for VPC CIDR Block Base address - class C subnet"
}

variable "cost-center" {
  type = "string"
  default = "tinn"
  description = "Cost Center responsible for operational costs"
}

variable "region" {
  type = "string"
  default = "us-east-1"
  description = "Region to create resources in"
}

variable "db-user" {
  type = "string"
  default = "meetupdbuser"
  description = "Master DB Username"
}

variable "db-password" {
  type = "string"
  default = "awsmeetupdbPwd!0"
  description = "Master DB Password"
}

variable "ssh-location" {
  type = "string"
  default = "0.0.0.0/0"
  description = "Allowed locations for SSH"
}

variable "instance-type" {
  type = "string"
  default = "t2.small"
  description = "Type of EC2 instance"
}

variable "ec2-key-name" {
  type = "string"
  default = "aws-meetup-group-key"
  description = "Name of EC2 key to use for SSH connectivity to EC2 instance"
}

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
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh-location}"]
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
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_instance" "web" {
  instance_type               = "${var.instance-type}"
  ami                         = "${data.aws_ami.amzn.id}"
  key_name                    = "${var.ec2-key-name}"
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.public.id}"
  security_groups             = ["${aws_security_group.ec2-sg.id}"]
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

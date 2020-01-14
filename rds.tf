resource "aws_db_subnet_group" "db-subnet-group" {
  subnet_ids = ["${aws_subnet.db-subnet-main.id}", "${aws_subnet.db-subnet-failover.id}"]
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ec2-sg.id}"]
  }
  tags = {
    CostCenter = "${var.cost-center}"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "defaultdb"
  username             = "${var.db-user}"
  password             = "${var.db-password}"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "${aws_db_subnet_group.db-subnet-group.id}"
  vpc_security_group_ids  = ["${aws_security_group.db-sg.id}"]
  skip_final_snapshot     = true
  # multi_az = true
  tags = {
    CostCenter = "${var.cost-center}"
  }
}
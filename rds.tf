##-------------------only need this for relational database deployments--------------------
/*
# --------------------------RDS security group--------------------------

resource "aws_security_group" "rds_sg" {
  name   = "${var.project_name}-rds-sg-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 3306 // sql port
    to_port          = 3306
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}


# -------------------------------DB subnet group----------------------------

resource "aws_db_subnet_group" "rds_eks" {
  name       = "${var.project_name}-subnet-gr-${var.environment}"
  subnet_ids = [aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id]
}

# --------------------------------RDS database------------------------------

resource "aws_db_instance" "rds" {
  identifier              = "${var.project_name}-usermgmtdb-${var.environment}" // name chage broke app
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = var.rds_instance // db.t2.micro
  allocated_storage       = 20
  storage_type            = var.rds_storage_type // gp2
  name                    = "usermgmt"
  username                = "dbadmin" // i could use secrets for this two
  password                = "dbpassword11"
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_eks.name
}

*/



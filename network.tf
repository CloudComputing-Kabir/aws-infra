resource "aws_vpc" "assignment_3_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}


# Security Group
resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "Allow HTTPS to web server"
  vpc_id      = aws_vpc.assignment_3_vpc.id

  ingress = [
    {
      description      = "HTTPS ingress"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      security_groups  = ["${aws_security_group.load-balancer.id}"]
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    # {
    #   description     = "HTTPS ingress"
    #   from_port       = 80
    #   to_port         = 80
    #   protocol        = "tcp"
    #   security_groups = ["${aws_security_group.load-balancer.id}"]
    #   cidr_blocks      = ["0.0.0.0/0"]
    #   ipv6_cidr_blocks = []
    #   prefix_list_ids  = []
    #   security_groups  = []
    #   self             = false
    # },
     {
      description     = "HTTPS ingress"
      from_port       = 2000
      to_port         = 2000
      protocol        = "tcp"
      security_groups = ["${aws_security_group.load-balancer.id}"]
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  egress {
    description      = "Outbound Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = {
    Name = "Web app security group"
  }
}

#Security group for the RDS:

resource "aws_security_group" "db_security_group" {
  name_prefix = "db_security_group"
  vpc_id      = aws_vpc.assignment_3_vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_app_sg.id]
  }
}

#RDS Parameter group:

resource "aws_db_parameter_group" "rds_parameter_group" {
  name_prefix = "rds-parameter-group"
  family      = var.rds_engine_family
  description = "Custom Parameter Group for ${var.rds_engine}"
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = {
    "Name" = "RDS PARAMETER TAG"
  }

}

#Security group for the load balancer:
resource "aws_security_group" "load-balancer" {
  name        = "load-balancer"
  description = "For the Load Balancer"
  vpc_id      = aws_vpc.assignment_3_vpc.id

  ingress {
    description = "Allow HTTP traffic from the load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


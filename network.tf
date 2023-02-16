resource "aws_vpc" "assignment_3_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "my-vpc"
  }
}

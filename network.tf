resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "my-vpc"
  }
}

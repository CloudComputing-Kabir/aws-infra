resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.assignment_3_vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.assignment_3_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.assignment_3_vpc.id
  tags = {
    Name = "Private Route Table"
  }
}
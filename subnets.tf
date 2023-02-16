resource "aws_subnet" "subnet" {
  count             = length(var.subnets)
  vpc_id            = aws_vpc.assignment_3_vpc.id
  cidr_block        = var.subnets[count.index].cidr_block
  availability_zone = "${var.region}${var.subnets[count.index].availability_zone}"
  tags = {
    Name = var.subnets[count.index].name
  }
}
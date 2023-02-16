resource "aws_route_table_association" "a" {
  count          = length(var.subnets)
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = var.subnets[count.index].ispublic ? aws_route_table.public_route_table.id : aws_route_table.private_route_table.id
}

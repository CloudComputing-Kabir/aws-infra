# Create EC2 instance
data "aws_ami" "ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["webapp - 20230223212439"]
  }
}

resource "aws_instance" "web_app" {
  ami                         = data.aws_ami.ami.id
  instance_type               = "t2.micro"
  subnet_id                   = element(aws_subnet.subnet[*].id, 0)
  vpc_security_group_ids      = [aws_security_group.web_app_sg.id]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  tags = {
    Name = "Web app"
  }
}



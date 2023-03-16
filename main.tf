# Create EC2 instance
data "aws_ami" "ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["webapp - 20230316170624"]
  }
}

resource "aws_instance" "web_app" {
  ami                         = data.aws_ami.ami.id
  instance_type               = "t2.micro"
  subnet_id                   = element(aws_subnet.subnet[*].id, 0)
  vpc_security_group_ids      = [aws_security_group.web_app_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.webapppofile.name
  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  user_data = <<-EOF
  #!/bin/bash
  echo DB_USERNAME='${aws_db_instance.rds_cloud_database.username}' >>  /home/ec2-user/webapp/.env
  echo DB_DNAME='${aws_db_instance.rds_cloud_database.db_name}' >>  /home/ec2-user/webapp/.env
  echo DB_PASSWORD='${aws_db_instance.rds_cloud_database.password}'>>  /home/ec2-user/webapp/.env
  echo DB_HOSTNAME='${aws_db_instance.rds_cloud_database.address}'>>  /home/ec2-user/webapp/.env
  echo S3_BUCKETNAME='${aws_s3_bucket.s3Bucket.bucket}'>>  /home/ec2-user/webapp/.env
  echo S3_BUCKETREGION='${var.region}'>>  /home/ec2-user/webapp/.env
EOF

  tags = {
    Name = "Web app"
  }
}

#Create RDS Instance:
resource "aws_db_instance" "rds_cloud_database" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "csye6225"
  username               = "csye6225"
  password               = var.rds_pasword
  publicly_accessible    = true
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rdsSubnet.name

  tags = {
    "Name" = "RDS_DATABASE_FOR_CLOUD_ASSIGNMENT"
  }
}

resource "aws_db_subnet_group" "rdsSubnet" {
  name       = "rds-subnet"
  subnet_ids = [element(aws_subnet.subnet[*].id, 4), element(aws_subnet.subnet[*].id, 3)]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "random_id" "random" {
  byte_length = 4
}

#Create S3 Bucket Instance:
resource "aws_s3_bucket" "s3Bucket" {
  bucket        = "${var.profile}-bucket-${random_id.random.hex}"
  force_destroy = true

}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.s3Bucket.id
  acl    = "private"
}


resource "aws_s3_bucket_lifecycle_configuration" "s3BucketLifeCycle" {
  bucket = aws_s3_bucket.s3Bucket.id
  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3BucketEncryption" {
  bucket = aws_s3_bucket.s3Bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}



# #S3 Bucket Policy for the user:
# resource "aws_s3_bucket_policy" "s3_bucketPolicy" {
#   bucket = aws_s3_bucket.s3Bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           "${aws_s3_bucket.s3Bucket.arn}",
#           "${aws_s3_bucket.s3Bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }

#IAM User:

resource "aws_iam_policy" "webappS3" {
  name        = "webappS3"
  description = "Allow EC2 instances to perform S3 buckets."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:PutObject", "s3:DeleteObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3Bucket.arn}",
          "${aws_s3_bucket.s3Bucket.arn}/*"
        ]
      }
    ]
  })
}

#IAM Role:

resource "aws_iam_role" "webappS3Role" {
  name = "EC2-CSYE6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#IAM Role Policy attatchment:

resource "aws_iam_policy_attachment" "roleAndPolicyAttatchment" {
  name       = "policy-attachment"
  policy_arn = aws_iam_policy.webappS3.arn
  roles      = [aws_iam_role.webappS3Role.name]
}

resource "aws_iam_instance_profile" "webapppofile" {
  name = "webappprofile"
  role = aws_iam_role.webappS3Role.name
}

//Route53:
data "aws_route53_zone" "selected" {
  name         = "${var.profile}.shaikhkabir.com"
  private_zone = false
}

resource "aws_route53_record" "route_54_www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.profile}.shaikhkabir.com"
  type    = "A"
  ttl     = "60"
  records = [ aws_instance.web_app.public_ip ]
}

# resource "aws_eip" "webapp_eip" {
#   instance = aws_instance.web_app.id
#   vpc      = true
# }

# resource "aws_eip_association" "web_app_eip_assoc" {
#   instance_id   = aws_instance.web_app.id
#   allocation_id = aws_eip.web_app_eip.id
# }
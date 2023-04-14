# Create EC2 instance
# data "aws_ami" "ami" {
#   most_recent = true
#   filter {
#     name   = "name"
#     values = var.ami
#   }
# }

# resource "aws_instance" "web_app" {
#   ami                         = data.aws_ami.ami.id
#   instance_type               = "t2.micro"
#   subnet_id                   = element(aws_subnet.subnet[*].id, 0)
#   vpc_security_group_ids      = [aws_security_group.web_app_sg.id]
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.webapppofile.name
#   root_block_device {
#     delete_on_termination = true
#     volume_size           = 50
#     volume_type           = "gp2"
#   }

#   user_data = <<-EOF
#   #!/bin/bash
#   echo DB_USERNAME='${aws_db_instance.rds_cloud_database.username}' >>  /home/ec2-user/webapp/.env
#   echo DB_DNAME='${aws_db_instance.rds_cloud_database.db_name}' >>  /home/ec2-user/webapp/.env
#   echo DB_PASSWORD='${aws_db_instance.rds_cloud_database.password}'>>  /home/ec2-user/webapp/.env
#   echo DB_HOSTNAME='${aws_db_instance.rds_cloud_database.address}'>>  /home/ec2-user/webapp/.env
#   echo S3_BUCKETNAME='${aws_s3_bucket.s3Bucket.bucket}'>>  /home/ec2-user/webapp/.env
#   echo S3_BUCKETREGION='${var.region}'>>  /home/ec2-user/webapp/.env
# EOF

#   tags = {
#     Name = "Web app"
#   }
# }

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
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds-kms-key.arn

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
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

//IAM role for cloudwatch:
data "aws_iam_policy" "CloudWatchAgentServerPolicy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_policy_attachment" "CloudWatchAgentServerPolicy_Policy" {
  name       = "policy-attachment-CloudWatch"
  policy_arn = data.aws_iam_policy.CloudWatchAgentServerPolicy.arn
  roles      = [aws_iam_role.webappS3Role.name]
}
resource "aws_iam_policy_attachment" "AmazonSSMManagedInstanceCore_Policy" {
  name       = "policy-attachment-AmazonSSM"
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
  roles      = [aws_iam_role.webappS3Role.name]
}

//Auto Scaling Config:
resource "aws_launch_template" "launch-config" {
  image_id      = var.ami
  instance_type = "t2.micro"
  name          = "launch-config"
  # security_groups = [aws_security_group.load-balancer.id]
  user_data = base64encode(<<-EOF
  #!/bin/bash
  echo DB_USERNAME='${aws_db_instance.rds_cloud_database.username}' >>  /home/ec2-user/webapp/.env
  echo DB_DNAME='${aws_db_instance.rds_cloud_database.db_name}' >>  /home/ec2-user/webapp/.env
  echo DB_PASSWORD='${aws_db_instance.rds_cloud_database.password}'>>  /home/ec2-user/webapp/.env
  echo DB_HOSTNAME='${aws_db_instance.rds_cloud_database.address}'>>  /home/ec2-user/webapp/.env
  echo S3_BUCKETNAME='${aws_s3_bucket.s3Bucket.bucket}'>>  /home/ec2-user/webapp/.env
  echo S3_BUCKETREGION='${var.region}'>>  /home/ec2-user/webapp/.env
EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_app_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.webapppofile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50
      delete_on_termination = true
      volume_type           = "gp2"
      encrypted             = true
      kms_key_id            = aws_kms_key.aws-infra-kms-key.arn
    }
  }

}


#Auto scaling group:
resource "aws_autoscaling_group" "asg" {
  name                      = "csye6225-asg-spring2023"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = [for subnet in aws_subnet.subnet : subnet.id]
  default_cooldown          = 60

  tag {
    key                 = "Name"
    value               = "Webapp - ${var.ami}"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.launch-config.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.alb_tg.arn
  ]

}


//Auto Scaling Policy:
resource "aws_autoscaling_policy" "asg_up_policy" {
  name                   = "csye6225-asg-up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  scaling_adjustment     = 1
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_metric_up" {
  alarm_name          = "auto-scaling-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_actions = [aws_autoscaling_policy.asg_up_policy.arn]
}

resource "aws_autoscaling_policy" "asg_down_policy" {
  name                   = "csye6225-asg-down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  scaling_adjustment     = -1
}

resource "aws_cloudwatch_metric_alarm" "autoscaling_metric_down" {
  alarm_name          = "auto-scaling-down-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_actions = [aws_autoscaling_policy.asg_down_policy.arn]
}




//Load Balancer:
resource "aws_lb" "lb" {
  name               = "csye6225-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = [for subnet in aws_subnet.subnet : subnet.id]
  ip_address_type    = "ipv4"


  tags = {
    Application = "WebApp"
  }
}

//Load Balancer Listener:
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80     //Cross check
  protocol          = "HTTP" //Cross check
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

//Load Balancer Target Group:
resource "aws_lb_target_group" "alb_tg" {
  name        = "csye6225-lb-alb-tg"
  target_type = "instance"
  vpc_id      = aws_vpc.assignment_3_vpc.id
  port        = 2000
  protocol    = "HTTP"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "2000"
    protocol            = "HTTP"
  }
}

//Instance registration for target group:
resource "aws_autoscaling_attachment" "webapp_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.alb_tg.arn
}




//KMS key for EBS encryption:
resource "aws_kms_key" "aws-infra-kms-key" {
  description              = "EC2 KMS Key"
  deletion_window_in_days  = 7
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode(
    {
      "Id" : "key-consolepolicy-3",
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.active.account_id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "Allow access for Key Administrators",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            ]
          },
          "Action" : [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Allow use of the key",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            ]
          },
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Allow attachment of persistent resources",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            ]
          },
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource" : "*",
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        }
      ]
    }
  )
}

//KMS key for the RDS encryption:
resource "aws_kms_key" "rds-kms-key" {
  description              = "RDS KMS Key"
  deletion_window_in_days  = 7
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode(
    {
      "Id" : "key-consolepolicy-3",
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.active.account_id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "Allow access for Key Administrators",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            ]
          },
          "Action" : [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Allow use of the key",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            ]
          },
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Allow attachment of persistent resources",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${data.aws_caller_identity.active.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            ]
          },
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource" : "*",
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        }
      ]
    }
  )
}


//Caller Identity:
data "aws_caller_identity" "active" {

}
resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.profile == "demo" ? "arn:aws:acm:us-east-1:146721225773:certificate/f6ea008f-8627-46f7-a71b-5dc30d2521c6" : "arn:aws:acm:us-east-1:072975252406:certificate/ebfcaa2f-292f-489c-a2de-c4b3b6b071c1"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}


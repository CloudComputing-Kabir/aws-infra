variable "region" {
  description = "The AWS region to create the VPC in"
  default     = "us-east-1"
}

variable "profile" {
  default = "dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "ami" {
  type    = string
  default = "ami-0fa1de1d60de6a97e"
}

variable "subnets" {
  description = "A list of subnets to create in the VPC"
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    ispublic          = bool
  }))
}

#RDS Variables:
variable "rds_pasword" {
  description = "password for the RDS"
  default     = "Kabir12345"
}

variable "default_vpc_rds" {
  description = "Default VPC is getting used at the moment for the RDS"
  default     = "vpc-03f9052f3d7ca86cb"
}

variable "rds_engine_family" {
  description = "Family name for the rds parameter"
  default     = "mysql8.0"
}

variable "rds_engine" {
  description = "RDS engine name"
  default     = "mysql8.0"
}

#S3 Bucket Variables:

variable "bucketName" {
  description = "S3 Bucket name"
  default     = "s3-webapp"
}


//Assignment - 9 Changes:

variable "environment" {
  description = "The environment where the infra will be deployed"
  default     = "dev"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:072975252406:certificate/ebfcaa2f-292f-489c-a2de-c4b3b6b071c1"
}


# variable "rds_engine_version" {
#   description        = "RDS engine version"
#   version = "8.0.27"
# }


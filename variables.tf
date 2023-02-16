variable "region" {
  description = "The AWS region to create the VPC in"
  default     = "us-east-1"
}

variable "profile" {
  default ="dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
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

region   = "us-east-1"
profile  = "demo"
vpc_cidr = "10.0.0.0/16"
subnets = [
  {
    name              = "public"
    cidr_block        = "10.0.1.0/24"
    availability_zone = "a"
    ispublic          = true
  },
  {
    name              = "public"
    cidr_block        = "10.0.2.0/24"
    availability_zone = "b"
    ispublic          = true
  },
  {
    name              = "public"
    cidr_block        = "10.0.3.0/24"
    availability_zone = "c"
    ispublic          = true
  },
  {
    name              = "private"
    cidr_block        = "10.0.4.0/24"
    availability_zone = "d"
    ispublic          = false
  },
  {
    name              = "private"
    cidr_block        = "10.0.5.0/24"
    availability_zone = "e"
    ispublic          = false
  },
  {
    name              = "private"
    cidr_block        = "10.0.6.0/24"
    availability_zone = "f"
    ispublic          = false
  },
]
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_region" "current" {}

locals {
  std_name    = "heartcentrix-assesment"
  vpc_cidr    = "10.0.0.0/16"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)
  k8s_version = "1.31"
}



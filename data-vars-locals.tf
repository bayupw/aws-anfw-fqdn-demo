data "aws_availability_zones" "available" {
  state = "available"
}

variable "supernet" {
  type    = string
  default = "10.0.0.0/8"
}

locals {
  protected_vpc_a_cidr = cidrsubnet(var.supernet, 8, 1) # 10.1.0.0/16
  protected_vpc_b_cidr = cidrsubnet(var.supernet, 8, 2) # 10.2.0.0/16
}
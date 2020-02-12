/**
 * Get AWS info.
 */
data "aws_caller_identity" "current" {}

/**
 * Make current vpc's az's available
 */
data "aws_availability_zones" "available" {}

provider "aws" {
  profile = var.profile
  region =  var.region
  version = ">= 2.28.1"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.22.0"
  name    = "vpc-${terraform.workspace}"
  cidr    = var.vpc_cidr_block

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
  ]

  private_subnets = ["${cidrsubnet("${var.vpc_cidr_block}", 4, 1)}","${cidrsubnet("${var.vpc_cidr_block}", 4, 2)}"]
  public_subnets  = ["${cidrsubnet("${var.vpc_cidr_block}", 4, 3)}","${cidrsubnet("${var.vpc_cidr_block}", 4, 4)}"]

  enable_dns_hostnames = true
  enable_nat_gateway   = true

  tags = {
    Environment = "${terraform.workspace}"
  }
}

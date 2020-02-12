module "env_security_group"  {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "${terraform.workspace}-sg"

  description = "Security group for the environment"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

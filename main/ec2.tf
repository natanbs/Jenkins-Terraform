
# Create key-pair

module "keypair" {
  source = "mitchellh/dynamic-keys/aws"
  name   = "key-${terraform.workspace}"
  path   = "${path.root}/../keys"
}

output "private_key_pem" {
  value = "${module.keypair.private_key_pem}"
}

module "server1_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count              = "${var.instance_count}"
  key_name                    = "${module.keypair.key_name}"
  name                        = "server1-${terraform.workspace}"
  ami                         = "${var.server1_ami_id}"
  instance_type               = "${var.server1_instance_type}"
  subnet_id                   = tolist(module.vpc.private_subnets)[0]
  vpc_security_group_ids      = [module.env_security_group.this_security_group_id]
  associate_public_ip_address = false
}

module "server2_ec2" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 2.0"
  instance_count              = "${var.instance_count}"
  key_name                    = "${module.keypair.key_name}"
  name                        = "server2-${terraform.workspace}"
  ami                         = "${var.server2_ami_id}"
  instance_type               = "${var.server2_instance_type}"
  subnet_id                   = tolist(module.vpc.private_subnets)[0]
  vpc_security_group_ids      = [module.env_security_group.this_security_group_id]
  associate_public_ip_address = false
}

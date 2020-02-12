profile                 = "tikal"
vendor_name             = "tikal"
region                  = "eu-central-1"
bucket                  = "tikal-terraform-state"
primary_domain          = "tikal.io"
dynamodb_table          = "TikalTerraformStatelock"
env                     = "tf-customer1"
instance_count          = 1
key_name                = "client-key"
server1_instance_type   = "t2.micro"
server1_ami_id          = "ami-0cc0a36f626a4fdf5"
server2_instance_type   = "t2.micro"
server2_ami_id          = "ami-0cc0a36f626a4fdf5"
cluster_version         = "1.14"
vpc_cidr_block          = "10.0.58.0/23"
profiling_vpc_id        = "vpc-076d4aa84edf987e1"
profiling_vpc_cdir      = "10.16.0.0/16"
operators = [
  "natanb",
]
WORKSPACE                  = "."
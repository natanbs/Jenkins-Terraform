variable "env" {
  default = "dev"
}

variable "region" {
  description = "The AWS region to use"
}

variable "vendor_name" {
  description = "Usually the org/company name"
  default     = "Tikal"
}

variable "profile" {
  description = "The AWS profile to use"
}
variable "instance_count" {
  description = "Number of instance"
}
variable "bucket" {
  description = "Terraform state s3 bucket"
}

variable "dynamodb_table" {
  description = "Terraform statelock DynamoDB table"
}

variable "operators" {
  # type        = "list"
  description = "List of IAM users to grant access to state"
}

variable "primary_domain" {
  description = "Domain name to use"
}

variable "vpc_cidr_block" {
  # type = "string"
}

variable "cluster_version" {}

variable "server1_instance_type" {}
variable "server2_instance_type" {}
variable "server1_ami_id" {}
variable "server2_ami_id" {}
variable "profiling_vpc_id" {}
variable "profiling_vpc_cdir" {}
variable "key_name" {}
variable "WORKSPACE" {}

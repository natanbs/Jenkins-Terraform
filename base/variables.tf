variable "env" {
 
}

variable "region" {
  description = "The AWS region to use"
}

variable "vendor_name" {
  description = "Usually the org/company name"
  
}

variable "profile" {
  description = "The AWS profile to use"
}

variable "bucket" {
  description = "Terraform state s3 bucket"
}

variable "dynamodb_table" {
  description = "Terraform statelock DynamoDB table"
}

variable "operators" {
  type        = "list"
  description = "List of IAM users to grant access to state"
}

variable "primary_domain" {
  description = "Domain name to use"
}

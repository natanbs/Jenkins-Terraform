terraform {
  backend "s3" {
    bucket         = "tikal-terraform-state"
    region         = "eu-central-1"
    dynamodb_table = "TikalTerraformStatelock"
    key            = "main/terraform-tikal.tfstate"
  }
}

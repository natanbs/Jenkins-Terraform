provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

module "backend" {
  source = "../modules/backend"

  bootstrap      = 1
  operators      = "${var.operators}"
  bucket         = "${var.bucket}"
  dynamodb_table = "${var.dynamodb_table}"
  region         = "${var.region}"
}


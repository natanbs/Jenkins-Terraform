variable "bootstrap" {
  description = "Whether bootstrap basic infra or not"
  default     = 0
}

variable "operators" {
  type = "list"
}

variable "bucket" {}
variable "dynamodb_table" {}
variable "region" {}

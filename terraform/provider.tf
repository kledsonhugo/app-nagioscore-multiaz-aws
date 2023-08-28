# PROVIDER

variable "bucket" {
  type    = string
  default = "app-nagios-core-multiaz-v1"
}

variable "dynamodb_table" {
  type    = string
  default = "app-nagios-core-multiaz-v1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

terraform {

  required_version = "~> 1.5.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.13"
    }
  }

  backend "s3" {
    bucket         = "${var.bucket}"
    key            = "terraform.tfstate"
    dynamodb_table = "${var.dynamodb_table}"
    region         = "${var.region}"
  }

}

# provider "aws" {
#   region                   = "us-east-1"
#   shared_config_files      = ["./.aws/config"]
#   shared_credentials_files = ["./.aws/credentials"]
#   profile                  = "fiap"
# }
# PROVIDER
terraform {

  required_version = "~> 1.8.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  # backend "s3" {
  #   bucket         = "app-nagios-core-multiaz-v1-puc"
  #   key            = "terraform.tfstate"
  #   dynamodb_table = "app-nagios-core-multiaz-v1-puc"
  # }

}

provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["./.aws/config"]
  shared_credentials_files = ["./.aws/credentials"]
  profile                  = "fiap-iac"
}
# PROVIDER
terraform {

  required_version = "~> 1.5.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.13"
    }
  }

  backend "s3" {
    bucket         = "app-nagios-core-multiaz-v1-puc"
    key            = "terraform.tfstate"
    dynamodb_table = "app-nagios-core-multiaz-v1-puc"
  }

}
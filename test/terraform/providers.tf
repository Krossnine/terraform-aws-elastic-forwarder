provider "aws" {
  region                      = "eu-west-1"
  access_key                  = "null"
  secret_key                  = "null"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    logs           = "http://127.0.0.1:4566"
    sts            = "http://127.0.0.1:4566"
    lambda         = "http://127.0.0.1:4566"
    cloudwatch     = "http://127.0.0.1:4566"
    cloudwatchlogs = "http://127.0.0.1:4566"
    iam            = "http://127.0.0.1:4566"
  }
}

terraform {
  required_version = ">= 0.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.0"
    }
  }
}

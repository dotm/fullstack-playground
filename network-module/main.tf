#Put terraform settings and providers' configurations here

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
  }

  required_version = ">= 1.2.3"
}

provider "aws" {
  region     = var.aws_deployment_region
  access_key = var.aws_deployment_access_key_id
  secret_key = var.aws_deployment_secret_access_key

  allowed_account_ids = [var.aws_deployment_account_id]

  default_tags {
    tags = {
      deployment_environment_name    = "local"
      deployment_environment_purpose = "Rapid local experimentation for individual developer"
      project_name                   = "fullstack-playground"
      module_name                    = "network"
    }
  }
}

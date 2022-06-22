#Put terraform settings and providers' configurations here

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.1"
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
      deployment_environment_name    = var.deployment_environment_name
      deployment_environment_purpose = var.deployment_environment_purpose
      project_name                   = var.project_name
      module_name                    = var.module_name
    }
  }
}

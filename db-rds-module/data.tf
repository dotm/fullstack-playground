data "aws_vpcs" "list" {
  tags = {
    deployment_environment_name = var.deployment_environment_name
    project_name                = var.project_name
  }
}

data "aws_subnets" "list_public" {
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }

  tags = {
    deployment_environment_name = var.deployment_environment_name
    project_name                = var.project_name
  }
}

data "aws_subnets" "list_private" {
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }

  tags = {
    deployment_environment_name = var.deployment_environment_name
    project_name                = var.project_name
  }
}

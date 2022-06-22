locals {
  ecr_deploy_agent_user_name = "${var.stage}-${var.project_code}-ecr-deploy-agent"
  ecr_repositories = {
    "annotation_consumer"  = { name = "${var.project_code}/annotation-consumer" },
    "process_clip_service" = { name = "${var.project_code}/process-clip-service" },
    "partition_generator"  = { name = "${var.project_code}/partition-generator" },
  }
}

###############
# ECR IAM User
###############

# Create user
resource "aws_iam_user" "ecr_deploy_agent" {
  name = local.ecr_deploy_agent_user_name

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

# Attach managed policy
resource "aws_iam_user_policy_attachment" "ecr_deploy_agent_attached_ecr_policy" {
  user       = aws_iam_user.ecr_deploy_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

###############
# ECR Repositories
###############

resource "aws_ecr_repository" "backend" {
  for_each = local.ecr_repositories
  name     = each.value.name
}

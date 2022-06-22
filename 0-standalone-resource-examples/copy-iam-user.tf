###############
# IAM user for EC2
###############

resource "aws_iam_user" "process_clip_service" {
  name = "${local.process_clip_service_long_name}-iam-user"

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

resource "aws_iam_access_key" "process_clip_service" {
  user = aws_iam_user.process_clip_service.name
}

# Attach managed policy
resource "aws_iam_user_policy_attachment" "process_clip_service_attach_kvs_read_only_policy" {
  user       = aws_iam_user.process_clip_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisVideoStreamsReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "process_clip_service_attach_cloudwatch_agent_server_policy" {
  user       = aws_iam_user.process_clip_service.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach inline policy
resource "aws_iam_user_policy" "process_clip_service_s3_full_access_policy" {
  user = aws_iam_user.process_clip_service.name
  name = local.process_clip_service_s3_full_access_policy

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
          "${local.process_clip_service_s3_bucket.arn}",
          "${local.process_clip_service_s3_bucket.arn}/*"
        ]
      }
    ]
  }
  EOF
}
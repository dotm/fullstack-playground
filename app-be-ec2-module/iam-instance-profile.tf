#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_iam_instance_profile" "test" {
  name = "test_instance_profile"
  role = aws_iam_role.ec2_test.name
}

# Create role
resource "aws_iam_role" "ec2_test" {
  name = "test_instance_role_for_ec2"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# Attach managed policy
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_server_policy_to_test" {
  role       = aws_iam_role.ec2_test.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach inline policy
resource "aws_iam_role_policy" "process_clip_service_s3_full_access_policy" {
  role = aws_iam_role.ec2_test.id
  name = "sample_inline_policy"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
      }
    ]
  }
  EOF
}
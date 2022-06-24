resource "aws_iam_role_policy" "inline_ssm_policy" {
  role = aws_iam_role.example.name
  name = "inline_ssm_policy"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/path/to/parameter"
      }
    ]
  }
  EOF
}

resource "aws_ssm_parameter" "example" {
  name        = "/path/to/parameter" #if the name is not a path, the / prefix is not necessary.
  description = ""
  type        = "String" #String, StringList and SecureString.
  value       = ""

  # lifecycle {
  #   ignore_changes = [
  #     # Ignore changes to value to allow management from console
  #     value,
  #   ]
  # }

  # tier            = "Standard" #Standard, Advanced, and Intelligent-Tiering
  # key_id          = ""         #optional KMS key id or arn for encrypting a SecureString
  # overwrite       = false      #Overwrite an existing parameter. Default to false
  # allowed_pattern = ""         #regex used to validate the parameter value
  # data_type       = "text"     #text and aws:ec2:image (for AMI format)

  tags = {}
}

data "aws_ssm_parameter" "example" {
  name = "/path/to/parameter" #if the name is not a path, the / prefix is not necessary.

  with_decryption = true #Default value is true

  #exported attributes: arn, name, type, value, version
}

data "aws_ssm_parameters_by_path" "example" {
  path            = "/path/to"
  with_decryption = true  #Defaults to true.
  recursive       = false #Whether to recursively return parameters under path. Defaults to false.

  #exported attributes: arns, names, types, values
}
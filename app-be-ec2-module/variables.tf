variable "aws_deployment_access_key_id" {
  type = string
}

variable "aws_deployment_secret_access_key" {
  type = string
}

variable "aws_deployment_account_id" {
  type = string
}

variable "aws_deployment_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "deployment_environment_name" {
  type = string
}

variable "deployment_environment_purpose" {
  type = string
}

variable "project_name" {
  type = string
}

variable "module_name" {
  type    = string
  default = "app-be-ec2"
}

variable "ami_image_id" {
  type = map(any)
  default = {
    "ap-southeast-1" = "ami-0c802847a7dd848c0"
  }
}

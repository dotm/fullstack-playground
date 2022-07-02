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

variable "aws_deployment_region_short" {
  #short/abbreviated version of project_name.
  #useful for naming resources.
  type    = string
  default = "apse1"
}

variable "deployment_environment_name" {
  type = string
}

variable "deployment_environment_purpose" {
  type = string
}

variable "project_name" {
  type    = string
  default = "fullstack-playground"
}

variable "project_name_short" {
  #short/abbreviated version of project_name.
  #useful for naming resources.
  type    = string
  default = "fspg"
}

variable "module_name" {
  type    = string
  default = "db-s3"
}

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

variable "aws_deployment_availability_zones" {
  type = map(any)
  default = {
    "a" = {
      index = 0,
      name  = "ap-southeast-1a",
    },
    "b" = {
      index = 1,
      name  = "ap-southeast-1b",
    },
    "c" = {
      index = 2,
      name  = "ap-southeast-1c",
    },
  }

  #most regions has 3 AZs
  #some regions has more than 3
  #new regions may have less than 3
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
  type = string
  default = "network"
}

variable "vpc_cidr" {
  type = string

  #private ip addresses:
  # 10.0.0.0/8 (255.0.0.0) -> 10.0.0.0 - 10.255.255.255
  # 172.16.0.0/12 (255.240.0.0) -> 172.16.0.0 - 172.31.255.255
  # 192.168.0.0/16 (255.255.0.0) -> 192.168.0.0 - 192.168.255.255

  #good value is 10.1.0.0/16 (10.1.0.0 - 10.1.255.255)
  # allowing multiple vpcs (256 to be exact) to exist in the same region with the same 10 prefix
  #max value is 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
  #default aws vpc value is somewhere inside 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
}

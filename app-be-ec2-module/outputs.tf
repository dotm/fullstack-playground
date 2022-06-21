output "vpc_ids" {
  value = data.aws_vpcs.list.ids
}

output "vpc_restricted_sg_ids" {
  value = data.aws_security_groups.main_vpc_restricted_sg.ids
}

output "public_subnet_ids" {
  value = data.aws_subnets.list_public.ids
}

output "private_subnet_ids" {
  value = data.aws_subnets.list_private.ids
}

output "ec2_public_ips" {
  value = flatten([
    aws_instance.test[*].public_ip,
  ])
}
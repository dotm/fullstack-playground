#Put resources here.
#If this files become to long, you can move related resources to their own files.

#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
  give_ec2_instance_in_private_subnet_internet_connection = false

  #Used for cidr block calculation for all subnet.
  #Example:
  # if we have less than 8 subnets in this vpc, we'll use 3 newbits: 2^3 <= 8
  total_subnets      = length(var.aws_deployment_availability_zones) * 2 #We use * 2 because we have both public and private subnet
  newbits            = ceil(log(local.total_subnets, 2))                 #We use base 2 for log because bit is base 2
  max_subnets        = pow(2, local.newbits)                             #We use base 2 for power because bit is base 2
  final_subnet_index = local.max_subnets - 1                             #Because cidrsubnet is zero-indexed
}

#Notes:
#Resting VPC Resources are mostly free except for
# NAT Gateway (and the EIP attached to it), IPAM (IP address manager), Interface VPC Endpoint (Gateway VPCE is free),
# and Network Analysis (Traffic Mirroring, Reachability Analyzer, Network Access Analyzer).
#Data transfer cost: https://aws.amazon.com/blogs/architecture/overview-of-data-transfer-costs-for-common-architectures/

################
# VPC Resources
################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true #instances with public IP addresses get corresponding public DNS hostnames
  enable_dns_support   = true #default value is true

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_vpc_igw"
  }
}

################
# Route Tables Resources
################

resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id

  #route = [] #use this to clear all routes (https://www.terraform.io/language/attr-as-blocks)

  #the default route mapping the VPC's CIDR block to "local" is created implicitly and cannot be specified
  # route {
  #   cidr_block = var.vpc_cidr
  #   #mapped to "local" target
  # }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main_public_route_table"
  }
}

resource "aws_route_table" "main_private" {
  vpc_id = aws_vpc.main.id

  #route = [] #use this to clear all routes

  #the default route mapping the VPC's CIDR block to "local" is created implicitly and cannot be specified
  # route {
  #   cidr_block = var.vpc_cidr
  #   #mapped to "local" target
  # }

  #NAT Gateway in multi-AZ for high availability
  dynamic "route" {
    for_each = aws_nat_gateway.main
    iterator = nat_gateway
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = nat_gateway.id
    }
  }

  #Egress only internet gateway is like NAT Gateway but for IPv6 traffic
  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
  # }

  tags = {
    Name = "main_private_route_table"
  }
}

resource "aws_route_table_association" "main_public_subnet" {
  for_each       = var.aws_deployment_availability_zones
  subnet_id      = aws_subnet.main_public[each.key].id
  route_table_id = aws_route_table.main_public.id
}

resource "aws_route_table_association" "main_private_subnet" {
  for_each       = var.aws_deployment_availability_zones
  subnet_id      = aws_subnet.main_private[each.key].id
  route_table_id = aws_route_table.main_private.id
}

################
# Subnets Resources
################

#Notes:
#Subnets and security groups associated with Lambda Functions can take up to 45 minutes to successfully delete
#The first 4 and the last ip addresses in a subnet cidr block range is reserved by AWS.

resource "aws_subnet" "main_public" {
  for_each          = var.aws_deployment_availability_zones
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.name
  cidr_block        = cidrsubnet(var.vpc_cidr, local.newbits, each.value.index)

  #instances launched into this subnet should be assigned a public IP address
  #should be true in public subnets
  map_public_ip_on_launch = true

  private_dns_hostname_type_on_launch = "ip-name" #Value in Default VPC's Subnets is ip-name

  assign_ipv6_address_on_creation = false #Assign to ENI. Default value is false
  #ipv6_cidr_block
  #ipv6_native

  tags = {
    Name = "main_public_subnet_${each.key}"
  }
}

resource "aws_subnet" "main_private" {
  for_each          = var.aws_deployment_availability_zones
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.name
  cidr_block        = cidrsubnet(var.vpc_cidr, local.newbits, local.final_subnet_index - each.value.index)

  #instances launched into this subnet should be assigned a public IP address
  #should be true in public subnets
  map_public_ip_on_launch = false

  private_dns_hostname_type_on_launch = "ip-name" #Value in Default VPC's Subnets is ip-name

  assign_ipv6_address_on_creation = false #Assign to ENI. Default value is false
  #ipv6_cidr_block
  #ipv6_native

  tags = {
    Name = "main_private_subnet_${each.key}"
  }
}

################
# Private Subnet Resources
################

#Create aws_nat_gateway only if you want your private subnets resources to have internet connection.
#Deploy in multi-AZ for availability.
#Note that NAT Gateway is NOT free.
resource "aws_nat_gateway" "main" {
  for_each = (local.give_ec2_instance_in_private_subnet_internet_connection ? var.aws_deployment_availability_zones : {})

  #required if connectivity_type is public
  allocation_id = aws_eip.main_nat_eip[each.key].id

  #It is necessary to create NAT gateway in public subnet
  # because through NAT gateway your instances in private subnets can access the internet.
  subnet_id = aws_subnet.main_public[each.key].id

  connectivity_type = "public" #default value is public
}

#EIP attached to NAT Gateway is NOT free.
resource "aws_eip" "main_nat_eip" {
  for_each = (local.give_ec2_instance_in_private_subnet_internet_connection ? var.aws_deployment_availability_zones : {})

  vpc = true #if eip is in a vpc

  #It's recommended to denote that the AWS EC2 Instance or Elastic IP depends on the Internet Gateway.
  depends_on = [aws_internet_gateway.main]
}
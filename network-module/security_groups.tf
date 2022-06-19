#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Notes:
#Subnets and security groups associated with Lambda Functions can take up to 45 minutes to successfully delete.

resource "aws_security_group" "main_vpc_allow_all_sg" {
  name        = "main_vpc_allow_all_sg"
  description = "Allow all traffic to and from the VPC"
  lifecycle {
    #Necessary if you use name, name_prefix, or description properties.
    create_before_destroy = true
    #Changing those properties will recreate the security group.
    #Existing ENIs that use this security group will need the new security group.
    #So we create the new security group so that those ENIs can be reattached to the new security group
    #and the old security group can be destroyed.
  }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Allow All"
  }

  #Certain AWS services (e.g. Elastic Map Reduce) may automatically add required rules to security groups used with the service,
  #and those rules may contain a cyclic dependency that prevent the security groups from being destroyed without removing the dependency first.
  #In that case, set revoke_rules_on_delete to true.
  revoke_rules_on_delete = false #Default value is false. 

  #### Ingress and Egress Rules ####

  #ingress = [] #use this to clear all ingress (https://www.terraform.io/language/attr-as-blocks)
  #egress = [] #use this to clear all egress (https://www.terraform.io/language/attr-as-blocks)

  #Valid protocol: tcp, udp, icmp, icmpv6
  # Use -1 as protocol with from_port and to_port set to 0 to specify all protocols

  #Specifying -1 or a protocol number other than the valid protocol above allows traffic on all ports regardless of any port range you specify
  # For tcp, udp, and icmp, you must specify a port range.
  # For icmpv6, if you omit the optional port range, traffic for all types and codes is allowed.

  #You can use prefix_list_ids as a source instead of cidr blocks as ingress or egress destination.
  #A prefix list is a set of IPv4 or IPv6 address ranges. E.g. CloudFront Global IP addresses, S3 or DynamoDB region IP addresses, your own (customer-managed) addresses.

  #You can use security_groups as a source instead of cidr blocks: list of security group names if using EC2-Classic or ids if using a VPC.
  # This is useful for connecting to a load balancer (ELB/ALB/NLB) using the load balancer's security group as a source.
  #The self property can be set to true/false to state explicity that this security group is also a source to a rule or not.

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all inbound traffic"
  }

  #Terraform remove the default egress rule so we need to specify it here
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }
}

resource "aws_security_group" "main_vpc_restricted_sg" {
  name        = "main_vpc_restricted_sg"
  description = "Allow some traffic to and from the VPC"
  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Restricted SG"
  }

  revoke_rules_on_delete = false

  ingress {
    from_port   = 8  #ICMP type number if protocol is icmp or icmpv6. 8 is Echo Request (NOT Echo Reply)
    to_port     = -1 #ICMP code if protocol is icmp or icmpv6
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ping IPv4 traffic through ICMP"
  }
  ingress {
    from_port        = 128 #ICMP type number if protocol is icmp or icmpv6. 8 is Echo Request (NOT Echo Reply)
    to_port          = 0   #ICMP code if protocol is icmp or icmpv6
    protocol         = "icmpv6"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow ping IPv6 traffic through ICMPv6"
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow SSH traffic"
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTP traffic"
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTPS traffic"
  }

  #Terraform remove the default egress rule so we need to specify it here
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }
}

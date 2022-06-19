#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_network_acl" "main_vpc_allow_all_nacl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = flatten([
    [for key, subnet in aws_subnet.main_public : subnet.id],
    [for key, subnet in aws_subnet.main_private : subnet.id],
  ])

  tags = {
    Name = "Allow All"
  }

  #### Ingress and Egress Rules ####

  #ingress = [] #use this to clear all ingress (https://www.terraform.io/language/attr-as-blocks)
  #egress = [] #use this to clear all egress (https://www.terraform.io/language/attr-as-blocks)

  #Rule with lower rule_no takes precedence.
  #Default fallback rule_no is "*" and is automatically specified as deny all traffic (you can't provision or modify it).

  #Valid action: allow, deny

  #Valid protocol: tcp, udp, icmp, icmpv6
  # Use -1 as protocol with from_port and to_port set to 0 to specify all protocols

  #Specifying -1 or a protocol number other than the valid protocol above allows traffic on all ports regardless of any port range you specify
  # For tcp, udp, and icmp, you must specify a port range.
  # For icmpv6, if you omit the optional port range, traffic for all types and codes is allowed.

  #You can specify icmp_type and icmp_code in the rules. https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml

  #We split this because we can't specify multiple sources (cidr_block and ipv6_cidr_block) in a rule.
  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no         = 101
    action          = "allow"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    ipv6_cidr_block = "::/0"
  }

  #Terraform remove the default egress rule so we need to specify it with the rule below
  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no         = 101
    action          = "allow"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    ipv6_cidr_block = "::/0"
  }
}

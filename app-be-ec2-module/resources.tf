#Put resources here.
#If this files become to long, you can move related resources to their own files.

#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
}

resource "aws_key_pair" "default" {
  key_name   = "default_keypair"
  public_key = file("${path.module}/default_keypair.pub")
}

# resource "aws_network_interface" "test" {
#   subnet_id       = data.aws_subnets.list_public.ids[0] #The only required argument
#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 0
#   }
# }

resource "aws_launch_template" "default_free_tier" {
  name = "test_launch_template"

  image_id      = var.ami_image_id[var.aws_deployment_region]
  instance_type = "t2.micro"

  credit_specification {
    cpu_credits = "standard" #use "unlimited" to get billed for extra cpu usage
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.test.name
  }
  key_name = aws_key_pair.default.key_name

  disable_api_termination = false
  hibernation_options {
    configured = false
  }
  instance_initiated_shutdown_behavior = "stop" #or "terminate"
  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      data.aws_security_groups.main_vpc_restricted_sg.ids[0],
    ]
    # ipv6_address_count = 0
    # ipv6_addresses = []
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
    # capacity_reservation_target {}
  }

  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  ebs_optimized = false
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = false
      # iops= 100
      # kms_key_id = ""
      # throughput= 0
      volume_size = 8     #GB
      volume_type = "gp2" #Default value is gp2
    }
  }

  #instance_market_options {} #use this for spot instance

  # placement { #placement group settings
  #   availability_zone = ""
  #   host_id = null #Dedicated host id
  #   tenancy = "default"
  # }

  # ram_disk_id = "test"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test_instance"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/sh
    echo Hello >> ~/index.html
    cd ~
    pushd ~; sudo python -m SimpleHTTPServer 80; popd
    EOF
  )
}

resource "aws_instance" "test" {
  count = 0 #set to 0 to terminate all instance

  subnet_id = data.aws_subnets.list_public.ids[0]
  launch_template {
    name    = aws_launch_template.default_free_tier.name
    version = "$Latest"
  }

  get_password_data = false
  # cpu_core_count       = 1
  # cpu_threads_per_core = 1
  volume_tags                 = {}
  secondary_private_ips       = []
  source_dest_check           = true
  user_data_replace_on_change = true #trigger a destroy and recreate. Default value is false.
}

resource "aws_instance" "test" {
  subnet_id     = "subnet-c4f309a2"
  ami           = "ami-0c802847a7dd848c0"
  instance_type = "t2.micro"

  tags = {
    Name = "test_instance"
  }
  
  # launch_template {}

  iam_instance_profile   = ""
  key_name               = "default"
  vpc_security_group_ids = ["sg-080f0d79"]

  disable_api_termination              = false
  get_password_data                    = false
  hibernation                          = false
  instance_initiated_shutdown_behavior = "stop"
  monitoring                           = false

  associate_public_ip_address = true

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
    # capacity_reservation_target {}
  }

  # cpu_core_count       = 1
  # cpu_threads_per_core = 1
  credit_specification {
    cpu_credits = "standard"
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

  placement_group            = ""
  placement_partition_number = null

  # ebs_block_device {}
  ebs_optimized = false
  # ephemeral_block_device {}
  root_block_device {
    delete_on_termination = true
    # device_name= "/dev/xvda"
    encrypted = false
    # iops= 100
    # kms_key_id= ""
    # throughput= 0
    volume_size = 8
    volume_type = "gp2"
  }
  volume_tags = {}

  # network_interface {}
  # ipv6_address_count = 0
  # ipv6_addresses = []
  secondary_private_ips = []
  source_dest_check     = true

  # host_id = null #Dedicated host id
  tenancy               = "default"

  user_data                   = <<-EOF
  #!/bin/sh
  echo Hello >> ~/index.html
  cd ~
  pushd ~; sudo python -m SimpleHTTPServer 80; popd
  EOF
  user_data_replace_on_change = true #trigger a destroy and recreate. Default value is false.
}
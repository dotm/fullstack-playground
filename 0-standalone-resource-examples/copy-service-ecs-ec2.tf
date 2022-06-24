locals {
  process_clip_subnet_ids = [aws_subnet.public_subnet_2.id] #selected randomly between subnet 1-3

  #prepare should be
  # less than 5 minutes (ASG cooldown time) and more than 2 minutes (potential delay on ASG scheduled action)
  # BEFORE the cron is runned
  #finish should by less
  # less than 7 minutes (assumed process clip service minimal run time)
  # AFTER the cron is runned
  process_clip_service_prepare_schedule = "6 * * * *"          #run every hour at the 6th minute (use Unix cron style)
  process_clip_service_finish_schedule  = "14 * * * *"         #run every hour at the 11th minute (use Unix cron style)
  process_clip_service_run_schedule     = "cron(10 * * * ? *)" #run every hour at the 10th minute (use AWS cron style)

  process_clip_service_ec2_instance_type = "g4dn.xlarge"
  process_clip_service_ec2_user_data     = <<DOC
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.process_clip_service.name} >> /etc/ecs/ecs.config
    DOC
  process_clip_service_ec2_ami = {
    #use ami specified when creating new cluster from console
    "ap-northeast-1" = "ami-0f87d679e2fccd272",
  }
  process_clip_service_long_name                      = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-service"
  process_clip_service_ec2_security_group_name        = "${local.process_clip_service_long_name}-internal-only-docker-sg"
  process_clip_service_iam_ecs_role_name              = "${local.process_clip_service_long_name}-ecs-role"
  process_clip_service_iam_cloudwatch_event_role_name = "${local.process_clip_service_long_name}-cloudwatch-event-role"
  process_clip_service_s3_bucket                      = aws_s3_bucket.videos_bucket
  process_clip_service_s3_full_access_policy          = "${var.stage}-${var.project_code}${var.project_code_suffix}-s3-full-access-policy"
  process_clip_service_cron_policy                    = "${var.stage}-${var.project_code}${var.project_code_suffix}-cron-policy"
  process_clip_service_cluster_name                   = local.process_clip_service_long_name
  process_clip_service_pipeline_list = {
    "${var.use_case_pdf01_short}" = {
      long_name       = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_pdf01_short}",
      log_group_name  = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_pdf01_short}",
      kvs_stream_name = "${var.stage}-${var.project_code}${var.project_code_suffix}-${var.use_case_pdf01_short}-kvs",
    },
    "${var.use_case_pdf02_short}" = {
      long_name       = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_pdf02_short}",
      log_group_name  = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_pdf02_short}",
      kvs_stream_name = "${var.stage}-${var.project_code}${var.project_code_suffix}-${var.use_case_pdf02_short}-kvs",
    },
    "${var.use_case_fga01_short}" = {
      long_name       = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_fga01_short}",
      log_group_name  = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_fga01_short}",
      kvs_stream_name = "${var.stage}-${var.project_code}${var.project_code_suffix}-${var.use_case_fga01_short}-kvs",
    },
    "${var.use_case_fga02_short}" = {
      long_name       = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_fga02_short}",
      log_group_name  = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-${var.use_case_fga02_short}",
      kvs_stream_name = "${var.stage}-${var.project_code}${var.project_code_suffix}-${var.use_case_fga02_short}-kvs",
    },
  }
}

###############
# ECS IAM role
###############

# Create role
resource "aws_iam_role" "process_clip_service" {
  name = local.process_clip_service_iam_ecs_role_name

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# Attach managed policy
resource "aws_iam_role_policy_attachment" "process_clip_service_attach_ecs_policy" {
  role       = aws_iam_role.process_clip_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "process_clip_service_attach_kvs_read_only_policy" {
  role       = aws_iam_role.process_clip_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisVideoStreamsReadOnlyAccess"
}

# Attach inline policy
resource "aws_iam_role_policy" "iam_policy_process_clip_service" {
  name = local.process_clip_service_s3_full_access_policy
  role = aws_iam_role.process_clip_service.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
          "${local.process_clip_service_s3_bucket.arn}",
          "${local.process_clip_service_s3_bucket.arn}/*"
        ]
      }
    ]
  }
  EOF
}

##############
# ECS Cluster
##############
resource "aws_ecs_cluster" "process_clip_service" {
  name = local.process_clip_service_cluster_name

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

##############
# EC2 ASG for ECS Cluster
##############

resource "aws_security_group" "internal_only_docker" {
  name        = local.process_clip_service_ec2_security_group_name
  description = "Allow internal traffic to docker servers"
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "internal_only_docker"
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

resource "aws_launch_template" "process_clip_service" {
  name_prefix   = "process_clip_service"
  image_id      = local.process_clip_service_ec2_ami[var.aws_region]
  instance_type = local.process_clip_service_ec2_instance_type
  iam_instance_profile {
    name = "ecsInstanceRole" #this assumes that the role has been created previously with AmazonEC2ContainerServiceforEC2Role policy already attached
  }
  user_data = base64encode(local.process_clip_service_ec2_user_data)
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.internal_only_docker.id]
  }
}

resource "aws_autoscaling_group" "process_clip_service" {
  for_each            = local.process_clip_service_pipeline_list
  name                = each.value.long_name
  vpc_zone_identifier = local.process_clip_subnet_ids
  max_size            = 0 #kodok #in normal condition should be 2 instance max per pipeline. we use 3 here to add a buffer.
  min_size            = 0

  launch_template {
    id      = aws_launch_template.process_clip_service.id
    version = "$Latest"
  }
}

#uncomment below ~kodok
# resource "aws_autoscaling_schedule" "process_clip_prepare" {
#   for_each               = local.process_clip_service_pipeline_list
#   scheduled_action_name  = "${each.value.long_name}-prepare"
#   min_size               = 1  #scale out to prepare for process_clip_service_scheduled_task cron
#   max_size               = -1 #don't change
#   desired_capacity       = -1 #don't change
#   recurrence             = local.process_clip_service_prepare_schedule
#   autoscaling_group_name = aws_autoscaling_group.process_clip_service[each.key].name
# }

# resource "aws_autoscaling_schedule" "process_clip_min_0_finish_prepare" {
#   for_each               = local.process_clip_service_pipeline_list
#   scheduled_action_name  = "${each.value.long_name}-finish-prepare"
#   min_size               = 0  #reset to 0. this will trigger auto scale in if conditions are met
#   max_size               = -1 #don't change
#   desired_capacity       = -1 #don't change
#   recurrence             = local.process_clip_service_finish_schedule
#   autoscaling_group_name = aws_autoscaling_group.process_clip_service[each.key].name
# }

resource "aws_ecs_cluster_capacity_providers" "process_clip_service" {
  cluster_name       = aws_ecs_cluster.process_clip_service.name
  capacity_providers = [for k, v in aws_ecs_capacity_provider.process_clip_service : v.name]
}

resource "aws_ecs_capacity_provider" "process_clip_service" {
  for_each = local.process_clip_service_pipeline_list
  name     = each.value.long_name

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.process_clip_service[each.key].arn

    managed_scaling {
      maximum_scaling_step_size = 3
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

#####################
# ECS Task Definition
#####################
resource "aws_ecs_task_definition" "process_clip_tasks" {
  for_each                 = local.process_clip_service_pipeline_list
  family                   = "${each.value.long_name}-task"
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "${each.key}",
      "image": "${var.process_clip_image}",
      "essential": true,
      "environment": [
        {"name": "LOG_LEVEL", "value": "trace"},
        {"name": "NODE_ENV", "value": "${var.stage_long}"},
        {"name": "NO_COLOR", "value": "0"},
        {"name": "BATCH_PROCESS_CLIP_BUCKET_NAME", "value": "${local.process_clip_service_s3_bucket.id}"},
        {"name": "RAW_CLIP_S3_PREFIX", "value": "raw/"},
        {"name": "STITCHED_CLIP_S3_PREFIX", "value": "stitched/"},
        {"name": "STREAM_NAME", "value": "${each.value.kvs_stream_name}"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${each.value.log_group_name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${each.value.log_group_name}"
        }
      }
    }
  ]
  TASK_DEFINITION
  task_role_arn            = aws_iam_role.process_clip_service.arn
  execution_role_arn       = aws_iam_role.process_clip_service.arn
  requires_compatibilities = ["EC2"]
  memory                   = 4096

  network_mode = "host"
  #host network mode cannot run multiple copies of the same container/task on the same EC2 instance.
  #in this project this is fine, because only one task is running for each pipeline at any given time.
  #use awsvpc if you want to have multiple container per EC2 instance.
  #here we'll use host for simplicity and to minimize ENI creation.
  #see below for caveat on using awsvpc with EC2 (and not Fargate):
  #https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/networking-networkmode-awsvpc.html

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

##############
# ECS Service
##############
resource "aws_ecs_service" "process_clip_ecs_services" {
  for_each        = local.process_clip_service_pipeline_list
  name            = "${each.value.long_name}-ecs-service"
  cluster         = aws_ecs_cluster.process_clip_service.id
  task_definition = aws_ecs_task_definition.process_clip_tasks[each.key].arn
  desired_count   = 0
  capacity_provider_strategy {
    capacity_provider = each.value.long_name
    weight            = 1
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
}

#################
# CloudWatch Logs
#################
resource "aws_cloudwatch_log_group" "process_clip_logs" {
  for_each = local.process_clip_service_pipeline_list
  name     = each.value.log_group_name

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

#################
# CloudWatch Events for CRON
#################

resource "aws_iam_role" "process_clip_cron" {
  name = local.process_clip_service_iam_cloudwatch_event_role_name

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "process_clip_cron_inline_policy" {
  name = local.process_clip_service_cron_policy
  role = aws_iam_role.process_clip_cron.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "arn:aws:ecs:${var.aws_region}:${var.aws_account_id}:task-definition/${var.stage}-sej-process-clip-*"
        }
    ]
}
DOC
}

resource "aws_cloudwatch_event_rule" "process_clip_service" {
  for_each            = local.process_clip_service_pipeline_list
  name                = each.value.long_name
  schedule_expression = local.process_clip_service_run_schedule
  is_enabled          = false #kodok
}

resource "aws_cloudwatch_event_target" "process_clip_service_scheduled_task" {
  for_each  = local.process_clip_service_pipeline_list
  rule      = aws_cloudwatch_event_rule.process_clip_service[each.key].name
  target_id = each.value.long_name
  arn       = aws_ecs_cluster.process_clip_service.arn
  role_arn  = aws_iam_role.process_clip_cron.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.process_clip_tasks[each.key].arn

    tags = {
      PROJECT = var.tag_project_code
      STAGE   = var.tag_stage
      PURPOSE = var.tag_purpose
    }
  }
}
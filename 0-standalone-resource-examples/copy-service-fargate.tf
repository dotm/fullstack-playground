locals {
  process_clip_service_iam_ecs_role_name              = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-service-ecs-role"
  process_clip_service_iam_cloudwatch_event_role_name = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-service-cloudwatch-event-role"
  process_clip_service_s3_bucket                      = aws_s3_bucket.videos_bucket
  process_clip_service_s3_full_access_policy          = "${var.stage}-${var.project_code}${var.project_code_suffix}-s3-full-access-policy"
  process_clip_service_cron_policy                    = "${var.stage}-${var.project_code}${var.project_code_suffix}-cron-policy"
  process_clip_service_cluster_name                   = "${var.stage}-${var.project_code}${var.project_code_suffix}-process-clip-service"
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
  process_clip_service_run_schedule = "cron(10 * * * ? *)" #run every hour at the 10th minute
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
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 4096
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
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id]
    security_groups  = [aws_security_group.ecs_fargate_sg.id]
    assign_public_ip = true
  }
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
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "process_clip_service_scheduled_task" {
  for_each  = local.process_clip_service_pipeline_list
  rule      = aws_cloudwatch_event_rule.process_clip_service[each.key].name
  target_id = each.value.long_name
  arn       = aws_ecs_cluster.process_clip_service.arn
  role_arn  = aws_iam_role.process_clip_cron.arn

  ecs_target {
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.process_clip_tasks[each.key].arn
    network_configuration {
      assign_public_ip = true
      subnets = [
        aws_subnet.public_subnet_1.id,
        aws_subnet.public_subnet_2.id,
        aws_subnet.public_subnet_3.id,
      ]
    }

    tags = {
      PROJECT = var.tag_project_code
      STAGE   = var.tag_stage
      PURPOSE = var.tag_purpose
    }
  }
}
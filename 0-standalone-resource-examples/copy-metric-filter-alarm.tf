#################
# CloudWatch Logs
#################
resource "aws_sns_topic" "process_clip_service_error_notification" {
  name = local.process_clip_service_error_sns_topic_name

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

resource "aws_sns_topic_subscription" "process_clip_service_error_email_targets" {
  for_each  = toset(local.process_clip_service_error_email_subscriptions)
  topic_arn = aws_sns_topic.process_clip_service_error_notification.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_log_group" "process_clip_logs" {
  for_each = local.process_clip_service_pipeline_list
  name     = each.value.log_group_name

  tags = {
    PROJECT = var.tag_project_code
    STAGE   = var.tag_stage
    PURPOSE = var.tag_purpose
  }
}

resource "aws_cloudwatch_log_metric_filter" "process_clip_logs_error_metric_filter" {
  for_each       = local.process_clip_service_pipeline_list
  name           = "${each.value.log_group_name}-error-metric-filter"
  log_group_name = aws_cloudwatch_log_group.process_clip_logs[each.key].name
  pattern        = "?ERROR ?error"
  metric_transformation {
    name          = each.value.error_metric_name
    namespace     = local.process_clip_service_error_metrics_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count" #change to unit after creation might not take effect
  }
}

resource "aws_cloudwatch_metric_alarm" "process_clip_logs_error_alarm" {
  for_each    = local.process_clip_service_pipeline_list
  alarm_name  = "${each.value.log_group_name}-error-alarm"
  metric_name = each.value.error_metric_name
  namespace   = local.process_clip_service_error_metrics_namespace

  threshold           = "0"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  unit                = "Count" #change to unit after creation might not take effect

  datapoints_to_alarm = "1"  #change to ALARM state
  evaluation_periods  = "1"  #change alarm state every period
  period              = "60" #seconds
  treat_missing_data  = "notBreaching"

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.process_clip_service_error_notification.arn]
  # insufficient_data_actions = [] #list of arn
  # ok_actions                = [] #list of arn
}
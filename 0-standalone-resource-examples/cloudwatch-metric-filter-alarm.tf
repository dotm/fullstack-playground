locals {
  example_error_email_subscriptions = [
    "example@yopmail.com",
  ]
  example_error_metrics_namespace = "ErrorMetrics"
  example_error_metric_name       = "${aws_cloudwatch_log_group.example.name}-error-metric"
}

resource "aws_sns_topic" "example_error_notification" {
  name = "example_error_notification"

  tags = {}
}

resource "aws_sns_topic_subscription" "example_error_email_targets" {
  for_each  = toset(local.example_error_email_subscriptions)
  topic_arn = aws_sns_topic.example_error_notification.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_log_group" "example" {
  #AWS managed log group is prefixed with /aws/service-name
  name = "/user/service-name/example" #optional. you can also use name_prefix

  #Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0
  #If 0 (default value), the events in the log group are always retained and never expire.
  retention_in_days = 1

  kms_key_id = ""

  tags = {}
}

resource "aws_cloudwatch_log_metric_filter" "process_clip_logs_error_metric_filter" {
  name           = "${aws_cloudwatch_log_group.example.name}-error-metric-filter"
  log_group_name = aws_cloudwatch_log_group.example.name
  pattern        = "?ERROR ?error"
  metric_transformation {
    name          = local.example_error_metric_name
    namespace     = local.example_error_metrics_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count" #change to unit after creation might not take effect
  }
}

resource "aws_cloudwatch_metric_alarm" "process_clip_logs_error_alarm" {
  alarm_name  = "${aws_cloudwatch_log_group.example.name}-error-alarm"
  metric_name = local.example_error_metric_name
  namespace   = local.example_error_metrics_namespace

  threshold           = "0"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  unit                = "Count" #change to unit after creation might not take effect

  datapoints_to_alarm = "1"  #change to ALARM state
  evaluation_periods  = "1"  #change alarm state every period
  period              = "60" #seconds
  treat_missing_data  = "notBreaching"

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.example_error_notification.arn]
  # insufficient_data_actions = [] #list of arn
  # ok_actions                = [] #list of arn
}
resource "aws_cloudwatch_log_group" "example" {
  #AWS managed log group is prefixed with /aws/service-name
  name = "/user/service-name/example" #optional. you can also use name_prefix

  #Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0
  #If 0 (default value), the events in the log group are always retained and never expire.
  retention_in_days = 1

  kms_key_id = ""

  tags = {}
}
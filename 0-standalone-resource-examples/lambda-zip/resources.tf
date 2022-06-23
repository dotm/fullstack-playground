locals {
  zip_file_name         = "index"
  handler_function_name = "handler"
  source_file_path      = "${path.module}/${local.zip_file_name}.js"
  output_path           = "${path.module}/${local.zip_file_name}.zip"
}

data "archive_file" "lambda_zip_example" {
  type = "zip"

  source_file = local.source_file_path
  output_path = local.output_path
}

resource "aws_lambda_function" "lambda_zip_example" {
  function_name = "lambda_zip_example"
  role          = aws_iam_role.lambda_zip_example.arn
  description   = "Demonstrating how to deploy lambda using zip file" #optional

  architectures = ["x86_64"] #["x86_64"] and ["arm64"]. Default value is ["x86_64"]
  # code_signing_config_arn
  # dead_letter_config {
  #   target_arn = ""
  # }
  environment {
    variables = {
      deployment_environment_name    = var.deployment_environment_name
      deployment_environment_purpose = var.deployment_environment_purpose
      project_name                   = var.project_name
      module_name                    = var.module_name
    }
  }

  #increasing memory size of a lambda will also increase it's cpu
  memory_size = 128 #in MB. from 128 (default) up to 10240.

  # ephemeral_storage { #ephemeral storage (/tmp) to allocate for the Lambda Function
  #   size = 512 #in MB. min 512 MB, max 10240 MB
  # }
  # file_system_config {
  #   #Mount targets must be in available lifecycle state.
  #   #Use depends_on to explicitly declare this dependency. 
  #   arn              = aws_efs_access_point.access_point_for_lambda.arn
  #   local_mount_path = "/mnt/efs" # Local mount path inside the lambda function. Must start with '/mnt/'.
  # }

  #You can only use one of the deployment options below:
  package_type = "Zip" #Zip and Image. Defaults to Zip.
  #1. deploy zip from local file
  filename = data.archive_file.lambda_zip_example.output_path
  #2. deploy zip from S3
  # s3_bucket         = aws_s3_object.lambda_zip_example.bucket #must be in the same region with the Lambda function
  # s3_key            = aws_s3_object.lambda_zip_example.key
  # s3_object_version = aws_s3_object.lambda_zip_example.version_id
  #3. deploy zip using container image
  # image_uri = ""
  # image_config {
  #   #configuration values that override the values in the container image Dockerfile.
  #   command           = ["", ""] #Parameters that you want to pass in with entry_point.
  #   entry_point       = ["", ""] #Entry point to your application, which is typically the location of the runtime executable.
  #   working_directory = ""
  # }

  kms_key_arn = "" #used to encrypt environment variables with custom key (AWS Lambda uses a default service key)

  # layers = [aws_lambda_layer_version.example.arn] #max 5 layers

  handler = "${local.zip_file_name}.${local.handler_function_name}" #The function entrypoint in your code
  #for compiled files (e.g. Go build output), use the name of the compiled file for handler

  runtime = "nodejs16.x" #see valid values at https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  timeout = 3            #in seconds. Amount of time your Lambda Function has to run. Defaults to 3
  publish = true         #publish creation/change as new Lambda Function Version. Default to false

  #Amount of reserved concurrent executions for this lambda function.
  # 0 disables lambda from being triggered 
  # -1 (default) removes any concurrency limitations
  reserved_concurrent_executions = -1

  source_code_hash = data.archive_file.lambda_zip_example.output_base64sha256 #Used to trigger updates. Use filebase64sha256 if necessary.

  # tracing_config {
  #   #Whether to to sample and trace a subset of incoming requests with AWS X-Ray.
  #   mode = "Active"
  #   #PassThrough and Active.
  #   # If PassThrough, Lambda will only trace the request from an upstream service if it contains a tracing header with "sampled=1".
  #   # If Active, Lambda will respect any tracing header it receives from an upstream service.
  #   # If no tracing header is received, Lambda will call X-Ray for a tracing decision.
  # }

  # vpc_config {
  #   #For network connectivity to AWS resources in a VPC (Lambda in VPC)
  #   subnet_ids         = [aws_subnet.subnet_for_lambda.id]
  #   security_group_ids = [aws_security_group.sg_for_lambda.id]
  # }

  tags = {}
}

resource "aws_cloudwatch_log_group" "lambda_zip_example" {
  name = "/aws/lambda/${aws_lambda_function.lambda_zip_example.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_zip_example" {
  name = "lambda_zip_example"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_zip_example.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
#Other AWS managed roles:
# AWSLambdaBasicExecutionRole
# AWSLambdaDynamoDBExecutionRole
# AWSLambdaKinesisExecutionRole
# AWSLambdaMSKExecutionRole
# AWSLambdaSQSQueueExecutionRole
# AWSLambdaVPCAccessExecutionRole
# AWSXRayDaemonWriteAccess
# CloudWatchLambdaInsightsExecutionRolePolicy
# AmazonS3ObjectLambdaExecutionRolePolicy
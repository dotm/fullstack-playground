#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Note:
# stage is a named reference to a deployment.
# stages can be optionally managed further with:
# - aws_api_gateway_base_path_mapping
#     Connects a custom domain name registered via aws_api_gateway_domain_name
#     with a deployed API so that its methods can be called via the custom domain name.
# - aws_api_gateway_domain_name
#     Registers a custom domain name for use with AWS API Gateway.
# - aws_api_method_settings
#     Manages method settings: logging, metrics, tracing, throttling, caching, etc.

resource "aws_api_gateway_stage" "example_rest" {
  deployment_id = aws_api_gateway_deployment.example_rest.id
  rest_api_id   = aws_api_gateway_rest_api.example_rest.id
  stage_name    = var.deployment_environment_name
  description   = "Example REST API Gateway Stage"

  access_log_settings {
    destination_arn = "" #CloudWatch log group or Firehose delivery stream.
    #If you specify a Kinesis Data Firehose delivery stream, the stream name must begin with amazon-apigateway-.
    #Automatically removes trailing :* if present.

    #see https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
    format = ""
  }

  cache_cluster_enabled = false
  cache_cluster_size    = "0.5" #0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237.

  canary_settings {
    percent_traffic          = 0.0   #traffic to divert to the canary deployment. 0.0 - 100.0
    stage_variable_overrides = {}    #for the canary deployment.
    use_stage_cache          = false #canary deployment uses the stage cache. Defaults to false.
  }

  # client_certificate_id = aws_api_gateway_client_certificate.example_rest.id #Optional

  documentation_version = "" #The version of the associated API documentation

  #stage variables
  variables = {}

  xray_tracing_enabled = true

  tags = {}
}

# aws_api_gateway_client_certificate
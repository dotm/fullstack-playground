#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Note:
# deployment is a snapshot of the API configuration.
# stage is a named reference to a deployment.

resource "aws_apigatewayv2_api" "example_ws" {
  name          = "example_ws"
  description   = "An example implementation of WebSocket API"
  protocol_type = "WEBSOCKET"
  version       = "v1.0.0-alpha"

  route_selection_expression = "$request.body.action"

  #identify where the api key is located
  #valid values: $context.authorizer.usageIdentifierKey, $request.header.x-api-key (default)
  api_key_selection_expression = "$request.header.x-api-key"

  #Can the API by invoked using the {api_id}.execute-api.{region}.amazonaws.com endpoint
  #To require the use of a custom domain name, disable the default endpoint and configure an aws_apigatewayv2_domain_name
  disable_execute_api_endpoint = true #Default value is true

  tags = {}
}

#Creating a deployment for an API requires at least one aws_apigatewayv2_route resource associated with that API.
resource "aws_apigatewayv2_deployment" "example_ws" {
  api_id      = aws_apigatewayv2_api.example_ws.id
  description = "v1.0.0-alpha"

  #To avoid race conditions when all resources are being created together,
  #you need to add implicit resource references via the triggers argument or
  #explicit resource references using the resource depends_on meta-argument.
  triggers = {
    #Arbitrary map that will trigger a redeployment when changed.
    #To force a redeployment without changing these keys/values, use the terraform taint command.

    #List ALL routes and integrations here
    redeployment = sha1(join(",", list(
      jsonencode(aws_apigatewayv2_integration.example_ws),
      jsonencode(aws_apigatewayv2_route.example_ws),
    )))
  }

  #It is recommended to enable the resource lifecycle configuration block create_before_destroy argument
  #in this resource configuration to properly order redeployments in Terraform.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "example_ws" {
  api_id      = aws_apigatewayv2_api.example_ws.id
  name        = var.deployment_environment_name
  description = "Example WebSocket API Gateway Stage"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.example.arn
    #See custom variables for HTTP access log format here:
    #https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-logging-variables.html
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  # client_certificate_id = aws_api_gateway_client_certificate.example_ws.id #Optional

  #default route acts as a catch-all for requests that don’t match any other routes
  default_route_settings {
    detailed_metrics_enabled = false #Default value is false
    # throttling_burst_limit
    # throttling_rate_limit

    #ws only
    data_trace_enabled = false #Default value is false
    logging_level      = "OFF" #Valid values: ERROR, INFO, OFF (default)
  }
  route_settings {
    route_key                = ""
    detailed_metrics_enabled = false #Default value is false
    # throttling_burst_limit
    # throttling_rate_limit

    #ws only
    data_trace_enabled = false #Default value is false
    logging_level      = "OFF" #Valid values: ERROR, INFO, OFF (default)
  }

  #To deploy an API to make it callable by your users,
  #create an API deployment and associate it with a stage
  deployment_id = aws_apigatewayv2_deployment.example_ws.id

  stage_variables = {
    deployment_environment_name    = var.deployment_environment_name
    deployment_environment_purpose = var.deployment_environment_purpose
    project_name                   = var.project_name
    module_name                    = var.module_name
  }

  tags = {}
}

#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_apigatewayv2_api" "example_http" {
  name          = "example_http"
  description   = "An example implementation of HTTP API"
  protocol_type = "HTTP"
  version       = "v1.0.0-alpha"

  route_selection_expression = "$request.method $request.path" #Defaults to $request.method $request.path.

  #The body field is for OpenAPI specification that defines the routes and integrations to create as part of the HTTP APIs.
  #If provided, the aws_apigatewayv2_integration and aws_apigatewayv2_route should not be managed as separate ones
  #and the name, description, cors_configuration, tags and version fields should be specified
  # to override any values specified in the OpenAPI document.
  body = ""
  #Whether warnings should return an error while API Gateway is
  #creating or updating the resource using an OpenAPI specification
  fail_on_warnings = true #Default value is false.

  #Can the API by invoked using the {api_id}.execute-api.{region}.amazonaws.com endpoint
  #To require the use of a custom domain name, disable the default endpoint and configure an aws_apigatewayv2_domain_name
  disable_execute_api_endpoint = true #Default value is true

  #Below arguments are part of HTTP quick create integration
  #Quick create produces an API with
  # an integration, a default catch-all route,
  # and a default stage which is configured to automatically deploy changes.
  credentials_arn = "" #Specifies any credentials required
  route_key       = ""
  #As target for HTTP integrations (HTTP_PROXY), specify a fully qualified URL.
  #As target for Lambda integrations (AWS_PROXY), specify a function ARN.
  target = ""

  #cors_configuration will override CORS headers returned from your backend integration.
  cors_configuration {
    #server allows cookies (or other user credentials) to be included on cross-origin requests.
    allow_credentials = true

    #Use "*" for all. It's better to restrict origns to your frontend deployment domain and localhost.
    allow_origins = [
      "*", "http://*", "https://*", "https://www.example.com"
    ]
    allow_methods  = ["GET", "POST", "DELETE"]
    allow_headers  = ["Authorization"]
    expose_headers = []
    #allow_headers are request headers that the server will accept from browsers
    #expose_headers are response headers that the browser's Javascript can access

    max_age = 300 #in seconds. how long browsers should cache preflight request results.
  }

  tags = {}
}

resource "aws_apigatewayv2_stage" "example_http" {
  api_id      = aws_apigatewayv2_api.example_http.id
  name        = var.deployment_environment_name
  description = "Example HTTP API Gateway Stage"

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

  auto_deploy = false #updates to an API automatically trigger a new deployment. Default is false (for more control).

  #default route acts as a catch-all for requests that don’t match any other routes
  default_route_settings {
    detailed_metrics_enabled = false #Default value is false
    # throttling_burst_limit
    # throttling_rate_limit
  }
  route_settings {
    route_key                = ""
    detailed_metrics_enabled = false #Default value is false
    # throttling_burst_limit
    # throttling_rate_limit
  }

  #To deploy an API to make it callable by your users,
  #create an API deployment and associate it with a stage
  deployment_id = aws_apigatewayv2_deployment.example_http.id

  stage_variables = {
    deployment_environment_name    = var.deployment_environment_name
    deployment_environment_purpose = var.deployment_environment_purpose
    project_name                   = var.project_name
    module_name                    = var.module_name
  }

  tags = {}
}

#Creating a deployment for an API requires at least one aws_apigatewayv2_route resource associated with that API.
resource "aws_apigatewayv2_deployment" "example_http" {
  api_id      = aws_apigatewayv2_api.example_http.id
  description = "v1.0.0-alpha"

  #To avoid race conditions when all resources are being created together,
  #you need to add implicit resource references via the triggers argument or
  #explicit resource references using the resource depends_on meta-argument.
  triggers = {
    #Arbitrary map that will trigger a redeployment when changed.
    #To force a redeployment without changing these keys/values, use the terraform taint command.

    #List ALL routes and integrations here
    redeployment = sha1(join(",", list(
      jsonencode(aws_apigatewayv2_integration.example_http),
      jsonencode(aws_apigatewayv2_route.example_http),
    )))
  }

  #It is recommended to enable the resource lifecycle configuration block create_before_destroy argument
  #in this resource configuration to properly order redeployments in Terraform.
  lifecycle {
    create_before_destroy = true
  }
}

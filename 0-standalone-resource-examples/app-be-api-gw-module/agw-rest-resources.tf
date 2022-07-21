#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Note:
# deployment is a snapshot of the API configuration.
# stage is a named reference to a deployment.
# aws_api_gateway_resource and aws_api_gateway_method is in agw-rest-route.tf

resource "aws_api_gateway_rest_api" "example_rest" {
  name        = "example_rest"
  description = "An example implementation of REST API"

  #The body field is for OpenAPI specification that defines the routes and integrations to create as part of the REST APIs.
  #If provided, the following resources should not be managed as separate ones:
  # aws_api_gateway_resource, aws_api_gateway_model, aws_api_gateway_rest_api_policy,
  # aws_api_gateway_method, aws_api_gateway_method_response, aws_api_gateway_method_settings,
  # aws_api_gateway_integration, aws_api_gateway_integration_response, aws_api_gateway_gateway_response
  #Other arguments in this aws_api_gateway_rest_api will override values specified in the OpenAPI document.
  body = ""
  #Map of customizations for importing the specification in the body argument.
  parameters = {}

  #Can the API by invoked using the {api_id}.execute-api.{region}.amazonaws.com endpoint
  #To require the use of a custom domain name, disable the default endpoint and configure an aws_api_gateway_domain_name
  disable_execute_api_endpoint = true #Default value is true

  endpoint_configuration {
    types = "EDGE" #EDGE (default), REGIONAL or PRIVATE. Must be declared as REGIONAL in non-Commercial partitions

    # vpc_endpoint_ids = "" #For PRIVATE only
  }

  # binary_media_types = [""] #By default, the REST API supports only UTF-8-encoded text payloads

  minimum_compression_size = -1 #-1 disables compression (default). 0-10485760 (10MB) will enable response size compression

  # policy = "" #JSON policy. Using aws_api_gateway_rest_api_policy is recommended.

  api_key_source = "HEADER" #Source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER

  tags = {}
}

resource "aws_api_gateway_rest_api_policy" "example_rest" {
  rest_api_id = aws_api_gateway_rest_api.example_rest.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "*"
          },
          "Action": "execute-api:Invoke",
          "Resource": "${aws_api_gateway_rest_api.example_rest.execution_arn}"
        }
      ]
    }
    EOF
}

resource "aws_api_gateway_deployment" "example_rest" {
  rest_api_id = aws_api_gateway_rest_api.example_rest.id

  triggers = {
    #Use one of the triggers below depending on whether you use OpenAPI or Terraform resources to manage the REST API.
    # redeployment_for_openapi_spec = sha1(jsonencode(aws_api_gateway_rest_api.example.body))

    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment_for_terraform_managed_resources = sha1(jsonencode([
      aws_api_gateway_resource.example.id,
      aws_api_gateway_method.example.id,
      aws_api_gateway_integration.example.id,
    ]))
  }

  lifecycle {
    //this avoids error from orphaned stages of deleted deployments.
    create_before_destroy = true
  }
}

# aws_api_gateway_gateway_response
#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Note:
#Client -> Method Request -> API Gateway -> Integration Request -> Backend Service
#Client <- Method Response <- API Gateway <- Integration Response <- Backend Service

resource "aws_api_gateway_resource" "example_rest" {
  rest_api_id = aws_api_gateway_rest_api.example_rest.id
  parent_id   = aws_api_gateway_rest_api.example_rest.root_resource_id
  path_part   = "example_path" #last path segment of this API resource
}

resource "aws_api_gateway_method" "example_rest" {
  rest_api_id = aws_api_gateway_rest_api.example_rest.id
  resource_id = aws_api_gateway_resource.example_rest.id
  http_method = "GET" #GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY

  authorization = "NONE"                                     #NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS
  authorizer_id = aws_api_gateway_authorizer.example_rest.id #must be used for CUSTOM or COGNITO_USER_POOLS
  # authorization_scopes = "files.read_only" #used for COGNITO_USER_POOLS
  api_key_required = false

  #Name given to the method when generating an SDK through API Gateway.
  #If omitted, the name is based on the resource path and HTTP verb.
  # operation_name = ""

  #API models used for the request's content type.
  #key is the content type (e.g., application/json)
  #value is either Error, Empty (built-in models) or aws_api_gateway_model's name.
  # request_models = {} 

  # request_validator_id = aws_api_gateway_request_validator.example_rest.id

  #request parameters (from querystring, path, header, or body) that should be passed to the integration.
  #boolean value indicates whether the parameter is required (true) or optional (false).
  # request_parameters = {
  #   "method.request.header.X-Some-Header" = true,
  #   "method.request.querystring.some-query-param" = true,
  # } 
  #see https://docs.amazonaws.cn/en_us/apigateway/latest/developerguide/api-gateway-swagger-extensions-integration-requestParameters.html
}

# resource "aws_api_gateway_method_response" "example_rest" {}

# aws_api_gateway_model
# aws_api_gateway_request_validator

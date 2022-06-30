#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_apigatewayv2_route" "example_http" {
  api_id = aws_apigatewayv2_api.example_http.id

  #For HTTP can be a HTTP method + resource path or $default (for route that doesn't match other keys)
  #examples: GET /path/{path_parameter}, ANY /path/{proxy+}
  #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-routes.html
  route_key = "$default"

  authorization_scopes = [""]   #used with a JWT authorizer to authorize the method invocation.
  authorization_type   = "NONE" #valid values: NONE (open access), JWT, AWS_IAM (IAM permissions), and CUSTOM (Lambda authorizer). Defaults to NONE.
  authorizer_id        = aws_apigatewayv2_authorizer.example_http.id

  operation_name = "DefaultRoute" #example: "ListFiles" for the GET /files route key

  target = "integrations/${aws_apigatewayv2_integration.example_http.id}"
}

resource "aws_apigatewayv2_route_response" "example_http" {
  api_id             = aws_apigatewayv2_api.example_http.id
  route_id           = aws_apigatewayv2_route.example_http.id
  route_response_key = "$default"
}

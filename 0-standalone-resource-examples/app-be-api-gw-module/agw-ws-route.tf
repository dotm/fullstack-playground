#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_apigatewayv2_route" "example_ws" {
  api_id = aws_apigatewayv2_api.example_ws.id

  #the value that is expected once a route selection expression is evaluated.
  #predefined routes that can be used: $connect, $disconnect, $default
  #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api-develop-routes.html
  route_key = "$default"

  api_key_required = false #API key is required for the route. Defaults to false.

  authorization_scopes = [""]   #used with a JWT authorizer to authorize the method invocation.
  authorization_type   = "NONE" #valid values: NONE (open access), AWS_IAM (IAM permissions), CUSTOM (Lambda authorizer). Defaults to NONE.
  authorizer_id        = aws_apigatewayv2_authorizer.example_ws.id

  #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api-request-validation.html
  model_selection_expression = ""

  operation_name = "DefaultRoute" #example: "ConnectToSocket" for the $connect route key

  request_models = [aws_apigatewayv2_model.example_ws.id] #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/models-mappings.html#models-mappings-models
  request_parameter {
    request_parameter_key = "" #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api-data-mapping.html#websocket-mapping-request-parameters
    required              = true
  }

  #like aws_apigatewayv2_api.route_selection_expression but for the response
  route_response_selection_expression = ""

  target = "integrations/${aws_apigatewayv2_integration.example_ws.id}"
}

resource "aws_apigatewayv2_route_response" "example_ws" {
  api_id             = aws_apigatewayv2_api.example_ws.id
  route_id           = aws_apigatewayv2_route.example_ws.id
  route_response_key = "$default"

  #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api-request-validation.html
  model_selection_expression = ""

  #see: https://docs.aws.amazon.com/apigateway/latest/developerguide/models-mappings.html#models-mappings-models
  response_models = [aws_apigatewayv2_model.example_ws.id]
}

resource "aws_apigatewayv2_model" "example_ws" {
  api_id       = aws_apigatewayv2_api.example_ws.id
  content_type = "application/json"
  name         = "example"
  description  = "Example Model"

  #should be a JSON schema draft 4 model
  schema = <<-EOF
  {
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "ExampleModel",
    "type": "object",
    "properties": {
      "id": { "type": "string" }
    }
  }
  EOF
}
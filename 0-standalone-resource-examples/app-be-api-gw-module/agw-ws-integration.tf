#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_apigatewayv2_integration" "example_ws" {
  api_id = aws_apigatewayv2_api.example_ws.id

  credentials_arn = aws_iam_role.example.arn
  description     = "Example WebSocket integration"

  #Valid values for WebSocket APIs: AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK.
  #For private integration, use HTTP_PROXY.
  integration_type   = "AWS_PROXY"
  integration_method = "ANY" #integration's HTTP method (use ANY for any). Must be specified if integration_type is not MOCK.

  #For a Lambda proxy integration (AWS_PROXY): the URI of the Lambda function.
  #For an HTTP integration: a fully-qualified URL.
  #For an HTTP API private integration: the ARN of an ALB/NLB listener or AWS Cloud Map service.
  # integration_uri = ""

  connection_type = "INTERNET" #INTERNET or VPC_LINK. Default to INTERNET
  connection_id   = aws_apigatewayv2_vpc_link.example_ws.id

  content_handling_strategy = "CONVERT_TO_TEXT" #CONVERT_TO_BINARY or CONVERT_TO_TEXT

  #pass-through behavior for incoming requests based on the Content-Type header in the request,
  # and the available mapping templates specified as the request_templates attribute.
  #Valid values: WHEN_NO_MATCH (default), WHEN_NO_TEMPLATES, NEVER.
  passthrough_behavior = "WHEN_NO_MATCH"

  #The format of the payload sent to an integration.
  #https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html#http-api-develop-integrations-lambda.proxy-format
  #Valid values: 1.0 (default), 2.0.
  payload_format_version = "1.0"

  #For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend.
  request_parameters = {}

  #map of Velocity templates applied on the request payload
  # based on the value of the Content-Type header sent by the client
  #https://velocity.apache.org/
  request_templates = {}

  #template_selection_expression = ""

  timeout_milliseconds = 29000 #50 to 29000 (default) ms for ws
}

resource "aws_apigatewayv2_integration_response" "example_ws" {
  api_id                   = aws_apigatewayv2_api.example_ws.id
  integration_id           = aws_apigatewayv2_integration.example_ws.id
  integration_response_key = "/expression/" #can be $default or a regex expression with the format of /expression/

  content_handling_strategy = "CONVERT_TO_TEXT" #How to handle response payload content type conversions. Valid values: CONVERT_TO_BINARY, CONVERT_TO_TEXT.

  #map of Velocity templates applied on the request payload
  # based on the value of the Content-Type header sent by the client
  #https://velocity.apache.org/
  response_templates = {}

  #template_selection_expression = ""
}

resource "aws_apigatewayv2_vpc_link" "example_ws" {
  name               = "example_ws"
  security_group_ids = [aws_security_group.example_ws.id]
  subnet_ids         = aws_subnet_ids.example_ws.ids

  tags = {}
}
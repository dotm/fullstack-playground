#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

resource "aws_apigatewayv2_integration" "example_http" {
  api_id = aws_apigatewayv2_api.example_http.id

  credentials_arn = aws_iam_role.example.arn
  description     = "Example WebSocket integration"

  #Valid values for HTTP APIs: AWS_PROXY (used for lambda and other AWS services) and HTTP_PROXY (used for HTTP endpoints)
  #For private integration, use HTTP_PROXY.
  integration_type   = "AWS_PROXY"
  integration_method = "ANY" #integration's HTTP method (use ANY for any). Must be specified if integration_type is not MOCK.

  #Can be used for HTTP APIs with AWS_PROXY only.
  #Specifies the AWS service action to invoke. see: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services-reference.html
  # integration_subtype = ""

  #For a Lambda proxy integration (AWS_PROXY): the URI of the Lambda function.
  #For an HTTP integration: a fully-qualified URL.
  #For an HTTP API private integration: the ARN of an ALB/NLB listener or AWS Cloud Map service.
  # integration_uri = ""

  connection_type = "INTERNET" #INTERNET or VPC_LINK for private integration. Default to INTERNET
  tls_config {                 #for private integration
    #server_name_to_verify is optional.
    #Specify a server name to verify the hostname on the integration's certificate.
    #The server name is also included in the TLS handshake to support Server Name Indication (SNI) or virtual hosting.
    server_name_to_verify = "example.com"
  }
  connection_id = aws_apigatewayv2_vpc_link.example_http.id #Specify this for private integration

  #The JSON format of the payload of the integration request and response.
  #https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html#http-api-develop-integrations-lambda.proxy-format
  #Valid values: 1.0 (default), 2.0.
  payload_format_version = "2.0"

  #For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend.
  #For HTTP APIs with a specified integration_subtype, a key-value map specifying parameters that are passed to AWS_PROXY integrations.
  #For HTTP APIs without a specified integration_subtype, a key-value map specifying how to transform HTTP requests before sending them to the backend.
  #https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html
  request_parameters = {}

  #Mappings to transform the HTTP response from a backend integration before returning the response to clients.
  response_parameters {
    status_code = 403
    mappings = {
      "append:header.auth" = "$context.authorizer.authorizerResponse"
    }
  }
  response_parameters {
    status_code = 200 #200-599
    mappings = {
      #The key identifies the location of the request parameter to change, and how to change it.
      #The corresponding value specifies the new data for the parameter.
      #https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html
      "overwrite:statuscode" = "204"
    }
  }

  #template_selection_expression = ""

  timeout_milliseconds = 29000 #50 to 30000 (default) ms for http
}

resource "aws_apigatewayv2_integration_response" "example_http" {
  api_id                   = aws_apigatewayv2_api.example_http.id
  integration_id           = aws_apigatewayv2_integration.example_http.id
  integration_response_key = "/expression/" #can be $default or a regex expression with the format of /expression/

  content_handling_strategy = "CONVERT_TO_TEXT" #How to handle response payload content type conversions. Valid values: CONVERT_TO_BINARY, CONVERT_TO_TEXT.

  #map of Velocity templates applied on the request payload
  # based on the value of the Content-Type header sent by the client
  #https://velocity.apache.org/
  response_templates = {}

  #template_selection_expression = ""
}

resource "aws_apigatewayv2_vpc_link" "example_http" {
  name               = "example_http"
  security_group_ids = [aws_security_group.example_http.id]
  subnet_ids         = aws_subnet_ids.example_http.ids

  tags = {}
}
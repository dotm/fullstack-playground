#Local variables that is used in multiple files should be placed in ./locals.tf
#Put local variables that is only used in this file below
locals {
}

#Note:
#Client -> Method Request -> API Gateway -> Integration Request -> Backend Service
#Client <- Method Response <- API Gateway <- Integration Response <- Backend Service

resource "aws_api_gateway_integration" "example_rest" {
  rest_api_id = aws_api_gateway_rest_api.example_rest.id
  resource_id = aws_api_gateway_resource.example_rest.id
  http_method = aws_api_gateway_method.example_rest.http_method

  integration_http_method = "POST" #GET, POST, PUT, DELETE, HEAD, OPTIONs, ANY, PATCH
  #specify how API Gateway will interact with the back end.
  #Required if type is AWS, AWS_PROXY, HTTP or HTTP_PROXY.
  #Not all methods are compatible with all AWS integrations.
  #e.g. Lambda can only be invoked via POST.

  type = "AWS_PROXY"
  #Valid integration input's type values:
  # HTTP (for HTTP backends), MOCK (not calling any real backend),
  # AWS (for AWS services), AWS_PROXY (for Lambda proxy integration)
  # and HTTP_PROXY (for HTTP proxy integration).

  connection_type = "INTERNET"
  #Valid values are INTERNET (default for connections through the public routable internet),
  # and VPC_LINK (for private connections between API Gateway and a network load balancer in a VPC).
  #HTTP or HTTP_PROXY integration with a connection_type of VPC_LINK
  # is referred to as a private integration.
  connection_id = aws_api_gateway_vpc_link.test.id #Required if connection_type is VPC_LINK

  uri = aws_lambda_function.lambda.invoke_arn
  #Required if type is AWS, AWS_PROXY, HTTP or HTTP_PROXY.
  #For HTTP integrations, the URI must be
  # a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification.
  #For AWS integrations, the URI should be
  # of the form arn:aws:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}.
  # region, subdomain and service are used to determine the right endpoint.
  # e.g., arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-west-1:012345678901:function:my-func/invocations
  #For private integrations, the URI parameter is not used for routing requests to your endpoint,
  # but is used for setting the Host header and for certificate validation.

  credentials = ""
  #For AWS integrations, 2 options are available.
  # To specify an IAM Role for Amazon API Gateway to assume, use the role's ARN.
  # To require that the caller's identity be passed through from the request, specify the string arn:aws:iam::\*:user/\*.

  #A map of request query string parameters and headers that should be passed to the backend responder.
  request_parameters = { "integration.request.header.X-Some-Other-Header" = "method.request.header.X-Some-Header" }
  #map of Velocity templates applied on the request payload
  # based on the value of the Content-Type header sent by the client
  #https://velocity.apache.org/
  request_templates = {}

  #pass-through behavior for incoming requests based on the Content-Type header in the request,
  # and the available mapping templates specified as the request_templates attribute.
  #Required if request_templates is used.
  #Valid values: WHEN_NO_MATCH (default), WHEN_NO_TEMPLATES, NEVER.
  passthrough_behavior = "WHEN_NO_MATCH"

  cache_key_parameters = ["method.request.path.param"]
  cache_namespace      = "foobar"

  content_handling = ""
  #How to handle request payload content type conversions.
  #Valid values are CONVERT_TO_BINARY and CONVERT_TO_TEXT.
  #If this property is not defined, the request payload
  # will be passed through from the method request to integration request without modification,
  # provided that the passthroughBehaviors is configured to support payload pass-through.

  timeout_milliseconds = 29000 #50 to 29000 (default) ms for ws

  tls_config {
    insecure_skip_verification = false
    #whether or not API Gateway skips verification that the certificate for an integration endpoint
    # is issued by a supported certificate authority.
    #This isn’t recommended, but it enables you to use certificates
    # that are signed by private certificate authorities, or that are self-signed.
    #If enabled, API Gateway still performs basic certificate validation,
    # which includes checking the certificate's expiration date, hostname, and presence of a root certificate authority.
    #Supported only for HTTP and HTTP_PROXY integrations.
  }
}

# resource "aws_api_gateway_integration_response" "example_rest" {}

resource "aws_api_gateway_vpc_link" "example_rest" {
  name        = "example_rest_vpc_link"
  description = "example REST VPC Link"

  target_arns = [aws_lb.example.arn]
  #list of network load balancer arns in the VPC targeted by the VPC link.
  #Currently AWS only supports 1 target.

  tags = {}
}
data "aws_apigatewayv2_export" "test" {
  api_id = aws_apigatewayv2_route.test.api_id

  specification = "OAS30" #OAS30 (OpenAPI 3.0) is the only supported value.
  output_type   = "JSON"  #JSON or YAML

  # export_version = "1.0" #Used API Gateway export algorithm's version. Defaults to latest version.

  # include_extensions = true #include API Gateway extensions in the exported API definition. Defaults to included.

  #The name of the API stage to export.
  #If you don't specify this property, a representation of the latest API configuration is exported.
  # stage_name = ""

  #Attributes:
  # id - The API identifier.
  # body - The id of the API.
}
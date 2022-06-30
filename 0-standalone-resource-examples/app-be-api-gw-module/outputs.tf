output "vpc_ids" {
  value = data.aws_vpcs.list.ids
}

output "base_url_http" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.example_http.invoke_url
}

output "base_url_ws" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.example_ws.invoke_url
}

locals {
  user_pool_name = "${var.stage}-${var.project_code}-user-pool"
}

resource "aws_cognito_user_pool" "project_specific_user_pool" {
  name = local.user_pool_name
}

resource "aws_cognito_user_pool_client" "userpool_client" {
  name                                 = "client"
  user_pool_id                         = aws_cognito_user_pool.project_specific_user_pool.id
  callback_urls                        = ["https://example.com"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
}
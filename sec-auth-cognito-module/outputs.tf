output "vpc_ids" {
  value = data.aws_vpcs.list.ids

  #optional arguments
  description = "The list of VPCs created from network-module."
  # sensitive   = false
  # depends_on = [
  #   #When a parent module accesses an output value exported by one of its child modules,
  #   # the dependencies of that output value allow Terraform to correctly determine
  #   # the dependencies between resources defined in different modules.
  #   #Terraform analyzes the value expression for an output value
  #   # and automatically determines a set of dependencies,
  #   # but in less-common cases there are dependencies that cannot be recognized implicitly.
  #   #In these rare cases, the depends_on argument can be used to create additional explicit dependencies.
  # ]

  # precondition {
  #   condition     = length(data.aws_vpcs.list.ids) > 0
  #   error_message = "The network-module VPC is undetected."
  # }
}

locals {
  default_user_pool_response_type = "token" #code or token
  #Indicates whether the client wants
  # an authorization code for the user (authorization code grant flow),
  # or directly issues tokens for the user (implicit flow).

  default_user_pool_path = "https://${
    aws_cognito_user_pool_domain.default.domain
  }.auth.${var.aws_deployment_region}.amazoncognito.com/login"

  default_user_pool_query_params = "?client_id=${
    aws_cognito_user_pool_client.default_user_pool_client.id
    }&response_type=${
    local.default_user_pool_response_type
    }&scope=${
    join("+", aws_cognito_user_pool_client.default_user_pool_client.allowed_oauth_scopes)
    }&redirect_uri=${
    aws_cognito_user_pool_client.default_user_pool_client.default_redirect_uri
  }"
}
output "default_user_pool_url" {
  value = "${local.default_user_pool_path}${local.default_user_pool_query_params}"
}
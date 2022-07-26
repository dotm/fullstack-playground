#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
}

resource "aws_cognito_user_pool_domain" "default" {
  #no need to include region in domain (see outputs.tf).
  #can't include var.module_name in domain because cognito is a reserved word.
  domain = "${var.aws_deployment_account_id}-${var.deployment_environment_name}-${var.project_name_short}-default-domain"

  user_pool_id = aws_cognito_user_pool.default_user_pool.id

  # certificate_arn = aws_acm_certificate.cert.arn #ISSUED ACM certificate in us-east-1 for a custom domain.
  #see aws_cognito_user_pool_domain on Terraform docs
  #for example on how to create custom domain
  #by associating aws_route53_zone and aws_route53_record
  #with aws_cognito_user_pool_domain.default.domain
}

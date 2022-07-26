#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
  default_redirect_url = "https://dotm.github.io"
}

resource "aws_cognito_user_pool_client" "default_user_pool_client" {
  name         = "default_user_pool_client"
  user_pool_id = aws_cognito_user_pool.default_user_pool.id

  allowed_oauth_flows_user_pool_client = true
  #Whether the client is allowed to follow the OAuth protocol when interacting with Cognito user pools.

  allowed_oauth_flows = ["code", "implicit"] #code, implicit, client_credentials
  # Best practice:
  #   If the app is running on a backend server and doesn't have any end user
  #     (e.g. a server that regularly provision/maintain a resource),
  #     then use "client_credentials"
  #   If the app is running on a backend server and have an end user that highly trust the server
  #     (e.g. a private server that you're comfortable giving your social media password to),
  #     then use password flow (not builtin to Cognito).
  #   If the app is running on a backend server and have an end user that doesn't trust the server
  #     (e.g. you are only willing to give your basic social media info and not your password to)
  #     then use "code" (you're only giving the app authorization code to access your basic info)
  #   If the app is running in an old browser frontend that doesn't support Web Crypto
  #     then use "implicit" (the app will be given access token and not authorization code)
  #   If the app is running in a native mobile app or a browser frontend that supports Web Crypto
  #     then use "code" with PKCE (you must implement the PKCE yourself to defend against CSRF).
  #     see: https://advancedweb.hu/how-to-secure-the-cognito-login-flow-with-a-state-nonce-and-pkce/

  allowed_oauth_scopes = ["email", "openid"] #phone, email, openid, profile, aws.cognito.signin.user.admin
  #what information are allowed to be accessed by the auth client.

  callback_urls = [local.default_redirect_url] #allowed callback URLs for the identity providers.
  logout_urls   = [local.default_redirect_url] #logout URLs for the identity providers.
  #redirect/callback uri will be opened to receive the token/code from the authentication server
  # after the resource owner (the user) grants permission to the client (the app that needs the authorization)
  default_redirect_uri = local.default_redirect_url #must be in the list of callback URLs.

  enable_token_revocation = true

  enable_propagate_additional_user_context_data = false

  # explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  #Valid values:
  # ALLOW_ADMIN_USER_PASSWORD_AUTH,
  # ALLOW_USER_PASSWORD_AUTH, ALLOW_USER_SRP_AUTH (Secure Remote Password),
  # CUSTOM_AUTH_FLOW_ONLY, ALLOW_CUSTOM_AUTH (AWS Lambda trigger based authentication),
  # ALLOW_REFRESH_TOKEN_AUTH
  #for details see: ExplicitAuthFlows on API_CreateUserPoolClient docs

  generate_secret = false #Should an OAuth client secret be generated.
  #Client secrets should only be used by applications that have
  # a server-side authentication component so that it can secure the client secret.
  #For usual JavaScript frontend, set to false.


  prevent_user_existence_errors = "ENABLED"
  #Choose which errors and responses are returned when the user does not exist in the user pool.
  #If ENABLED, the error hides whether the username exists or not in the user pool
  # (it says either the username or password was incorrect, or an email was sent if the username exist),
  #If LEGACY, those APIs will return a UserNotFoundException.
  #Prefer to use ENABLED for security purpose (not letting an attacker check if a username exist).

  read_attributes  = [] #user pool attributes the application client can read from.
  write_attributes = [] #user pool attributes the application client can write to.

  supported_identity_providers = ["COGNITO"] #You can use Cognito, Google, Facebook, etc.
  #provider names for the identity providers that are supported on this client.
  #Uses the provider_name attribute of aws_cognito_identity_provider resource(s) or the equivalent string(s).

  token_validity_units {
    #Valid values for the following arguments are: seconds, minutes, hours or days.
    access_token  = "hours" #unit for the value in access_token_validity, defaults to hours.
    id_token      = "hours" #unit for the value in id_token_validity, defaults to hours.
    refresh_token = "hours" #unit for the value in refresh_token_validity, defaults to days.
  }
  access_token_validity  = 1 #between 5 minutes and 1 day
  id_token_validity      = 1 #between 5 minutes and 1 day
  refresh_token_validity = 24

  # analytics_configuration {
  #   #for Amazon Pinpoint analytics for collecting metrics for this user pool

  #   #Either application_arn or application_id is required.
  #   application_arn = aws_pinpoint_app.default.arn #Conflicts with external_id and role_arn.
  #   application_id  = aws_pinpoint_app.default.application_id
  #   external_id     = "" #ID for the Analytics Configuration. Conflicts with application_arn.
  #   role_arn        = "" #authorizes Amazon Cognito to publish events to Amazon Pinpoint analytics. Conflicts with application_arn.

  #   user_data_shared = true
  #   #whether Amazon Cognito will include user data in the events it publishes to Amazon Pinpoint analytics.
  # }
}
#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
}

resource "aws_cognito_user_pool" "default_user_pool" {
  name = "default_user_pool"

  account_recovery_setting {
    #define which verified available method a user can use to recover their forgotten password.
    #valid names: verified_email, verified_phone_number, admin_only.
    #priority 1 is highest priority.
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    # recovery_mechanism {
    #   name     = "verified_phone_number"
    #   priority = 2
    # }
  }

  admin_create_user_config {
    #whether only admin can create users (users can NOT sign themselves up via an app).
    allow_admin_create_user_only = false

    invite_message_template {
      email_subject = "You've been invited to register."
      email_message = "Your username is {username} and your temporary password is {####}."
      sms_message   = "Your username is {username} and your temporary password is {####}."
    }
  }

  #An alias attribute is a username attribute that can be changed after user creation.
  #A username attribute is always required to register a user
  # and it cannot be changed after a user is created
  #The username attribute must be unique within a user pool;
  # it can be re-used, but only after getting deleted

  alias_attributes = ["email"]
  #Valid values: phone_number, email, preferred_username.
  #Conflicts with username_attributes.

  # username_attributes = ["email", "preferred_username"]
  #Valid values: phone_number, email, preferred_username.
  #Conflicts with alias_attributes.

  auto_verified_attributes = ["email"]
  #automatically send verification link
  #Valid values: "email", "phone_number"

  username_configuration {
    case_sensitive = false
    #Whether username case sensitivity will be applied
    #for all users in the user pool through Cognito APIs.
  }

  # device_configuration { #user pool's device tracking
  #   device_only_remembered_on_user_prompt = false 
  #   #false means "Always" remember,
  #   #true is "User Opt In,"
  #   #and not using a device_configuration block is "No."

  #   challenge_required_on_new_device = true
  # }

  mfa_configuration = "OFF"
  #Valid values are
  # OFF (default; MFA Tokens are not required)
  # ON (MFA is required for all users to sign in)
  # OPTIONAL (MFA Will be required only for individual users who have MFA Enabled)
  #for ON and Optional, requires at least one of
  # sms_configuration or software_token_mfa_configuration to be configured.

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false

    temporary_password_validity_days = 7
    #If the user does not sign-in during this time,
    #their password will need to be reset by an administrator.
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
    #COGNITO_DEFAULT for the default email functionality built into Cognito
    #or DEVELOPER to use your Amazon SES configuration.
    #if you use COGNITO_DEFAULT, the attributes below should not exist (will conflict with default setting).

    # configuration_set = aws_ses_configuration_set.default_user_pool.arn #optional

    #SES verified email identity to to use.
    #Required if email_sending_account is set to DEVELOPER.
    # source_arn = aws_ses_email_identity.default_user_pool.arn 

    #Sender’s email address or display name with email address
    # e.g., john@example.com, John Smith <john@example.com> or \"John Smith Ph.D.\" <john@example.com>
    #Escaped double quotes are required around display names
    # that contain certain characters as specified in RFC 5322.
    # from_email_address = "no-reply@yopmail.com"

    # reply_to_email_address = "reply-here@yopmail.com"
  }
  email_verification_message = "Your confirmation code is {####}"
  #Conflicts with verification_message_template.email_message
  email_verification_subject = "Confirmation Code"
  #Conflicts with verification_message_template.email_subject

  #Lambda triggers associated with the user pool
  # lambda_config {
  #   custom_message        = "" #Custom Message AWS Lambda trigger.
  #   define_auth_challenge = "" #Defines the authentication challenge.
  #   create_auth_challenge = aws_lambda_function.default_user_pool_create_auth_challenge.arn
  #   #for creating an authentication challenge.

  #   post_authentication = aws_lambda_function.default_user_pool_post_authentication.arn
  #   post_confirmation   = aws_lambda_function.default_user_pool_post_confirmation.arn
  #   pre_authentication  = aws_lambda_function.default_user_pool_pre_authentication.arn
  #   pre_sign_up         = aws_lambda_function.default_user_pool_pre_sign_up.arn

  #   pre_token_generation = aws_lambda_function.default_user_pool_pre_token_generation.arn
  #   #Allow to customize identity token claims before token generation.

  #   user_migration = "" #User migration Lambda config type.

  #   verify_auth_challenge_response = aws_lambda_function.default_user_pool_verify_auth_challenge_response.arn
  #   #Verifies the authentication challenge response.

  #   kms_key_id = aws_kms_key.default_user_pool.arn
  #   #Amazon Cognito uses the key to encrypt codes and temporary passwords
  #   #sent to CustomEmailSender and CustomSMSSender.
  #   custom_email_sender {
  #     lambda_arn = aws_lambda_function.default_user_pool_custom_email_sender.arn
  #     #Lambda used to send email notifications to users.

  #     lambda_version = "V1_0"
  #     #represents the signature of the "request" attribute
  #     #in the "event" information Amazon Cognito passes to your custom email Lambda function.
  #     #The only supported value is V1_0.
  #   }

  #   custom_sms_sender {
  #     lambda_arn = aws_lambda_function.default_user_pool_custom_sms_sender.arn
  #     #Lambda used to send SMS notifications to users.

  #     lambda_version = "V1_0"
  #     #represents the signature of the "request" attribute
  #     #in the "event" information Amazon Cognito passes to your custom SMS Lambda function.
  #     #The only supported value is V1_0.
  #   }
  # }

  #schema attributes of a user pool (one schema block for each attribute)
  # schema {
  #   #Schema attributes from the standard attribute set only need to be specified
  #   #if they are different from the default configuration.
  #   #Attributes can be added, but not modified or removed.
  #   #Maximum of 50 attributes.

  #   name                = "full_name"
  #   attribute_data_type = "String" #Boolean, Number, String, DateTime.
  #   #If String or Number, the respective attribute constraints
  #   #(e.g string_attribute_constraints or number_attribute_constraints)
  #   #is required to prevent recreation of the Terraform resource.
  #   #This requirement is true for both standard (e.g., name, email) and custom schema attributes.
  #   number_attribute_constraints {
  #     max_value = 100
  #     min_value = 0
  #   }
  #   string_attribute_constraints {
  #     max_length = 100
  #     min_length = 1
  #   }

  #   developer_only_attribute = false
  #   #can only be modified by an administrator (users can't update)
  #   mutable  = true
  #   required = false
  #   #If user does not provide a value for required attribute, registration or sign-in will fail.
  # }

  # sms_authentication_message = "Your code is {####}"
  # sms_configuration {
  #   #These settings apply to SMS user verification and SMS Multi-Factor Authentication (MFA).
  #   #The SMS configuration cannot be removed without recreating the Cognito User Pool.
  #   #For user data safety, this resource will ignore
  #   # the removal of this configuration by disabling drift detection.
  #   #To force resource recreation after this configuration has been applied, use taint.

  #   # external_id = ""
  #   #used in IAM role trust relationships.
  #   #For more information about using external IDs, see https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html

  #   # sns_caller_arn = ""
  #   #This is usually the IAM role that you've given Cognito permission to assume.
  # }
  # sms_verification_message = "{####}"
  # #Conflicts with verification_message_template.sms_message

  # verification_message_template {
  #   default_email_option = "CONFIRM_WITH_CODE" #CONFIRM_WITH_CODE (default) or CONFIRM_WITH_LINK.

  #   email_message = "Your confirmation code is {####}" #Conflicts with email_verification_message argument.
  #   email_subject = "Confirmation Code"                #Conflicts with email_verification_subject argument.

  #   email_message_by_link = "Your confirmation link is {##Click Here##}"
  #   email_subject_by_link = "Confirmation Link"

  #   sms_message = "{####}" #Conflicts with sms_verification_message argument.
  # }

  # software_token_mfa_configuration {
  #   #Software token MFA tokens such as Time-based One-Time Password (TOTP).
  #   enabled = false

  #   #To disable software token MFA when sms_configuration is not present,
  #   #the mfa_configuration argument must be set to OFF
  #   #and the software_token_mfa_configuration configuration block must be fully removed.
  # }

  # user_pool_add_ons {
  #   advanced_security_mode = "OFF" #OFF, AUDIT or ENFORCED.
  # }

  tags = {}
}
#Put resources here.
#If this files become to long, you can move related resources to their own files.

#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
  deployment_environment_is_temporary = contains(["local"], var.deployment_environment_name)
}

resource "aws_s3_bucket" "example_public" {
  #bucket's name (max 63 characters)
  bucket = "${var.aws_deployment_account_id}-${var.aws_deployment_region_short}-${var.deployment_environment_name}-${var.project_name_short}-${var.module_name}-example-public"
  # bucket_prefix = "max-37-characters" #alternative of and conflicts with bucket

  force_destroy = local.deployment_environment_is_temporary

  object_lock_enabled = false #Default to false. Configure with aws_s3_bucket_object_lock_configuration if enabled

  tags = {}
}

#docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html
resource "aws_s3_bucket_acl" "example_public" {
  bucket = aws_s3_bucket.example_public.id

  #Valid canned ACL: https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl
  # acl = "public-read" #Commonly used values: private, public-read

  #Fine grained policy instead of canned ACL
  access_control_policy {
    grant {
      grantee {
        type = "Group" #type of grantee. Valid values: CanonicalUser, AmazonCustomerByEmail, Group

        #Specify grantee using one of the arguments below:
        # id            = "" #canonical user ID of the grantee.
        # email_address = ""
        uri = "http://acs.amazonaws.com/groups/global/AllUsers"
        #URL values:
        # http://acs.amazonaws.com/groups/global/AuthenticatedUsers for any AWS account
        # http://acs.amazonaws.com/groups/global/AllUsers for anyone in the world
        # http://acs.amazonaws.com/groups/s3/LogDelivery for server access logging. see: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html
      }

      permission = "READ"
      #Permission values:
      # READ           list objects in the bucket. read object data and metadata
      # WRITE          create new objects in the bucket. allows objects deletions and overwrites (for owner only)
      # READ_ACP       read the bucket or object ACL
      # WRITE_ACP      write the bucket or object ACL
      # FULL_CONTROL = READ + WRITE + READ_ACP + WRITE_ACP
    }
    owner {
      id           = data.aws_canonical_user_id.current_account.id
      display_name = data.aws_canonical_user_id.current_account.display_name != "" ? data.aws_canonical_user_id.current_account.display_name : var.aws_deployment_account_id # #optional
    }
  }

  expected_bucket_owner = var.aws_deployment_account_id #optional
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  # only one single aws_s3_bucket_lifecycle_configuration per bucket allowed
  bucket = aws_s3_bucket.example_public.id

  rule {
    id     = "remove-all-objects-after-threshold"
    status = local.deployment_environment_is_temporary ? "Enabled" : "Disabled"
    filter {} #select all objects

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      #choose either date or days
      # date = "2200-12-19T00:00:00Z" #for removal at an absolute date in RFC3339 format. time must be at midnight GMT. 
      days = 14 #for removal after a relative amount of days

      # expired_object_delete_marker = true #Conflicts with date and days. whether to remove a delete marker with no noncurrent versions or not.
    }
  }

  expected_bucket_owner = var.aws_deployment_account_id #optional
}

resource "aws_s3_object" "readme" {
  bucket = aws_s3_bucket.example_public.id
  key    = "README"
  source = "uploaded-readme.txt"
  acl    = "public-read"

  etag = filemd5("uploaded-readme.txt")
}

#for transfer acceleration
# resource "aws_s3_bucket_accelerate_configuration" "example" {
#   bucket = aws_s3_bucket.example.bucket
#   status = "Enabled" #Enabled, Suspended
#   expected_bucket_owner = var.aws_deployment_account_id #optional
# }

# aws_s3_bucket_logging
# aws_s3_bucket_object_lock_configuration
# aws_s3_bucket_replication_configuration
# aws_s3_bucket_request_payment_configuration
# aws_s3_bucket_server_side_encryption_configuration

# aws_s3_bucket_analytics_configuration #for sending s3 bucket analytics to other s3 bucket
# aws_s3_bucket_intelligent_tiering_configuration
# aws_s3_bucket_inventory      #for auditing and reporting the replication and encryption status of your objects for business, compliance, and regulatory needs
# aws_s3_bucket_metric         #for Cloudwatch metrics
# aws_s3_bucket_notification   #only one single aws_s3_bucket_notification per bucket allowed
# aws_s3_bucket_ownership_controls

# aws_s3_object
# aws_s3_object_copy

#see S3 website for example implementation of:
# aws_s3_bucket_public_access_block
# aws_s3_bucket_website_configuration
# aws_s3_bucket_cors_configuration
# aws_s3_bucket_versioning
# aws_s3_bucket_lifecycle_configuration with versioning usecase
# aws_s3_bucket_policy
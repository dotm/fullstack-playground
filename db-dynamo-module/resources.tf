#Put resources here.
#If this files become to long, you can move related resources to their own files.

#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
}

#Note:
#Free tier: 25 GB of Storage, 25 provisioned Write Capacity Units (WCU), 25 provisioned Read Capacity Units (RCU)
#Calculation:
#1 RCU  = 2 eventually consistent reads of up to 4 KB/s. (5KB -> 1RCU)
#1 RCU  = 1 strongly consistent read of up to 4 KB/s. (5KB -> 2RCU)
#2 RCUs = 1 transactional read request (one read per second) for items up to 4 KB. (5KB -> 4RCU)
#1 WCU  = 1 standard write of up to 1 KB/s. (5KB -> 5WCU)
#2 WCUs = 1 transactional write request (one write per second) for items up to 1 KB. (5KB -> 10WCU)

resource "aws_dynamodb_table" "example" {
  name         = "${var.deployment_environment_name}-${var.project_name}-table"
  billing_mode = "PAY_PER_REQUEST" #Default value is PROVISIONED. On demand is PAY_PER_REQUEST.
  table_class  = "STANDARD"        #STANDARD or STANDARD_INFREQUENT_ACCESS

  #required for PROVISIONED billing mode
  # write_capacity = 1
  # read_capacity  = 1

  hash_key  = "pk" #attribute used as partition key
  range_key = "sk" #attribute used as sort key

  #you can only specify indexed attributes (pk, sk, lsi, gsi)
  attribute {
    name = "pk"
    type = "S" #(S)tring, (N)umber or (B)inary
  }
  attribute {
    name = "sk"
    type = "S"
  }

  ttl { #ttl attribute type must be Number and use seconds since epoch time (NOT ms)
    enabled        = true
    attribute_name = "item_ttl_at"
  }

  local_secondary_index { #lsi changes cause force new resource because it can only be created at creation time
    name      = "lsi1"
    range_key = "lsi_1"

    projection_type = "ALL"
    #ALL projects every attribute into the index.
    #KEYS_ONLY projects just the hash and range key into the index.
    #INCLUDE projects the keys specified in the non_key_attributes parameter.
    non_key_attributes = [] #do not need to be defined as attributes on the table.
  }
  attribute {
    name = "lsi_1"
    type = "S"
  }

  global_secondary_index { #gsi can be added after creation
    name      = "gsi1"
    hash_key  = "gsi_1"
    range_key = "sk" #optional

    #required for PROVISIONED billing mode
    # write_capacity = 1
    # read_capacity  = 1

    projection_type = "ALL"
    #ALL projects every attribute into the index.
    #KEYS_ONLY projects just the hash and range key into the index.
    #INCLUDE projects the keys specified in the non_key_attributes parameter.
    non_key_attributes = [] #do not need to be defined as attributes on the table.
  }
  attribute {
    name = "gsi_1"
    type = "S"
  }

  point_in_time_recovery { #pitr
    enabled = true
  }

  # stream_enabled   = false
  # stream_view_type = "NEW_AND_OLD_IMAGES" #KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES

  # server_side_encryption { #SSE
  #   enabled = true
  #   kms_key_arn = ""
  #   #If enabled = false, SSE is AWS owned CMK (DEFAULT in the AWS console).
  #   #If enabled = true and no kms_key_arn, then SSE is AWS managed CMK (KMS in the AWS console).
  # }

  # replica { #DynamoDB global table v2 feature
  #   region_name = "ap-southeast-3"
  #   kms_key_arn = "" #optional
  # }

  #restore from previous table
  # restore_source_name    = ""
  # restore_date_time      = ""
  # restore_to_latest_time = true #restore to latest date time pitr

  tags = {}
}

#TODO; fix error from applying item resource
# resource "aws_dynamodb_table_item" "example" {
#   count      = 1
#   table_name = aws_dynamodb_table.example.name
#   hash_key   = aws_dynamodb_table.example.hash_key
#   range_key  = aws_dynamodb_table.example.range_key

#   item = <<-ITEM
#     {
#       "pk": {
#         "S": "pk_value0"
#       },
#       "sk": {
#         "S": "sk_value0"
#       },
#       "gsi_1": {
#         "S": "gsi_value0"
#       },
#       "lsi_1": {
#         "S": "lsi_value0"
#       },
#       "item_ttl_at": {
#         "N": "1655952795"
#       }
#     }
#     ITEM
# }
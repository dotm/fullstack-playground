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
  billing_mode = "PROVISIONED" #Default value is PROVISIONED. On demand is PAY_PER_REQUEST.
  table_class  = "STANDARD"    #STANDARD or STANDARD_INFREQUENT_ACCESS

  #required for PROVISIONED billing mode
  write_capacity = 5
  read_capacity  = 5
  # lifecycle {
  #   # Ignore changes if there's autoscaling policy attached to the table.
  #   ignore_changes = [
  #     write_capacity,
  #     read_capacity,
  #   ]
  # }

  #if no range_key, pk value must be unique, else pk-sk combination value must be unique
  hash_key  = "user_id"    #attribute used as partition key
  range_key = "created_at" #attribute used as sort key

  #you can only specify indexed attributes (pk, sk, lsi, gsi)
  attribute {
    name = "user_id"
    type = "S" #(S)tring, (N)umber or (B)inary
  }
  attribute {
    name = "created_at"
    type = "S"
  }

  ttl { #ttl attribute type must be Number and use seconds since epoch time (NOT ms)
    enabled        = true
    attribute_name = "item_ttl_at"
  }
}

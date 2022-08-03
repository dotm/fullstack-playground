output "vpc_ids" {
  value = data.aws_vpcs.list.ids
}

output "main_db_connection" {
  value = {
    address = aws_db_instance.main.address
    db_name = aws_db_instance.main.db_name
    port    = aws_db_instance.main.port
  }
}

output "main_replicas_connection" {
  value = { for replica in aws_db_instance.main_replica :
    replica.identifier => {
      address = replica.address
      db_name = replica.db_name
      port    = replica.port
    }
  }
}
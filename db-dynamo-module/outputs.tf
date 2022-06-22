output "dynamodb_table_name" {
  value = aws_dynamodb_table.example.id
}

output "vpc_ids" {
  value = data.aws_vpcs.list.ids
}

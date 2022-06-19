output "main_vpc_id" {
  value = aws_vpc.main.id
}

output "main_public_subnet_ids" {
  value = [for key, subnet in aws_subnet.main_public : subnet.id]
}

output "main_private_subnet_ids" {
  value = [for key, subnet in aws_subnet.main_private : subnet.id]
}
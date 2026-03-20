output "endpoints" {
  description = "Map of service name to RDS endpoint"
  value = {
    for idx, name in var.db_names :
    name => aws_db_instance.main[idx].endpoint
  }
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

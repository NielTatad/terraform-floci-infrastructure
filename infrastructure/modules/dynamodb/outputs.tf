output "table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "ID of the DynamoDB table (same as the name)."
  value       = aws_dynamodb_table.this.id
}

output "billing_mode" {
  description = "Billing mode in use on the table."
  value       = aws_dynamodb_table.this.billing_mode
}

# ---------------------------------------------------------------------------
# S3 outputs
# ---------------------------------------------------------------------------

output "s3_bucket_id" {
  description = "Name / ID of the provisioned S3 bucket."
  value       = module.s3_bucket.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the provisioned S3 bucket."
  value       = module.s3_bucket.bucket_arn
}

output "s3_versioning_enabled" {
  description = "Whether versioning is enabled on the S3 bucket."
  value       = module.s3_bucket.versioning_enabled
}

# ---------------------------------------------------------------------------
# DynamoDB outputs
# ---------------------------------------------------------------------------

output "dynamodb_table_name" {
  description = "Name of the provisioned DynamoDB table."
  value       = module.dynamodb_table.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the provisioned DynamoDB table."
  value       = module.dynamodb_table.table_arn
}

# ---------------------------------------------------------------------------
# SQS outputs
# ---------------------------------------------------------------------------

output "sqs_queue_url" {
  description = "URL of the provisioned SQS queue. Use this in application configuration."
  value       = module.sqs_queue.queue_url
}

output "sqs_queue_arn" {
  description = "ARN of the provisioned SQS queue."
  value       = module.sqs_queue.queue_arn
}

output "sqs_queue_name" {
  description = "Name of the provisioned SQS queue."
  value       = module.sqs_queue.queue_name
}

# ---------------------------------------------------------------------------
# Convenience: Floci endpoint
# ---------------------------------------------------------------------------

output "floci_endpoint" {
  description = "Floci endpoint all resources are provisioned against."
  value       = var.floci_endpoint
}

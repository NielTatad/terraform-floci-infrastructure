output "queue_id" {
  description = "URL of the SQS queue (used as its ID by the AWS provider)."
  value       = aws_sqs_queue.this.id
}

output "queue_url" {
  description = "URL of the SQS queue. Use this when sending or receiving messages."
  value       = aws_sqs_queue.this.url
}

output "queue_arn" {
  description = "ARN of the SQS queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_name" {
  description = "Name of the SQS queue."
  value       = aws_sqs_queue.this.name
}

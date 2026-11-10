output "bucket_id" {
  description = "The name of the S3 bucket (also its ID)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket-style domain name for path-style access (used with Floci)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "versioning_enabled" {
  description = "Whether versioning is enabled on this bucket."
  value       = var.enable_versioning
}

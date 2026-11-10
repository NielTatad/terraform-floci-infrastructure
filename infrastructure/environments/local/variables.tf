# ---------------------------------------------------------------------------
# Floci / provider configuration
# ---------------------------------------------------------------------------

variable "floci_endpoint" {
  description = "HTTP endpoint of the local Floci AWS emulator."
  type        = string
  default     = "http://localhost:4566"
}

variable "aws_region" {
  description = "AWS region to report to the provider. Any valid region name works with Floci."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "Dummy AWS access key for the local Floci provider. Never use real credentials here."
  type        = string
  default     = "test"
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Dummy AWS secret key for the local Floci provider. Never use real credentials here."
  type        = string
  default     = "test"
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Environment metadata
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Logical environment name applied as a tag to all resources."
  type        = string
  default     = "local"
}

variable "project" {
  description = "Project name applied as a tag to all resources."
  type        = string
  default     = "floci-demo"
}

# ---------------------------------------------------------------------------
# S3 variables
# ---------------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "Name of the demo S3 bucket."
  type        = string
  default     = "floci-demo-bucket"
}

variable "s3_enable_versioning" {
  description = "Enable object versioning on the S3 bucket."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# DynamoDB variables
# ---------------------------------------------------------------------------

variable "dynamodb_table_name" {
  description = "Name of the demo DynamoDB table."
  type        = string
  default     = "floci-demo-table"
}

variable "dynamodb_hash_key" {
  description = "Partition key attribute name for the DynamoDB table."
  type        = string
  default     = "id"
}

variable "dynamodb_billing_mode" {
  description = "Billing mode for the DynamoDB table. PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

# ---------------------------------------------------------------------------
# SQS variables
# ---------------------------------------------------------------------------

variable "sqs_queue_name" {
  description = "Name of the demo SQS standard queue."
  type        = string
  default     = "floci-demo-queue"
}

variable "sqs_visibility_timeout" {
  description = "Visibility timeout in seconds for the SQS queue."
  type        = number
  default     = 30
}

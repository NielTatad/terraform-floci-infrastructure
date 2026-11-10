# ---------------------------------------------------------------------------
# Common tags applied to every resource in this environment.
# ---------------------------------------------------------------------------

locals {
  common_tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket
# ---------------------------------------------------------------------------

module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name       = var.s3_bucket_name
  enable_versioning = var.s3_enable_versioning
  tags              = local.common_tags
}

# ---------------------------------------------------------------------------
# DynamoDB Table
# ---------------------------------------------------------------------------

module "dynamodb_table" {
  source = "../../modules/dynamodb"

  table_name   = var.dynamodb_table_name
  hash_key     = var.dynamodb_hash_key
  billing_mode = var.dynamodb_billing_mode
  tags         = local.common_tags
}

# ---------------------------------------------------------------------------
# SQS Queue
# ---------------------------------------------------------------------------

module "sqs_queue" {
  source = "../../modules/sqs"

  queue_name                 = var.sqs_queue_name
  visibility_timeout_seconds = var.sqs_visibility_timeout
  tags                       = local.common_tags
}

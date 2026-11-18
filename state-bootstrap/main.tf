# state-bootstrap/main.tf
#
# PURPOSE:
# This is a one-time bootstrap configuration. It creates the S3 bucket and
# DynamoDB table that Terraform uses to store and lock remote state.
#
# In real AWS this solves a chicken-and-egg problem:
#   - You need an S3 bucket to store state
#   - But you can't create that bucket via a pipeline that needs state to run
#   - So you apply this ONCE locally, then never touch it again
#
# Here we do the same thing — but pointed at Floci (local AWS emulator).
# No real AWS account or credentials needed.
#
# HOW TO RUN (one time only):
#   cd state-bootstrap
#   terraform init
#   terraform apply

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # No remote backend here — this config itself uses local state.
  # That is intentional: bootstrap configs always use local state
  # because the remote backend doesn't exist yet when you run this.
  backend "local" {}
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  # Floci-specific: disable real AWS validation checks
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  # Redirect all calls to Floci instead of real AWS
  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

# ---------------------------------------------------------------------------
# S3 bucket — stores Terraform state files
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-cicd-demo"
}

# Enable versioning so you can recover a previous state file if something
# goes wrong (e.g. a failed apply corrupts the state).
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# DynamoDB table — state locking
# ---------------------------------------------------------------------------
# When two people (or two pipeline runs) try to apply at the same time,
# the lock table prevents them from corrupting each other's state.
# Only one apply can hold the lock at a time.
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ---------------------------------------------------------------------------
# Outputs — useful for configuring the backend in other environments
# ---------------------------------------------------------------------------
output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the state S3 bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB lock table."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "backend_config_snippet" {
  description = "Copy this into the backend block of your other Terraform environments."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket                      = "${aws_s3_bucket.terraform_state.id}"
        key                         = "environments/local/terraform.tfstate"
        region                      = "us-east-1"
        endpoint                    = "http://localhost:4566"
        dynamodb_endpoint           = "http://localhost:4566"
        dynamodb_table              = "${aws_dynamodb_table.terraform_lock.name}"
        access_key                  = "test"
        secret_key                  = "test"
        skip_credentials_validation = true
        skip_region_validation      = true
        use_path_style              = true
      }
    }
  EOT
}

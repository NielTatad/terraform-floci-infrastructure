terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state backend — stored in Floci's S3 (local, not real AWS).
  # The bucket and lock table are created by state-bootstrap/main.tf.
  # Run that ONCE before using this environment.
  #
  # To migrate existing local state into this backend run:
  #   terraform init -migrate-state
  backend "s3" {
    bucket = "my-terraform-state-cicd-demo"
    key    = "environments/local/terraform.tfstate"
    region = "us-east-1"

    # Point to Floci instead of real AWS
    endpoint          = "http://localhost:4566"
    dynamodb_endpoint = "http://localhost:4566"
    dynamodb_table    = "terraform-state-lock"
    encrypt = true

    # Dummy credentials — same as the provider
    access_key = "test"
    secret_key = "test"

    # Disable real AWS validation
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  # Disable all real-AWS validation checks. These would fail because
  # we are pointing at a local Floci endpoint, not actual AWS.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Required for S3: use path-style URLs (http://localhost:4566/<bucket>)
  # instead of virtual-hosted-style (http://<bucket>.localhost:4566).
  s3_use_path_style = true

  # Redirect every AWS service used by this environment to Floci.
  # Add a new entry here whenever a new AWS service module is introduced.
  endpoints {
    s3       = var.floci_endpoint
    dynamodb = var.floci_endpoint
    sqs      = var.floci_endpoint
  }
}

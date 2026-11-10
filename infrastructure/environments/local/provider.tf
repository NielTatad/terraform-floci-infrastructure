terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local backend — state is stored in terraform.tfstate in this directory.
  # This file is excluded from Git via .gitignore.
  #
  # To migrate to a Floci-backed S3 remote state (fully local, no real AWS),
  # replace this block with the s3 backend snippet from the README and
  # pre-create the bucket and lock table using the bootstrap commands there.
  backend "local" {}
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

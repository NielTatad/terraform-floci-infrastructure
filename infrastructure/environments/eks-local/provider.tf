terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local state for the EKS environment.
  # Upgrade to S3 backend (Floci-backed) using the state-bootstrap config
  # once the foundation is stable.
  backend "local" {}
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  # Every AWS service used by any module in this environment must have
  # an endpoint entry here pointing to Floci.
  endpoints {
    # Existing services
    s3       = var.floci_endpoint
    dynamodb = var.floci_endpoint
    sqs      = var.floci_endpoint

    # Phase 1 — Networking
    ec2 = var.floci_endpoint

    # Phase 2 — IAM
    iam = var.floci_endpoint
    sts = var.floci_endpoint

    # Phase 3 — EKS
    eks = var.floci_endpoint

    # Phase 4 — Supporting services
    ecr            = var.floci_endpoint
    elbv2          = var.floci_endpoint
    cloudwatchlogs = var.floci_endpoint
  }
}

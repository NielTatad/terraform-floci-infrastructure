# terraform-floci-infrastructure

A production-style local AWS Infrastructure as Code (IaC) repository using **Terraform** and **[Floci](https://github.com/floci-io/floci)** — a free, open-source local AWS emulator.

No real AWS account. No credentials. No cloud costs.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Floci](#floci)
  - [Start and Stop](#start-and-stop)
  - [Web Console](#web-console)
  - [Persistence](#persistence)
- [Credentials Configuration](#credentials-configuration)
  - [Environment Variables](#environment-variables)
  - [Optional AWS CLI Profile](#optional-aws-cli-profile)
- [Terraform](#terraform)
  - [How State Works](#how-state-works)
  - [Initialise](#initialise)
  - [Plan](#plan)
  - [Apply](#apply)
  - [Destroy](#destroy)
- [Automation Scripts](#automation-scripts)
- [Verifying Resources with the AWS CLI](#verifying-resources-with-the-aws-cli)
- [Extending the Repository](#extending-the-repository)
- [Troubleshooting](#troubleshooting)
- [Known Floci Limitations](#known-floci-limitations)

---

## Overview

This repository provisions three AWS-compatible resources entirely on your local machine:

| Service    | Resource              | Module                              |
|------------|-----------------------|-------------------------------------|
| S3         | Object storage bucket | `infrastructure/modules/s3`         |
| DynamoDB   | NoSQL table           | `infrastructure/modules/dynamodb`   |
| SQS        | Message queue         | `infrastructure/modules/sqs`        |

Terraform uses the standard **hashicorp/aws** provider (`~> 6.0`) with its endpoint override feature to redirect all API calls to Floci running at `http://localhost:4566`. No real AWS account or IAM credentials are involved at any point.

---

## Architecture

```
Your machine
│
├── Docker
│   └── floci/floci:latest  ← Local AWS emulator on :4566
│
└── Terraform (hashicorp/aws ~> 6.0)
    ├── endpoint: http://localhost:4566  (S3, DynamoDB, SQS)
    ├── credentials: "test" / "test"     (dummy — Floci accepts any value)
    └── state: local file (terraform.tfstate, git-ignored)
```

All service calls go to Floci via the `endpoints {}` block in `provider.tf`. Floci stores resource state in `floci/data/` using its **hybrid** storage mode (in-memory with periodic flush every 5 seconds).

---

## Repository Structure

```
terraform-floci-infrastructure/
├── infrastructure/
│   ├── modules/
│   │   ├── s3/                   # Reusable S3 module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── dynamodb/             # Reusable DynamoDB module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── sqs/                  # Reusable SQS module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── environments/
│       └── local/                # Local environment configuration
│           ├── main.tf           # Module calls + common_tags
│           ├── provider.tf       # AWS provider + Floci endpoint config
│           ├── variables.tf      # All input variables with defaults
│           ├── outputs.tf        # Exposed resource attributes
│           └── terraform.tfvars.example
│
├── floci/
│   ├── docker-compose.yml        # Floci container definition
│   └── data/                     # Persisted Floci state (git-ignored)
│
├── scripts/
│   ├── init.sh                   # Start Floci + terraform init
│   ├── plan.sh                   # terraform validate + plan
│   ├── apply.sh                  # terraform apply
│   ├── destroy.sh                # terraform destroy (with confirmation)
│   └── status.sh                 # Show container + Terraform state
│
├── .env.example                  # Credential template (copy to .env)
├── .gitignore
├── .terraform.lock.hcl           # Provider dependency lock file
└── README.md
```

---

## Prerequisites

| Tool        | Minimum version | Install                                      |
|-------------|-----------------|----------------------------------------------|
| Docker      | 24+             | https://docs.docker.com/get-docker/          |
| Docker Compose | v2 (plugin) | Included with Docker Desktop                 |
| Terraform   | 1.6+            | https://developer.hashicorp.com/terraform/install |
| AWS CLI     | v2 (optional)   | https://aws.amazon.com/cli/                  |
| curl        | any             | Pre-installed on most systems                |

> **Windows users:** run the Bash scripts inside WSL 2. All commands in this README assume a Bash-compatible shell.

---

## Quick Start

```bash
# 1. Clone the repository
git clone <repo-url>
cd terraform-floci-infrastructure

# 2. Set up local credentials
cp .env.example .env          # values are already correct — no edits needed

# 3. Start Floci and initialise Terraform
./scripts/init.sh

# 4. Preview what will be created
./scripts/plan.sh

# 5. Provision the resources
./scripts/apply.sh

# 6. Verify
aws --endpoint-url http://localhost:4566 s3 ls
aws --endpoint-url http://localhost:4566 dynamodb list-tables
aws --endpoint-url http://localhost:4566 sqs list-queues
```

---

## Floci

### Start and Stop

```bash
# Start Floci in the background
docker compose -f floci/docker-compose.yml up -d

# View logs
docker compose -f floci/docker-compose.yml logs -f floci

# Stop Floci (keeps persisted state)
docker compose -f floci/docker-compose.yml down

# Stop and wipe all persisted state
docker compose -f floci/docker-compose.yml down -v
rm -rf floci/data/
```

### Web Console

Floci ships a browser-based resource inspector. Once the container is running, open:

```
http://localhost:4566/_floci/ui
```

The first visit pulls the console sidecar image and starts it automatically. No additional configuration is required.

### Persistence

Floci is configured with `FLOCI_STORAGE_MODE=hybrid`. This keeps resource state in memory for performance and flushes to disk every 5 seconds. State survives container restarts as long as `floci/data/` exists.

| Mode         | Behaviour                                | Best for              |
|--------------|------------------------------------------|-----------------------|
| `memory`     | All data lost when container stops       | CI / ephemeral tests  |
| `hybrid`     | In-memory + flush every 5s (default)     | Local development     |
| `persistent` | Flush on every write                     | High-durability local |
| `wal`        | Write-ahead log before every response    | Maximum durability    |

Change the mode by editing `FLOCI_STORAGE_MODE` in `floci/docker-compose.yml`.

---

## Credentials Configuration

### Environment Variables

This repository uses **dummy credentials** — Floci accepts any non-empty string.

```bash
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
AWS_ENDPOINT_URL=http://localhost:4566
```

Copy `.env.example` to `.env` to have the scripts load them automatically:

```bash
cp .env.example .env
```

`.env` is excluded from Git. Never put real AWS credentials in any file in this repository.

### Optional AWS CLI Profile

You can configure a named profile called `floci` so you can use the AWS CLI without passing `--endpoint-url` on every command:

```bash
# Configure the profile
aws configure --profile floci
# AWS Access Key ID:     test
# AWS Secret Access Key: test
# Default region:        us-east-1
# Default output format: json

# Set the endpoint override for the profile
aws configure set endpoint_url http://localhost:4566 --profile floci
```

Then use it like this:

```bash
aws s3 ls --profile floci
aws dynamodb list-tables --profile floci
aws sqs list-queues --profile floci
```

Or export it for your session:

```bash
export AWS_PROFILE=floci
aws s3 ls
```

---

## Terraform

### How State Works

Terraform tracks every resource it manages in a **state file** (`terraform.tfstate`). This file:

- Lives in `infrastructure/environments/local/` by default (local backend).
- Is **excluded from Git** via `.gitignore` — it may contain sensitive output values.
- Must be present to run `plan`, `apply`, or `destroy` reliably.
- Can be inspected at any time:

```bash
# List all managed resources
terraform -chdir=infrastructure/environments/local state list

# Show details of a specific resource
terraform -chdir=infrastructure/environments/local state show module.s3_bucket.aws_s3_bucket.this
```

**Future remote state:** Floci supports the S3 backend with DynamoDB locking. See the [Floci Terraform docs](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md) for the backend configuration and bootstrap commands.

### Initialise

Initialisation downloads the AWS provider and sets up the working directory. Run this once, or after adding a new module or provider.

```bash
# Via script (also starts Floci)
./scripts/init.sh

# Manually
terraform -chdir=infrastructure/environments/local init
```

After `init` completes, commit the updated `.terraform.lock.hcl` to lock provider versions for all contributors.

### Plan

```bash
# Via script
./scripts/plan.sh

# Manually
terraform -chdir=infrastructure/environments/local validate
terraform -chdir=infrastructure/environments/local plan
```

### Apply

```bash
# Via script
./scripts/apply.sh

# Manually
terraform -chdir=infrastructure/environments/local apply
```

### Destroy

```bash
# Via script (prompts for confirmation)
./scripts/destroy.sh

# Manually
terraform -chdir=infrastructure/environments/local destroy
```

---

## Automation Scripts

All scripts live in `scripts/` and require Bash. Run them from the repository root.

| Script        | Purpose                                                      |
|---------------|--------------------------------------------------------------|
| `init.sh`     | Start Floci, wait for health, run `terraform init`           |
| `plan.sh`     | Check Floci health, validate config, show execution plan     |
| `apply.sh`    | Check Floci health, apply infrastructure changes             |
| `destroy.sh`  | Confirm, destroy resources, optionally stop Floci            |
| `status.sh`   | Show container status, Floci health, and Terraform resources |

Each script:
- Uses `set -euo pipefail` for strict error handling.
- Checks for `docker` and `terraform` before proceeding.
- Verifies Floci is healthy before running any Terraform command.
- Loads credentials from `.env` if the file exists.

---

## Verifying Resources with the AWS CLI

After running `apply`, verify the provisioned resources:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
ENDPOINT=http://localhost:4566

# S3 — list buckets
aws --endpoint-url $ENDPOINT s3 ls

# S3 — check versioning
aws --endpoint-url $ENDPOINT s3api get-bucket-versioning \
  --bucket floci-demo-bucket

# S3 — put and retrieve an object
aws --endpoint-url $ENDPOINT s3 cp README.md s3://floci-demo-bucket/test.md
aws --endpoint-url $ENDPOINT s3 ls s3://floci-demo-bucket

# DynamoDB — list tables
aws --endpoint-url $ENDPOINT dynamodb list-tables

# DynamoDB — describe the table
aws --endpoint-url $ENDPOINT dynamodb describe-table \
  --table-name floci-demo-table

# DynamoDB — put and get an item
aws --endpoint-url $ENDPOINT dynamodb put-item \
  --table-name floci-demo-table \
  --item '{"id": {"S": "item-1"}, "value": {"S": "hello from floci"}}'

aws --endpoint-url $ENDPOINT dynamodb get-item \
  --table-name floci-demo-table \
  --key '{"id": {"S": "item-1"}}'

# SQS — list queues
aws --endpoint-url $ENDPOINT sqs list-queues

# SQS — send and receive a message
QUEUE_URL=$(aws --endpoint-url $ENDPOINT sqs get-queue-url \
  --queue-name floci-demo-queue --query QueueUrl --output text)

aws --endpoint-url $ENDPOINT sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "hello from terraform + floci"

aws --endpoint-url $ENDPOINT sqs receive-message \
  --queue-url "$QUEUE_URL"
```

---

## Extending the Repository

To add a new AWS service (e.g. SNS):

1. **Create the module** under `infrastructure/modules/sns/` with `main.tf`, `variables.tf`, and `outputs.tf`.

2. **Call the module** from `infrastructure/environments/local/main.tf`:
   ```hcl
   module "sns_topic" {
     source     = "../../modules/sns"
     topic_name = var.sns_topic_name
     tags       = local.common_tags
   }
   ```

3. **Add the endpoint override** in `infrastructure/environments/local/provider.tf`:
   ```hcl
   endpoints {
     s3       = var.floci_endpoint
     dynamodb = var.floci_endpoint
     sqs      = var.floci_endpoint
     sns      = var.floci_endpoint   # ← add this
   }
   ```

4. **Add variables** in `variables.tf` and `terraform.tfvars.example`.

5. **Add outputs** in `outputs.tf`.

6. **Re-run init and apply:**
   ```bash
   ./scripts/init.sh
   ./scripts/apply.sh
   ```

> Before adding a service, confirm it is supported by checking the [Floci Services Overview](https://github.com/floci-io/floci/blob/main/README.md#supported-services). Floci supports 45+ services including SNS, Lambda, IAM, STS, KMS, Secrets Manager, EventBridge, Step Functions, API Gateway, Cognito, and more.

---

## Troubleshooting

**Floci container won't start**
```
Error response from daemon: Conflict. The container name "/floci" is already in use.
```
A stopped container with the same name exists. Remove it:
```bash
docker rm floci
docker compose -f floci/docker-compose.yml up -d
```

---

**Health check times out**
```
[init] ✗ Floci did not become healthy within 60s.
```
Check the container logs for startup errors:
```bash
docker compose -f floci/docker-compose.yml logs floci
```
Common causes: port 4566 already in use by another process, or Docker daemon not running.

---

**Terraform can't connect to endpoint**
```
Error: Failed to query available provider packages
```
Ensure Floci is running before `terraform init`:
```bash
./scripts/init.sh   # always starts Floci first
```

---

**`NoCredentialProviders` error**
```
No valid credential providers found.
```
The AWS provider needs credentials even for local use. Ensure your environment has:
```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```
Or copy `.env.example` to `.env` and re-run the script.

---

**S3 bucket already exists**
```
BucketAlreadyExists: The requested bucket name is not available.
```
Floci is stateful — if the bucket was created in a previous run and state was lost, import it:
```bash
terraform -chdir=infrastructure/environments/local \
  import module.s3_bucket.aws_s3_bucket.this floci-demo-bucket
```

---

**`terraform.tfstate` is missing after container restart**
Terraform state is stored locally on your filesystem — it is not affected by Floci restarts. If the state file is gone, you will need to re-apply or use `terraform import` to reconcile. This is why committing state to a remote backend (even a Floci-backed S3 bucket) is recommended for team workflows.

---

**Port 4566 already in use**
```bash
# Find what is using the port
lsof -i :4566

# Or on Windows/WSL
netstat -ano | grep 4566
```

---

## Known Floci Limitations

- **No real network traffic:** Floci is an in-process emulator. It does not simulate network latency, throttling, or service quotas.
- **Lambda cold starts differ:** Floci uses real Docker containers for Lambda, but startup behaviour and timeouts may differ from real AWS.
- **IAM is not enforced by default:** Floci accepts any credentials and does not enforce IAM policies unless you explicitly enable stricter auth (`FLOCI_SERVICES_S3_ENFORCE_AUTH=true` for S3).
- **CloudFront and Route53 are control-plane stubs:** Data-plane behaviour (actual request routing and DNS resolution) is not emulated.
- **No cross-region replication:** Floci runs as a single instance; multi-region setups are not meaningful locally.
- **EKS / RDS / ElastiCache require Docker:** These services launch real containers. They need the Docker socket mounted and sufficient memory on your machine.
- **State is not shared by default:** Each developer runs their own Floci instance. For shared local state, configure the S3 backend pointing at Floci (see the Terraform docs link above).

---

## References

- [Floci GitHub](https://github.com/floci-io/floci)
- [Floci — Terraform Guide](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)
- [Floci — Services Overview](https://github.com/floci-io/floci/blob/main/README.md#supported-services)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language Docs](https://developer.hashicorp.com/terraform/language)

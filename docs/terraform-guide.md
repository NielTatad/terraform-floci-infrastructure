# Terraform Guide

This guide covers everything you need to work with Terraform in this repository — module structure, provider configuration, workflows, and state management.

---

## Directory Structure

```
terraform-floci-infrastructure/
├── state-bootstrap/          ← One-time: creates remote state backend in Floci
│   └── main.tf
│
└── infrastructure/
    ├── modules/              ← Reusable building blocks (never run directly)
    │   ├── s3/
    │   ├── dynamodb/
    │   ├── sqs/
    │   ├── vpc/
    │   ├── security-groups/
    │   ├── iam-eks/
    │   ├── eks-cluster/
    │   ├── eks-nodegroup/
    │   ├── ecr/
    │   ├── alb/
    │   └── cloudwatch-logs/
    │
    └── environments/         ← Apply from here
        ├── local/            ← Basic AWS services (S3, DynamoDB, SQS)
        └── eks-local/        ← EKS-like infrastructure
```

**Rule:** always run `terraform` commands from an `environments/` directory, never from inside a module. Modules have no provider configuration and will fail if run directly.

---

## Module Reference

### `modules/s3`

Creates an S3 bucket with optional versioning.

| Variable | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | string | — | Bucket name (required) |
| `enable_versioning` | bool | `true` | Enable object versioning |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `bucket_id`, `bucket_arn`, `bucket_domain_name`, `versioning_enabled`

### `modules/dynamodb`

Creates a DynamoDB table with configurable keys and billing.

| Variable | Type | Default | Description |
|---|---|---|---|
| `table_name` | string | — | Table name (required) |
| `hash_key` | string | — | Partition key name (required) |
| `hash_key_type` | string | `"S"` | Key type: S, N, or B |
| `range_key` | string | `null` | Sort key name (optional) |
| `billing_mode` | string | `"PAY_PER_REQUEST"` | PAY_PER_REQUEST or PROVISIONED |
| `read_capacity` | number | `5` | Used when billing_mode=PROVISIONED |
| `write_capacity` | number | `5` | Used when billing_mode=PROVISIONED |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `table_name`, `table_arn`, `table_id`, `billing_mode`

### `modules/sqs`

Creates an SQS queue (standard or FIFO).

| Variable | Type | Default | Description |
|---|---|---|---|
| `queue_name` | string | — | Queue name (required) |
| `fifo_queue` | bool | `false` | Create FIFO queue (name must end with `.fifo`) |
| `visibility_timeout_seconds` | number | `30` | 0–43200 |
| `message_retention_seconds` | number | `345600` | 60–1209600 |
| `delay_seconds` | number | `0` | 0–900 |
| `max_message_size` | number | `262144` | 1024–262144 bytes |
| `receive_wait_time_seconds` | number | `0` | 0–20 |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `queue_id`, `queue_url`, `queue_arn`, `queue_name`

### `modules/vpc`

Creates a full VPC with public and private subnets across two AZs, plus Internet Gateway and NAT Gateway.

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix for all resources (required) |
| `vpc_cidr` | string | `"10.0.0.0/16"` | VPC CIDR block |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24","10.0.2.0/24"]` | One per AZ |
| `private_subnet_cidrs` | list(string) | `["10.0.10.0/24","10.0.11.0/24"]` | One per AZ |
| `availability_zones` | list(string) | `["us-east-1a","us-east-1b"]` | AZs for subnets |
| `enable_nat_gateway` | bool | `true` | Create NAT Gateway |
| `single_nat_gateway` | bool | `true` | One NAT GW for all private subnets |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `nat_gateway_ids`, `public_route_table_id`, `private_route_table_ids`

### `modules/security-groups`

Creates three security groups: EKS cluster control plane, EKS worker nodes, and ALB.

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix (required) |
| `vpc_id` | string | — | VPC ID (required) |
| `vpc_cidr` | string | — | VPC CIDR for intra-cluster rules (required) |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `cluster_sg_id`, `nodes_sg_id`, `alb_sg_id`

### `modules/iam-eks`

Creates IAM roles and policies for the EKS cluster and worker nodes.

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix (required) |
| `tags` | map(string) | `{}` | Resource tags |

Roles created:
- `{name}-eks-cluster-role` — assumed by `eks.amazonaws.com`, attaches `AmazonEKSClusterPolicy` and `AmazonEKSVPCResourceController`
- `{name}-eks-node-role` — assumed by `ec2.amazonaws.com`, attaches `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonSSMManagedInstanceCore`

Outputs: `cluster_role_arn`, `cluster_role_name`, `node_role_arn`, `node_role_name`, `node_instance_profile_name`, `node_instance_profile_arn`

### `modules/eks-cluster`

Creates the EKS cluster resource. In Floci this provisions the control-plane API record — the Kubernetes endpoint is a stub.

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | — | Cluster name (required) |
| `kubernetes_version` | string | `"1.31"` | Kubernetes version |
| `cluster_role_arn` | string | — | IAM role ARN (required) |
| `subnet_ids` | list(string) | — | Public + private subnet IDs (required) |
| `cluster_sg_id` | string | — | Control-plane security group ID (required) |
| `endpoint_private_access` | bool | `true` | Enable private endpoint |
| `endpoint_public_access` | bool | `true` | Enable public endpoint |
| `enabled_log_types` | list(string) | all five | Control-plane log types |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `cluster_id`, `cluster_name`, `cluster_arn`, `cluster_endpoint`, `cluster_version`, `cluster_certificate_authority`, `cluster_security_group_id`

### `modules/eks-nodegroup`

Creates an EKS managed node group. In Floci this provisions the node group API record — no real EC2 instances are launched.

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | — | Cluster name (required) |
| `nodegroup_name` | string | — | Node group name (required) |
| `node_role_arn` | string | — | Node IAM role ARN (required) |
| `subnet_ids` | list(string) | — | Private subnet IDs (required) |
| `desired_size` | number | `2` | Desired node count |
| `min_size` | number | `1` | Minimum node count |
| `max_size` | number | `3` | Maximum node count |
| `instance_types` | list(string) | `["t3.medium"]` | EC2 instance types |
| `ami_type` | string | `"AL2_x86_64"` | Node AMI type |
| `capacity_type` | string | `"ON_DEMAND"` | ON_DEMAND or SPOT |
| `disk_size` | number | `20` | Root volume size in GiB |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `nodegroup_id`, `nodegroup_arn`, `nodegroup_name`, `nodegroup_status`

### `modules/ecr`

Creates an ECR repository with image scanning and an optional lifecycle policy.

| Variable | Type | Default | Description |
|---|---|---|---|
| `repository_name` | string | — | Repository name (required) |
| `image_tag_mutability` | string | `"MUTABLE"` | MUTABLE or IMMUTABLE |
| `scan_on_push` | bool | `true` | Enable vulnerability scanning |
| `enable_lifecycle_policy` | bool | `true` | Attach lifecycle policy |
| `max_image_count` | number | `10` | Max tagged images to retain |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `repository_url`, `repository_arn`, `repository_name`, `registry_id`

### `modules/alb`

Creates an Application Load Balancer with a target group and HTTP listener.

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | ALB name (required) |
| `vpc_id` | string | — | VPC ID (required) |
| `public_subnet_ids` | list(string) | — | Public subnets for the ALB (required) |
| `alb_sg_id` | string | — | ALB security group ID (required) |
| `enable_deletion_protection` | bool | `false` | Prevent accidental deletion |
| `target_port` | number | `80` | Port for target group |
| `health_check_path` | string | `"/healthz"` | Health check HTTP path |
| `tags` | map(string) | `{}` | Resource tags |

Outputs: `alb_arn`, `alb_dns_name`, `alb_zone_id`, `target_group_arn`, `listener_arn`

### `modules/cloudwatch-logs`

Creates CloudWatch log groups for EKS control-plane and application logs.

| Variable | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | — | EKS cluster name (required) |
| `retention_days` | number | `7` | Log retention period |
| `tags` | map(string) | `{}` | Resource tags |

Log groups created:
- `/aws/eks/{cluster_name}/cluster`
- `/aws/eks/{cluster_name}/application`

Outputs: `cluster_log_group_name`, `cluster_log_group_arn`, `application_log_group_name`, `application_log_group_arn`

---

## Provider Configuration

Both environments configure the AWS provider identically in concept. The key settings that make Terraform work with Floci:

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = "test"   # dummy — Floci accepts any non-empty value
  secret_key = "test"

  # Disable real-AWS validation — these would all fail against Floci
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Required for S3: path-style URLs instead of virtual-hosted
  s3_use_path_style = true

  # Redirect every service to Floci
  endpoints {
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    eks            = "http://localhost:4566"
    ecr            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
  }
}
```

**When you add a new module that uses a new AWS service, you must add an endpoint entry here.** If you forget, Terraform will try to call real AWS and fail.

---

## Workflows

All commands run from the relevant `environments/` directory.

### First-time setup (state bootstrap)

The `environments/local` environment uses a Floci-backed S3 remote state. Create the backend resources once before initialising that environment:

```bash
cd state-bootstrap
terraform init
terraform apply
# type: yes
```

Expected output:
```
Apply complete! Resources: 3 added.
Outputs:
  state_bucket_name = "my-terraform-state-cicd-demo"
  lock_table_name   = "terraform-state-lock"
```

### Init

Downloads the provider and resolves modules. Run once, or after adding new modules.

```bash
terraform init
# Expected: "Terraform has been successfully initialized!"
```

After init, commit the generated `.terraform.lock.hcl` to version control:

```bash
git add .terraform.lock.hcl
git commit -m "chore: update terraform lock file"
```

### Format

Canonically formats all `.tf` files. No output means no changes were needed.

```bash
terraform fmt -recursive
```

### Validate

Checks syntax and internal consistency. Does not contact Floci.

```bash
terraform validate
# Expected: "Success! The configuration is valid."
```

### Plan

Shows exactly what Terraform will create, change, or destroy — without making any changes.

```bash
terraform plan
```

Read the plan carefully before applying. Look for unexpected additions or deletions.

### Apply — all resources

```bash
terraform apply
# Review the plan, type: yes
```

Apply only specific modules:

```bash
terraform apply -target=module.s3_bucket
terraform apply -target=module.vpc
terraform apply -target=module.eks_cluster
```

### Destroy

```bash
# Destroy everything in this environment
terraform destroy

# Destroy only specific resources
terraform destroy -target=module.eks_nodegroup
terraform destroy -target=module.eks_cluster
```

---

## State Management

### What state is

Terraform tracks every resource it manages in a state file. It is Terraform's memory — without it, Terraform cannot know what already exists.

### Where state lives

| Environment | Backend | Location |
|---|---|---|
| `state-bootstrap` | local | `state-bootstrap/terraform.tfstate` |
| `environments/local` | S3 (Floci) | `s3://my-terraform-state-cicd-demo/environments/local/terraform.tfstate` |
| `environments/eks-local` | local | `infrastructure/environments/eks-local/terraform.tfstate` |

State files are excluded from Git via `.gitignore`. Never commit them.

### Inspecting state

```bash
# List all managed resources
terraform state list

# Show details of one resource
terraform state show module.vpc.aws_vpc.this

# Show all outputs
terraform output
```

### Drift detection

If a resource is changed or deleted outside Terraform (e.g. via the Floci UI or AWS CLI), the state becomes inconsistent with reality. Detect and fix this:

```bash
# See what has drifted
terraform plan -refresh-only

# Sync state to match what actually exists
terraform apply -refresh-only

# Re-create anything that is now missing
terraform apply
```

### Importing existing resources

If a resource was created outside Terraform and you want Terraform to manage it:

```bash
terraform import module.s3_bucket.aws_s3_bucket.this my-existing-bucket
```

---

## Adding a New AWS Service

1. Create `infrastructure/modules/<service>/` with `main.tf`, `variables.tf`, `outputs.tf`
2. Add a module call in `environments/eks-local/main.tf`
3. Add the service endpoint to the `endpoints {}` block in `provider.tf`
4. Add variables to `variables.tf` and `terraform.tfvars.example`
5. Add outputs to `outputs.tf`
6. Run `terraform init`, `terraform fmt`, `terraform validate`, `terraform plan`

Before implementing, verify the service is supported by Floci:

```bash
export AWS_PAGER=""
aws --endpoint-url http://localhost:4566 --no-cli-pager \
  <service> <list-or-describe-command>
```

If the response is a valid (even empty) JSON object, the service is supported.

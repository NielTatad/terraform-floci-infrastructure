# Floci Guide

Floci is a free, open-source local AWS emulator. It runs the AWS wire protocol on `localhost:4566` so your existing AWS tools — Terraform, AWS CLI, SDKs — work without modification.

---

## Installation

### Option A — Floci CLI (recommended)

The CLI installs and manages the Floci daemon for you.

```bash
curl -fsSL https://get.floci.io | bash
source ~/.bashrc   # reload PATH
floci --version
```

### Option B — Docker directly

Pull and run the official image:

```bash
docker run -d \
  --name floci \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  floci/floci:latest
```

### Option C — Docker Compose (this repository)

The `floci/docker-compose.yml` in this repository provides a pre-configured setup with persistent storage and health checks:

```bash
docker compose -f floci/docker-compose.yml up -d
```

---

## Starting and Stopping

### CLI

```bash
floci start       # start in background
floci status      # show running status and endpoint
floci stop        # stop the daemon
floci restart     # restart
```

### Docker Compose

```bash
# Start
docker compose -f floci/docker-compose.yml up -d

# View logs
docker compose -f floci/docker-compose.yml logs -f floci

# Stop (preserves state)
docker compose -f floci/docker-compose.yml down

# Stop and wipe all state
docker compose -f floci/docker-compose.yml down -v
rm -rf floci/data/
```

---

## Health Check

Floci exposes a health endpoint:

```bash
curl -s http://localhost:4566/_floci/health
# Expected: {"status":"ok"}
```

If this does not return `{"status":"ok"}`, Floci is not ready yet. Wait a few seconds and retry.

---

## Web Console

Floci includes a browser-based resource inspector. Open it after starting Floci:

```
http://localhost:4566/_floci/ui
```

The first visit pulls and starts a sidecar container automatically. Use the UI to inspect resources visually. **Do not use the UI to delete resources managed by Terraform** — it will cause state drift. See [Troubleshooting](troubleshooting.md#drift) for how to recover.

---

## AWS CLI Configuration

Always use `--no-cli-pager` and `--endpoint-url` with Floci to avoid the terminal pager issue:

```bash
export AWS_PAGER=""
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url http://localhost:4566 --no-cli-pager s3 ls
```

Or set up a named profile:

```bash
aws configure --profile floci
# Access key: test
# Secret key: test
# Region:     us-east-1
# Format:     json

aws configure set endpoint_url http://localhost:4566 --profile floci

# Use it
aws s3 ls --profile floci
```

---

## Storage and Persistence

Floci supports four storage modes, configured via `FLOCI_STORAGE_MODE`:

| Mode | Behaviour | Use when |
|---|---|---|
| `memory` | All data lost on container stop | CI pipelines, throwaway tests |
| `hybrid` | In-memory + flush to disk every 5s | Local development (default in this repo) |
| `persistent` | Write to disk on every operation | Need data to survive crashes |
| `wal` | Write-ahead log before responding | Maximum durability |

This repository uses `hybrid`. The state is written to `floci/data/` and survives container restarts.

To change the mode, edit `floci/docker-compose.yml`:

```yaml
environment:
  FLOCI_STORAGE_MODE: persistent   # or memory, hybrid, wal
```

---

## Supported Services

The following services were verified against Floci 2.5.0 during development of this repository:

| Service | Verified Operations | Notes |
|---|---|---|
| **S3** | CreateBucket, PutObject, GetObject, ListBuckets, PutBucketVersioning | Fully functional |
| **DynamoDB** | CreateTable, PutItem, GetItem, Query, Scan | Fully functional |
| **SQS** | CreateQueue, SendMessage, ReceiveMessage, DeleteMessage | Fully functional |
| **EC2/VPC** | CreateVpc, CreateSubnet, CreateInternetGateway, CreateNatGateway, CreateRouteTable, CreateSecurityGroup | Fully functional |
| **IAM** | CreateRole, AttachRolePolicy, CreateInstanceProfile | Fully functional |
| **EKS** | CreateCluster, DescribeCluster, ListClusters, CreateNodegroup, DescribeNodegroup | Control-plane API only — see below |
| **ECR** | CreateRepository, DescribeRepositories | Fully functional |
| **ELB v2** | CreateLoadBalancer, CreateTargetGroup, CreateListener | Fully functional |
| **CloudWatch Logs** | CreateLogGroup, PutLogEvents, DescribeLogGroups | Fully functional |
| **STS** | GetCallerIdentity, AssumeRole | Fully functional |

Floci supports 45+ services total. See the [Floci services overview](https://github.com/floci-io/floci/blob/main/README.md#supported-services) for the complete list.

---

## EKS Limitations

This is the most important limitation to understand.

### What works

Floci implements the EKS control-plane API. After `terraform apply` or manual CLI commands, you can:

```bash
# List clusters
aws --endpoint-url http://localhost:4566 --no-cli-pager eks list-clusters
# Returns: { "clusters": ["floci-eks-cluster"] }

# Describe cluster (returns full metadata)
aws --endpoint-url http://localhost:4566 --no-cli-pager eks describe-cluster \
  --name floci-eks-cluster

# List node groups
aws --endpoint-url http://localhost:4566 --no-cli-pager eks list-nodegroups \
  --cluster-name floci-eks-cluster

# Describe node group
aws --endpoint-url http://localhost:4566 --no-cli-pager eks describe-nodegroup \
  --cluster-name floci-eks-cluster \
  --nodegroup-name floci-eks-nodes
```

### What does not work

- The `endpoint` URL returned by `describe-cluster` is a stub. `kubectl` cannot connect to it.
- No real Kubernetes API server is running.
- No real EC2 instances are launched for worker nodes.
- `kubectl get nodes` will not show Floci-managed nodes.
- EKS add-ons (CoreDNS, kube-proxy, VPC CNI) are not provisioned.

### The workaround

Kind provides the real Kubernetes runtime. See the [Kubernetes Guide](kubernetes-guide.md) for how to set it up and integrate it with the Floci infrastructure.

---

## Other Known Limitations

| Limitation | Details |
|---|---|
| **IAM not enforced** | Floci accepts any credentials. IAM policies are stored and queryable but not enforced by default. Set `FLOCI_SERVICES_S3_ENFORCE_AUTH=true` to enforce S3 auth. |
| **No cross-region replication** | Floci is a single instance. Multi-region setups are not meaningful locally. |
| **No real DNS resolution** | Route53 hosted zones are created but DNS does not resolve locally. |
| **CloudFront data plane** | CloudFront distributions are created but actual request routing does not work. |
| **ALB request routing** | ALB resources are created but the ALB does not proxy real HTTP traffic in Floci. |
| **Lambda Docker images** | Lambda with Docker-backed execution requires the Docker socket. Works with `floci/docker-compose.yml` as configured but not with the CLI-managed daemon on some systems. |
| **State not shared** | Each developer has their own Floci instance. Resources in one person's Floci are not visible in another's. |

---

## Multi-Account Isolation

Floci supports account-level resource isolation. If `AWS_ACCESS_KEY_ID` is exactly 12 digits, Floci treats it as an AWS account ID. Resources created with different 12-digit keys are isolated from each other.

```bash
# Account 111111111111
AWS_ACCESS_KEY_ID=111111111111 aws --endpoint-url http://localhost:4566 \
  --no-cli-pager sqs create-queue --queue-name team-a-queue

# Account 222222222222 (cannot see team-a-queue)
AWS_ACCESS_KEY_ID=222222222222 aws --endpoint-url http://localhost:4566 \
  --no-cli-pager sqs list-queues
```

Using `test` as the key (this repository's default) routes to the default account ID `000000000000`.

---

## Upgrading Floci

```bash
# CLI
floci update

# Docker Compose — update the image tag in floci/docker-compose.yml then
docker compose -f floci/docker-compose.yml pull
docker compose -f floci/docker-compose.yml up -d
```

> After upgrading, re-run `terraform apply -refresh-only` to verify no drift was introduced.

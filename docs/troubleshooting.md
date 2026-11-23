# Troubleshooting

A reference for common errors encountered in this environment, with causes and fixes.

---

## AWS CLI Pager Blocking Terminal

**Symptom:** AWS CLI output opens in `less`. Commands appear to hang or show garbled text. Subsequent commands are fed into the pager instead of executing.

**Cause:** The AWS CLI defaults to opening output in `less` when output is long.

**Fix:**

```bash
# Fix for the current session
export AWS_PAGER=""
q   # exit the pager if it's currently open (press q)

# Permanent fix — add to ~/.bashrc
echo 'export AWS_PAGER=""' >> ~/.bashrc
source ~/.bashrc
```

Always use `--no-cli-pager` on individual commands as a safety net:

```bash
aws --endpoint-url http://localhost:4566 --no-cli-pager eks list-clusters
```

If the terminal is completely stuck with no visible prompt, open a new WSL terminal window and continue from there.

---

## Terraform: "Invalid provider configuration"

**Symptom:**
```
Error: Invalid provider configuration
Provider "registry.terraform.io/hashicorp/aws" requires explicit configuration.
```

**Cause:** You ran `terraform plan` or `apply` from inside a module directory (e.g. `infrastructure/modules/s3/`). Modules do not have provider configuration.

**Fix:** Always run Terraform from an `environments/` directory:

```bash
cd infrastructure/environments/eks-local
terraform plan
```

---

## Terraform: STS GetCallerIdentity 403

**Symptom:**
```
Error: Retrieving AWS account details: validating provider credentials:
retrieving caller identity from STS: operation error STS: GetCallerIdentity,
https response error StatusCode: 403, RequestID: ..., api error InvalidClientTokenId
```

**Cause:** Terraform tried to call real AWS STS. This happens when:
1. The `skip_credentials_validation = true` setting is missing from the provider
2. Floci is not running when `terraform init` or `plan` is executed
3. The `sts` endpoint is not listed in the `endpoints {}` block

**Fix:**

```bash
# Check Floci is running
curl -s http://localhost:4566/_floci/health

# Start Floci if not running
floci start

# Verify provider.tf has these settings
grep -A5 "skip_credentials" infrastructure/environments/eks-local/provider.tf
```

---

## Floci Not Reachable

**Symptom:**
```
curl: (7) Failed to connect to localhost port 4566: Connection refused
```

**Fix:**

```bash
# Check if Floci is running
docker ps | grep floci

# Start via CLI
floci start

# Start via Docker Compose
docker compose -f floci/docker-compose.yml up -d

# Check logs if it fails to start
docker logs floci
```

---

## Port 4566 Already in Use

**Symptom:**
```
Error response from daemon: driver failed programming external connectivity:
Bind for 0.0.0.0:4566 failed: port is already allocated
```

**Find what is using the port:**

```bash
# Linux / WSL
lsof -i :4566

# Windows (run in PowerShell)
netstat -ano | findstr :4566
```

**Fix:** Stop the other process or change Floci's port in `docker-compose.yml`.

---

## Docker Container Name Conflict

**Symptom:**
```
Error response from daemon: Conflict. The container name "/floci" is already in use
```

**Cause:** A stopped container with the same name exists.

**Fix:**

```bash
docker rm floci
docker compose -f floci/docker-compose.yml up -d
```

---

## Terraform: BucketAlreadyExists

**Symptom:**
```
Error: creating S3 Bucket (floci-demo-bucket):
BucketAlreadyExists: The requested bucket name is not available
```

**Cause:** The bucket exists in Floci but Terraform's state file was deleted or lost. Terraform doesn't know it already created this bucket.

**Fix — import the existing resource:**

```bash
terraform import module.s3_bucket.aws_s3_bucket.this floci-demo-bucket
terraform plan   # should now show no changes
```

---

## Terraform State Drift

**Symptom:** `terraform plan` shows resources being created that you know already exist, or destroyed that you didn't delete.

**Cause:** A resource was created or deleted outside of Terraform (via AWS CLI, Floci UI, or manually).

**Fix:**

```bash
# Step 1: See what has changed
terraform plan -refresh-only

# Step 2: Sync Terraform's state to match reality
terraform apply -refresh-only

# Step 3: Re-create anything that is now missing
terraform apply
```

---

## Terraform: Backend S3 Connection Refused

**Symptom:**
```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```
or
```
Error: error configuring S3 Backend: no valid credential providers found
```

**Cause:** The `environments/local` environment uses a Floci-backed S3 backend. If Floci is not running when you run `terraform init`, the backend cannot be reached.

**Fix:**

```bash
# Start Floci first
floci start
curl -s http://localhost:4566/_floci/health

# If the state bucket was never created, run state-bootstrap
cd state-bootstrap
terraform init
terraform apply

# Then init the environment
cd ../infrastructure/environments/local
terraform init
```

---

## Kind: Cluster Not Responding

**Symptom:** `kubectl` commands time out or return `connection refused`.

**Fix:**

```bash
# Check cluster containers are running
docker ps | grep kind

# If containers are stopped, start them
docker start services-control-plane

# Wait for the API server to be ready
kubectl wait --for=condition=Ready node --all --timeout=60s

# If the cluster is broken, recreate it
kind delete cluster --name services
kind create cluster --name services
```

---

## Kind: Wrong kubectl Context

**Symptom:** `kubectl` commands affect the wrong cluster or return `server not found`.

**Fix:**

```bash
# List all contexts
kubectl config get-contexts

# Switch to the Kind cluster
kubectl config use-context kind-services
# or for a cluster named floci-eks:
kubectl config use-context kind-floci-eks
```

---

## WSL 2: Docker Not Running

**Symptom:** `docker: command not found` or `Cannot connect to the Docker daemon`.

**Fix:**

On Windows, ensure Docker Desktop is running and WSL 2 integration is enabled:

1. Open Docker Desktop → Settings → Resources → WSL Integration
2. Enable integration for your WSL 2 distribution
3. Click Apply & Restart

```bash
# Verify Docker works from WSL
docker info
```

---

## Terraform: Lock File Conflict

**Symptom:**
```
Error: Error acquiring the state lock
Lock Info:
  ID: ...
  Operation: OperationTypePlan
```

**Cause:** A previous Terraform operation was interrupted and the DynamoDB lock was not released.

**Fix:**

```bash
# Force-unlock using the lock ID shown in the error
terraform force-unlock <LOCK_ID>
```

---

## General Debugging Commands

```bash
# Check everything is running
docker ps
curl -s http://localhost:4566/_floci/health
floci status

# Check Terraform state
terraform state list
terraform state show <resource>

# Check AWS resources in Floci
export AWS_PAGER=""
aws --endpoint-url http://localhost:4566 --no-cli-pager ec2 describe-vpcs
aws --endpoint-url http://localhost:4566 --no-cli-pager eks list-clusters
aws --endpoint-url http://localhost:4566 --no-cli-pager iam list-roles \
  --query "Roles[?contains(RoleName,'floci')].[RoleName]" --output table

# Check Floci logs
docker logs floci --tail=50

# Check Kind cluster
kind get clusters
kubectl cluster-info
kubectl get nodes
```

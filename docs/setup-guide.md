# Setup Guide

This guide takes you from a bare machine to a fully working local DevOps lab. Follow the steps in order.

---

## Prerequisites

You need:
- A machine running Linux, macOS, or Windows with WSL 2
- At least 8 GB RAM (16 GB recommended for running Kind alongside Floci)
- Docker installed and running
- An internet connection for downloading tools and provider plugins

> **Windows users:** every command in this guide must be run inside a WSL 2 terminal, not PowerShell or Command Prompt. All file paths use Linux-style forward slashes.

---

## Step 1 — Docker

Floci and Kind both require Docker.

```bash
# Check if already installed
docker --version
docker compose version

# If not installed — Ubuntu/Debian/WSL
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow running Docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker run --rm hello-world
```

Expected output ends with: `Hello from Docker!`

---

## Step 2 — Floci

Floci is the local AWS emulator. There are two ways to run it.

### Option A — Floci CLI (recommended)

```bash
# Install
curl -fsSL https://get.floci.io | bash

# Reload your shell
source ~/.bashrc   # or ~/.zshrc

# Start Floci
floci start

# Verify
floci status
```

Expected output includes:
```
Reachable:  yes
Version:    2.x.x
```

### Option B — Docker Compose

Use this if you prefer to manage Floci as part of Docker Compose.

```bash
# From the repository root
docker compose -f floci/docker-compose.yml up -d

# Verify health
curl -s http://localhost:4566/_floci/health
```

Expected response: `{"status":"ok"}`

> You only need one method. If `floci status` shows `Reachable: yes`, you are ready.

---

## Step 3 — Terraform

```bash
# Check if already installed
terraform version

# If not installed — Ubuntu/Debian/WSL
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Verify
terraform version
# Expected: Terraform v1.6.0 or later
```

---

## Step 4 — AWS CLI

The AWS CLI is used to verify resources after Terraform apply.

```bash
# Check if already installed
aws --version

# If not installed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install

# Verify
aws --version
# Expected: aws-cli/2.x.x
```

**Important — disable the AWS CLI pager.** Without this, AWS CLI output opens in `less` and blocks your terminal:

```bash
# Add to ~/.bashrc or ~/.zshrc
export AWS_PAGER=""

# Apply immediately
source ~/.bashrc
```

---

## Step 5 — kubectl

```bash
# Check if already installed
kubectl version --client

# If not installed
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
# Expected: Client Version: v1.31.x or later
```

---

## Step 6 — Kind

Kind (Kubernetes in Docker) runs a real Kubernetes cluster inside Docker containers.

```bash
# Check if already installed
kind version

# If not installed
curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind

# Verify
kind version
# Expected: kind v0.24.0 or later
```

---

## Step 7 — Helm

Helm is the Kubernetes package manager, used for deploying ingress controllers and other components.

```bash
# Check if already installed
helm version

# If not installed
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
# Expected: version.BuildInfo{Version:"v3.x.x"}
```

---

## Step 8 — Clone the Repository

```bash
git clone <repo-url>
cd terraform-floci-infrastructure
```

---

## Step 9 — Configure Local Credentials

Copy the example environment file:

```bash
cp .env.example .env
```

The `.env` file already contains the correct dummy values for Floci — no edits are needed:

```bash
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_PAGER=""
```

Export these for your current shell session:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""
```

Or add them to your `~/.bashrc` permanently:

```bash
cat >> ~/.bashrc << 'EOF'
# Floci local AWS credentials
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""
EOF
source ~/.bashrc
```

> These credentials only work with Floci. They will be rejected by real AWS.

---

## Step 10 — Optional: AWS CLI Named Profile

Configure a named profile called `floci` so you can use shorter commands:

```bash
aws configure --profile floci
# AWS Access Key ID: test
# AWS Secret Access Key: test
# Default region name: us-east-1
# Default output format: json

aws configure set endpoint_url http://localhost:4566 --profile floci
```

Then use it like this:

```bash
aws s3 ls --profile floci
# or export it for your session
export AWS_PROFILE=floci
```

---

## Step 11 — Verify Your Setup

Run this checklist before continuing:

```bash
# Docker running
docker ps

# Floci reachable
curl -s http://localhost:4566/_floci/health
# Expected: {"status":"ok"}

# Terraform installed
terraform version

# AWS CLI installed and pager disabled
aws --version
echo "AWS_PAGER is: $AWS_PAGER"   # should be empty string

# kubectl installed
kubectl version --client

# Kind installed
kind version
```

If any of these fail, revisit the relevant step above before continuing.

---

## Next Steps

- [Provision infrastructure with Terraform →](terraform-guide.md)
- [Learn about Floci configuration →](floci-guide.md)
- [Set up a Kubernetes cluster with Kind →](kubernetes-guide.md)

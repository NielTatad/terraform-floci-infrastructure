# terraform-floci-infrastructure

Practice Terraform and AWS — **entirely on your laptop**. No AWS account. No credit card. No cloud costs.

This repo uses **[Floci](https://github.com/floci-io/floci)**, a free tool that runs a fake AWS on your machine. You write real Terraform code, it provisions real resources — they just live locally instead of in the cloud.

---

## What is this for?

If you want to learn or practice:
- How Terraform works (plan, apply, destroy, state)
- How to write reusable Terraform modules
- How AWS services like S3, DynamoDB, and SQS work
- How IaC (Infrastructure as Code) fits into a real project

...but you don't have an AWS account or don't want to pay — this is for you.

---

## What gets created?

When you run `terraform apply`, three AWS-compatible resources are provisioned locally:

| What          | AWS Service | What it does                        |
|---------------|-------------|-------------------------------------|
| A bucket      | S3          | Stores files (like Google Drive)    |
| A table       | DynamoDB    | Stores data (like a NoSQL database) |
| A queue       | SQS         | Passes messages between services    |

They all live inside Floci on your machine at `http://localhost:4566`.

---

## How it works (simple version)

```
You write Terraform code
        ↓
Terraform talks to Floci (fake AWS on your laptop)
        ↓
Floci creates the resources locally
        ↓
You can inspect them, test against them, then destroy them
```

No internet calls to real AWS. No IAM permissions. No bills.

---

## Prerequisites

You need these installed before starting:

### 1. Floci
Floci is the fake AWS that runs on your machine.

```bash
# Install via the official installer (Linux / macOS / WSL)
curl -fsSL https://get.floci.io | bash

# Start it
floci start

# Check it's running
floci status
# You should see: Reachable: yes
```

> **Windows users:** run everything inside **WSL 2** (Windows Subsystem for Linux). Open your WSL terminal and work from there.

### 2. Terraform
Terraform is the tool that reads your `.tf` files and creates resources.

```bash
# Check if already installed
terraform version

# If not installed, follow: https://developer.hashicorp.com/terraform/install
# On Ubuntu/WSL:
sudo apt-get update && sudo apt-get install -y terraform
```

### 3. AWS CLI (optional but recommended)
Used to verify that your resources were actually created.

```bash
# Check if already installed
aws --version

# Install guide: https://aws.amazon.com/cli/
```

---

## Step-by-Step Guide

### Step 1 — Clone this repo

```bash
git clone <repo-url>
cd terraform-floci-infrastructure
```

### Step 2 — Start Floci

If you installed Floci via the CLI:
```bash
floci start
floci status   # confirm it shows: Reachable: yes
```

If you prefer Docker Compose instead:
```bash
docker compose -f floci/docker-compose.yml up -d
```

> You only need **one** of the two methods above. If `floci status` shows it's running, you're good.

### Step 3 — Go to the Terraform environment folder

**Always run Terraform commands from this folder:**

```bash
cd infrastructure/environments/local
```

This is important. The modules (`infrastructure/modules/s3`, etc.) are just building blocks — they don't have provider configuration. The `local` environment folder is where everything is wired together.

### Step 4 — Initialise Terraform

This downloads the AWS provider plugin (one-time setup):

```bash
terraform init
```

You should see: `Terraform has been successfully initialized!`

### Step 5 — Preview what will be created

```bash
terraform plan
```

Terraform will show you exactly what it's going to create — without actually creating anything yet. It's like a dry run. Read through it and make sure it looks right.

You'll see three resources listed: an S3 bucket, a DynamoDB table, and an SQS queue.

### Step 6 — Create the resources

```bash
terraform apply
```

Terraform asks: `Do you want to perform these actions?`

Type `yes` and press Enter.

You should see: `Apply complete! Resources: 4 added.`

### Step 7 — Verify the resources exist

Now check that Floci actually has the resources:

```bash
# See your S3 bucket
aws --endpoint-url http://localhost:4566 s3 ls

# See your DynamoDB table
aws --endpoint-url http://localhost:4566 dynamodb list-tables

# See your SQS queue
aws --endpoint-url http://localhost:4566 sqs list-queues
```

You should see `floci-demo-bucket`, `floci-demo-table`, and `floci-demo-queue` in the output.

> **Why `--endpoint-url`?** This tells the AWS CLI to talk to Floci instead of real AWS.

---

## Credentials — why `test` / `test`?

Floci doesn't care about credentials — it accepts any non-empty value. So we use `test` as both the access key and secret key. This is intentional. These are **not** real AWS credentials and they will not work against real AWS.

The credentials are pre-configured in `provider.tf` so you don't need to do anything.

---

## Useful Terraform Commands

Run these from `infrastructure/environments/local`:

```bash
# See what's currently managed by Terraform
terraform state list

# Preview changes without applying
terraform plan

# Apply only one resource (e.g. just S3)
terraform apply -target=module.s3_bucket

# Destroy only one resource
terraform destroy -target=module.s3_bucket

# Destroy everything
terraform destroy

# Check if anything changed outside of Terraform (drift detection)
terraform plan -refresh-only
```

---

## Trying things out — hands-on examples

Once resources are applied, try these to see the services in action:

**Upload a file to S3:**
```bash
aws --endpoint-url http://localhost:4566 s3 cp README.md s3://floci-demo-bucket/test.md
aws --endpoint-url http://localhost:4566 s3 ls s3://floci-demo-bucket
```

**Write and read a DynamoDB item:**
```bash
aws --endpoint-url http://localhost:4566 dynamodb put-item \
  --table-name floci-demo-table \
  --item '{"id": {"S": "item-1"}, "value": {"S": "hello world"}}'

aws --endpoint-url http://localhost:4566 dynamodb get-item \
  --table-name floci-demo-table \
  --key '{"id": {"S": "item-1"}}'
```

**Send and receive an SQS message:**
```bash
# Get the queue URL first
QUEUE_URL=$(aws --endpoint-url http://localhost:4566 sqs get-queue-url \
  --queue-name floci-demo-queue --query QueueUrl --output text)

# Send a message
aws --endpoint-url http://localhost:4566 sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "hello from floci"

# Receive the message
aws --endpoint-url http://localhost:4566 sqs receive-message \
  --queue-url "$QUEUE_URL"
```

---

## The Web Console (visual UI)

Floci has a browser UI where you can see all your resources visually:

```
http://localhost:4566/_floci/ui
```

Open that in your browser after applying. You'll see the S3 bucket, DynamoDB table, and SQS queue listed there.

> **Tip:** Use the UI to *look* at resources, not to delete them. If you delete something through the UI, Terraform's state file won't know about it and things can get out of sync. Always delete through Terraform.

---

## Understanding Terraform State

Terraform keeps a file called `terraform.tfstate` that tracks everything it has created. Think of it as Terraform's memory.

- It lives in `infrastructure/environments/local/terraform.tfstate`
- It is **excluded from Git** (see `.gitignore`) — never commit it
- If you delete a resource in Floci manually (via UI or CLI), Terraform still thinks it exists — this is called **drift**

**How to detect drift:**
```bash
terraform plan -refresh-only
# If nothing changed: "No changes. Your infrastructure matches the configuration."
# If something is missing: it will show what drifted
```

**How to fix drift:**
```bash
terraform apply -refresh-only   # update Terraform's memory to match reality
terraform apply                 # re-create anything that's now missing
```

---

## Stopping Floci

```bash
# If you used the CLI
floci stop

# If you used Docker Compose
docker compose -f floci/docker-compose.yml down
```

Floci saves its state to `floci/data/` so your resources will still be there when you start it again.

To completely reset (wipe all Floci data):
```bash
docker compose -f floci/docker-compose.yml down -v
rm -rf floci/data/
```

---

## Understanding the Folder Structure

```
terraform-floci-infrastructure/
│
├── infrastructure/
│   ├── modules/              ← Building blocks (reusable Terraform code)
│   │   ├── s3/               ← "How to create an S3 bucket"
│   │   ├── dynamodb/         ← "How to create a DynamoDB table"
│   │   └── sqs/              ← "How to create an SQS queue"
│   │
│   └── environments/
│       └── local/            ← THIS is where you run Terraform from
│           ├── provider.tf   ← Tells Terraform to use Floci instead of real AWS
│           ├── main.tf       ← Calls the modules above
│           ├── variables.tf  ← Settings you can change (bucket name, etc.)
│           └── outputs.tf    ← Values printed after apply (ARNs, URLs, etc.)
│
├── floci/
│   └── docker-compose.yml    ← Alternative way to start Floci
│
├── scripts/                  ← Shortcut scripts (init, plan, apply, destroy, status)
└── .env.example              ← Copy to .env if using the scripts
```

The key idea: **modules define resources, environments use them**. You never run `terraform apply` from inside a module folder.

---

## Adding a New AWS Service

Want to add SNS (notifications)? Here's the pattern:

1. Create `infrastructure/modules/sns/` with `main.tf`, `variables.tf`, `outputs.tf`
2. Call it from `infrastructure/environments/local/main.tf`
3. Add `sns = var.floci_endpoint` to the `endpoints {}` block in `provider.tf`
4. Run `terraform init` then `terraform apply`

Floci supports 45+ AWS services. Check the [full list here](https://github.com/floci-io/floci/blob/main/README.md#supported-services).

---

## Troubleshooting

**"Invalid provider configuration" or STS error**
You're running `terraform` from inside a module folder. Move to the environment folder:
```bash
cd infrastructure/environments/local
terraform plan
```

**"BucketAlreadyExists" on apply**
The bucket exists in Floci but Terraform doesn't know about it (state was lost). Import it:
```bash
terraform import module.s3_bucket.aws_s3_bucket.this floci-demo-bucket
```

**"Port 4566 already in use"**
Something else is using that port. Find it:
```bash
lsof -i :4566        # macOS / Linux
netstat -ano | grep 4566   # Windows / WSL
```

**Floci not reachable**
```bash
floci status         # check if it's running
floci start          # start it if not
```

**Changes not showing after modifying `.tf` files**
Run `terraform plan` to see the diff. Terraform only applies changes when you run `apply`.

---

## Known Limitations

- Floci is a local emulator — it doesn't simulate network latency or AWS service quotas
- IAM permissions are not enforced by default (all actions are allowed)
- Resources only exist on your machine — other people on your team have their own separate Floci instances
- Some advanced AWS features (CloudFront routing, Route53 DNS resolution) are stubs only

---

## References

- [Floci docs](https://github.com/floci-io/floci)
- [Terraform AWS provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform language guide](https://developer.hashicorp.com/terraform/language)

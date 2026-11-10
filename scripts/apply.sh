#!/usr/bin/env bash
# apply.sh — Apply the Terraform configuration against Floci.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FLOCI_DIR="${REPO_ROOT}/floci"
TF_DIR="${REPO_ROOT}/infrastructure/environments/local"
ENV_FILE="${REPO_ROOT}/.env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[apply] $*"; }
ok()   { echo "[apply] ✓ $*"; }
err()  { echo "[apply] ✗ $*" >&2; }
die()  { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
command -v docker    >/dev/null 2>&1 || die "docker is not installed or not on PATH."
command -v terraform >/dev/null 2>&1 || die "terraform is not installed or not on PATH."

# ---------------------------------------------------------------------------
# Load credentials
# ---------------------------------------------------------------------------
if [[ -f "${ENV_FILE}" ]]; then
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
else
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
  export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
fi

# ---------------------------------------------------------------------------
# Verify Floci is running and healthy
# ---------------------------------------------------------------------------
log "Checking Floci health..."
FLOCI_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"

if ! curl -sf "${FLOCI_URL}/_floci/health" >/dev/null 2>&1; then
  die "Floci is not reachable at ${FLOCI_URL}. Run ./scripts/init.sh first."
fi
ok "Floci is healthy."

# Check that the Terraform working directory is initialised.
if [[ ! -d "${TF_DIR}/.terraform" ]]; then
  die "Terraform is not initialised. Run ./scripts/init.sh first."
fi

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------
log "Applying Terraform configuration..."
terraform -chdir="${TF_DIR}" apply -auto-approve

ok "Apply complete. Resources are now provisioned in Floci."
log "Verify with: aws --endpoint-url ${FLOCI_URL} s3 ls"

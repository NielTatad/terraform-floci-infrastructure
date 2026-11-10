#!/usr/bin/env bash
# destroy.sh — Destroy all Terraform-managed resources and optionally stop Floci.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FLOCI_DIR="${REPO_ROOT}/floci"
TF_DIR="${REPO_ROOT}/infrastructure/environments/local"
ENV_FILE="${REPO_ROOT}/.env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[destroy] $*"; }
ok()   { echo "[destroy] ✓ $*"; }
err()  { echo "[destroy] ✗ $*" >&2; }
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
# Confirmation prompt — do not destroy without explicit consent.
# ---------------------------------------------------------------------------
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  WARNING: This will DESTROY all Terraform-managed       │"
echo "  │  resources in the local Floci environment.              │"
echo "  │  This action cannot be undone once complete.            │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
read -r -p "  Type 'yes' to confirm destruction: " CONFIRM
echo ""

if [[ "${CONFIRM}" != "yes" ]]; then
  log "Destruction cancelled."
  exit 0
fi

# ---------------------------------------------------------------------------
# Destroy Terraform resources
# ---------------------------------------------------------------------------
log "Destroying Terraform-managed resources..."
terraform -chdir="${TF_DIR}" destroy -auto-approve
ok "Terraform resources destroyed."

# ---------------------------------------------------------------------------
# Optionally stop Floci
# ---------------------------------------------------------------------------
read -r -p "[destroy] Stop the Floci container as well? (y/N): " STOP_FLOCI
echo ""

if [[ "${STOP_FLOCI}" =~ ^[Yy]$ ]]; then
  log "Stopping Floci..."
  docker compose -f "${FLOCI_DIR}/docker-compose.yml" down
  ok "Floci stopped."
  log "Persisted state in floci/data/ was preserved. Remove it manually to reset completely."
else
  log "Floci container left running."
fi

ok "Done."

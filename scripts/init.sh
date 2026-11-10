#!/usr/bin/env bash
# init.sh — Start Floci and initialise Terraform for the local environment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FLOCI_DIR="${REPO_ROOT}/floci"
TF_DIR="${REPO_ROOT}/infrastructure/environments/local"
ENV_FILE="${REPO_ROOT}/.env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[init] $*"; }
ok()   { echo "[init] ✓ $*"; }
err()  { echo "[init] ✗ $*" >&2; }
die()  { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
log "Checking dependencies..."

command -v docker    >/dev/null 2>&1 || die "docker is not installed or not on PATH."
command -v terraform >/dev/null 2>&1 || die "terraform is not installed or not on PATH."
ok "docker and terraform found."

# ---------------------------------------------------------------------------
# Load local credentials from .env if present
# ---------------------------------------------------------------------------
if [[ -f "${ENV_FILE}" ]]; then
  log "Loading credentials from .env..."
  # Export only lines that look like KEY=VALUE; skip comments and blank lines.
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
  ok "Credentials loaded."
else
  log ".env not found — using defaults (AWS_ACCESS_KEY_ID=test, etc.)."
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
  export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
fi

# ---------------------------------------------------------------------------
# Start Floci via Docker Compose
# ---------------------------------------------------------------------------
log "Starting Floci..."
docker compose -f "${FLOCI_DIR}/docker-compose.yml" up -d

# Wait for the health endpoint to respond.
log "Waiting for Floci to become healthy..."
FLOCI_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
MAX_WAIT=60   # seconds
ELAPSED=0
INTERVAL=3

until curl -sf "${FLOCI_URL}/_floci/health" >/dev/null 2>&1; do
  if (( ELAPSED >= MAX_WAIT )); then
    die "Floci did not become healthy within ${MAX_WAIT}s. Check: docker compose -f floci/docker-compose.yml logs floci"
  fi
  sleep "${INTERVAL}"
  ELAPSED=$(( ELAPSED + INTERVAL ))
  log "Still waiting... (${ELAPSED}s elapsed)"
done
ok "Floci is healthy at ${FLOCI_URL}"

# ---------------------------------------------------------------------------
# Terraform init
# ---------------------------------------------------------------------------
log "Initialising Terraform..."
terraform -chdir="${TF_DIR}" init -upgrade

ok "Done. Run ./scripts/plan.sh to preview changes."

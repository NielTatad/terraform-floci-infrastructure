#!/usr/bin/env bash
# status.sh — Show the current state of Floci and Terraform resources.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FLOCI_DIR="${REPO_ROOT}/floci"
TF_DIR="${REPO_ROOT}/infrastructure/environments/local"
ENV_FILE="${REPO_ROOT}/.env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()     { echo "[status] $*"; }
header()  { echo ""; echo "━━━ $* ━━━"; }

# ---------------------------------------------------------------------------
# Load credentials (needed for Terraform state read)
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

FLOCI_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"

# ---------------------------------------------------------------------------
# Docker container status
# ---------------------------------------------------------------------------
header "Floci container"
if command -v docker >/dev/null 2>&1; then
  CONTAINER_STATUS=$(docker compose -f "${FLOCI_DIR}/docker-compose.yml" ps 2>/dev/null || echo "(docker compose not available)")
  echo "${CONTAINER_STATUS}"
else
  log "docker not found — skipping container status."
fi

# ---------------------------------------------------------------------------
# Floci health endpoint
# ---------------------------------------------------------------------------
header "Floci health (${FLOCI_URL})"
if curl -sf "${FLOCI_URL}/_floci/health" >/dev/null 2>&1; then
  echo "  Status : HEALTHY"
  echo "  Endpoint: ${FLOCI_URL}"
  echo "  Web UI  : ${FLOCI_URL}/_floci/ui"
else
  echo "  Status : UNREACHABLE"
  echo "  Run ./scripts/init.sh to start Floci."
fi

# ---------------------------------------------------------------------------
# Terraform state
# ---------------------------------------------------------------------------
header "Terraform state (${TF_DIR})"
if command -v terraform >/dev/null 2>&1; then
  if [[ -d "${TF_DIR}/.terraform" ]]; then
    echo "  Terraform is initialised."
    if [[ -f "${TF_DIR}/terraform.tfstate" ]]; then
      RESOURCE_COUNT=$(terraform -chdir="${TF_DIR}" state list 2>/dev/null | wc -l | tr -d ' ')
      echo "  Managed resources: ${RESOURCE_COUNT}"
      echo ""
      terraform -chdir="${TF_DIR}" state list 2>/dev/null | sed 's/^/  /' || true
    else
      echo "  No state file found — run ./scripts/apply.sh to provision resources."
    fi
  else
    echo "  Terraform is not initialised. Run ./scripts/init.sh first."
  fi
else
  log "terraform not found — skipping state status."
fi

echo ""

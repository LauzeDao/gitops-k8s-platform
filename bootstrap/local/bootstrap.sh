#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CLUSTER_NAME="${CLUSTER_NAME:-gitops-local}"
KIND_CONFIG="${KIND_CONFIG:-${SCRIPT_DIR}/kind-config.yaml}"
AGE_KEY_FILE="${AGE_KEY_FILE:-${SCRIPT_DIR}/age.key}"
FLUX_VERSION="${FLUX_VERSION:-2.8.8}"
FLUX_NAMESPACE="flux-system"
CLUSTER_ENTRYPOINT="${REPO_ROOT}/clusters/local/flux-system"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

for bin in docker kind kubectl flux; do
  command -v "${bin}" >/dev/null 2>&1 || die "required tool '${bin}' not found in PATH"
done

if [[ ! -f "${AGE_KEY_FILE}" ]]; then
  die "age key not found at '${AGE_KEY_FILE}'.
       A throwaway DEMO key normally ships in the repo at this path. If it is
       missing, generate one:  age-keygen -o '${AGE_KEY_FILE}'
       then re-encrypt secrets (see bootstrap/local/age.key.example)."
fi

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  log "kind cluster '${CLUSTER_NAME}' already exists — skipping create."
else
  log "Creating kind cluster '${CLUSTER_NAME}' from ${KIND_CONFIG}"
  kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}" --wait 120s
fi

KUBE_CONTEXT="kind-${CLUSTER_NAME}"
kubectl config use-context "${KUBE_CONTEXT}" >/dev/null

log "Installing Flux ${FLUX_VERSION} (idempotent)"
flux install \
  --version="v${FLUX_VERSION}" \
  --namespace="${FLUX_NAMESPACE}" \
  --context="${KUBE_CONTEXT}" \
  --network-policy=true \
  --components-extra=image-reflector-controller,image-automation-controller

log "Loading age key into Secret '${FLUX_NAMESPACE}/sops-age' (key age.agekey)"
kubectl create secret generic sops-age \
  --namespace="${FLUX_NAMESPACE}" \
  --from-file=age.agekey="${AGE_KEY_FILE}" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Applying clusters/local entrypoint (GitRepository + root Kustomization)"
kubectl apply -k "${CLUSTER_ENTRYPOINT}"

log "Bootstrap complete. Watch reconciliation with:"
echo "    flux get sources git -A"
echo "    flux get kustomizations -A"

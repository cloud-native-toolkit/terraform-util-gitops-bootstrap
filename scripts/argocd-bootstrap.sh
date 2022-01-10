#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

ARGOCD_HOST="$1"
ARGOCD_USER="$2"
ARGOCD_NAMESPACE="$3"
GIT_REPO="$4"
GIT_USER="$5"
BOOTSTRAP_PATH="$6"
PREFIX="$7"

if [[ -z "${ARGOCD_HOST}" ]] || [[ -z "${ARGOCD_USER}" ]] || [[ -z "${ARGOCD_NAMESPACE}" ]] || [[ -z "${GIT_REPO}" ]] || [[ -z "${GIT_USER}" ]] || [[ -z "${BOOTSTRAP_PATH}" ]]; then
  echo "Usage: argocd-bootstrap.sh ARGOCD_HOST ARGOCD_USER ARGOCD_NAMESPACE GIT_REPO GIT_USER BOOTSTRAP_PATH"
  exit 1
fi

if [[ -z "${ARGOCD_PASSWORD}" ]] || [[ -z "${GIT_TOKEN}" ]]; then
  echo "ARGOCD_PASSWORD and GIT_TOKEN must be provided as environment variables"
  exit 1
fi

ARGOCD=$(command -v argocd || command -v "${BIN_DIR}/argocd")

if [[ -z "${ARGOCD}" ]]; then
  echo "ArgoCD cli not found"
  exit 1
fi

echo "Logging into argocd: ${ARGOCD_HOST}"
${ARGOCD} login "${ARGOCD_HOST}" --username "${ARGOCD_USER}" --password "${ARGOCD_PASSWORD}" --insecure --grpc-web

echo "Registering git repo: ${GIT_REPO}"
${ARGOCD} repo add "${GIT_REPO}" --username "${GIT_USER}" --password "${GIT_TOKEN}" --upsert

PROJECT_NAME="0-bootstrap"
BOOTSTRAP_APP_NAME="0-bootstrap"
if [[ -n "${PREFIX}" ]]; then
  BOOTSTRAP_APP_NAME="${PREFIX}-${BOOTSTRAP_APP_NAME}"
fi

echo "Creating bootstrap project"
${ARGOCD} proj create "${PROJECT_NAME}" \
  -d "https://kubernetes.default.svc,${ARGOCD_NAMESPACE}" \
  -s "${GIT_REPO}" \
  --description "Bootstrap project resources" \
  --upsert

echo "Creating bootstrap application"
${ARGOCD} app create "${BOOTSTRAP_APP_NAME}" \
  --project "${PROJECT_NAME}" \
  --repo "${GIT_REPO}" \
  --path "${BOOTSTRAP_PATH}" \
  --helm-set "global.prefix=${PREFIX}" \
  --dest-namespace "${ARGOCD_NAMESPACE}" \
  --dest-server "https://kubernetes.default.svc" \
  --sync-policy auto \
  --self-heal \
  --auto-prune \
  --upsert

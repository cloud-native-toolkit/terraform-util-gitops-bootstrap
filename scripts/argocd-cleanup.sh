#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

ARGOCD_HOST="$1"
ARGOCD_USER="$2"
GIT_REPO="$3"
PREFIX="$4"

if [[ -z "${ARGOCD_HOST}" ]] || [[ -z "${ARGOCD_USER}" ]] || [[ -z "${GIT_REPO}" ]]; then
  echo "Usage: argocd-bootstrap.sh ARGOCD_HOST ARGOCD_USER GIT_REPO"
  exit 1
fi

if [[ -z "${ARGOCD_PASSWORD}" ]]; then
  echo "ARGOCD_PASSWORD must be provided as environment variable"
  exit 1
fi

ARGOCD=$(command -v argocd || command -v "${BIN_DIR}/argocd")

if [[ -z "${ARGOCD}" ]]; then
  echo "ArgoCD cli not found"
  exit 1
fi

echo "Logging into argocd: ${ARGOCD_HOST}"
${ARGOCD} login "${ARGOCD_HOST}" --username "${ARGOCD_USER}" --password "${ARGOCD_PASSWORD}" --insecure --grpc-web

LABEL="gitops-bootstrap"
PROJECT_NAME="0-bootstrap"
BOOTSTRAP_APP_NAME="0-bootstrap"
if [[ -n "${PREFIX}" ]]; then
  BOOTSTRAP_APP_NAME="${PREFIX}-${BOOTSTRAP_APP_NAME}"
  LABEL="${PREFIX}-${LABEL}"
fi

echo "Sleeping for 1 minute to allow gitops changes to be pushed"
sleep 60

echo "Syncing app"
${ARGOCD} app sync -l "app.kubernetes.io/part-of=${LABEL}"

echo "Sleeping for 1 minute to allow changes to be applied"
sleep 60

set -e

echo "Logging into argocd: ${ARGOCD_HOST}"
${ARGOCD} login "${ARGOCD_HOST}" --username "${ARGOCD_USER}" --password "${ARGOCD_PASSWORD}" --insecure --grpc-web

echo "Deleting bootstrap application"
${ARGOCD} app delete "${BOOTSTRAP_APP_NAME}" -y -p background

set +e

echo "Deleting bootstrap project"
${ARGOCD} proj delete "${PROJECT_NAME}"

echo "Removing git repo: ${GIT_REPO}"
${ARGOCD} repo rm "${GIT_REPO}" || echo "Failed to remove repo"

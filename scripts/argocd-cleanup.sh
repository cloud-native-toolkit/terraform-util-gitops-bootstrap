#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

ARGOCD_HOST="$1"
ARGOCD_USER="$2"
ARGOCD_NAMESPACE="$3"
GIT_REPO="$4"
PREFIX="$5"

if [[ -z "${ARGOCD_HOST}" ]] || [[ -z "${ARGOCD_USER}" ]] || [[ -z "${GIT_REPO}" ]]; then
  echo "Usage: argocd-bootstrap.sh ARGOCD_HOST ARGOCD_USER GIT_REPO"
  exit 1
fi

if [[ -z "${ARGOCD_PASSWORD}" ]]; then
  echo "ARGOCD_PASSWORD must be provided as environment variable"
  exit 1
fi

export PATH="${BIN_DIR}:${PATH}"

if ! command -v argocd 1> /dev/null 2> /dev/null; then
  echo "ArgoCD cli not found"
  exit 1
fi

echo "Logging into argocd: ${ARGOCD_HOST}"
argocd login "${ARGOCD_HOST}" --username "${ARGOCD_USER}" --password "${ARGOCD_PASSWORD}" --insecure --grpc-web

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
argocd app sync -l "app.kubernetes.io/part-of=${LABEL}"

echo "Sleeping for 1 minute to allow changes to be applied"
sleep 60

if [[ "${DELETE_APP}" != "false" ]]; then
  echo "Deleting bootstrap application - ${BOOTSTRAP_APP_NAME}"
  oc delete application "${BOOTSTRAP_APP_NAME}" -n "${ARGOCD_NAMESPACE}"

  echo "Deleting bootstrap project - ${PROJECT_NAME}"
  oc delete appproject "${PROJECT_NAME}" -n "${ARGOCD_NAMESPACE}"
fi

ORG_NAME=$(echo "${GIT_REPO}" | sed -E 's~https?://[^/]+/([^/]+)/.*~\1~g' | sed "s/_/-/g" | tr '[:upper:]' '[:lower:]')
REPO_NAME=$(echo "${GIT_REPO}" | sed -E 's~https?://[^/]+/[^/]+/(.*)~\1~g' | sed "s/_/-/g" | tr '[:upper:]' '[:lower:]')

SECRET_NAME=$(echo "repo-${ORG_NAME}-${REPO_NAME}" | cut -c1-63)

oc delete secret "${SECRET_NAME}" -n "${ARGOCD_NAMESPACE}"

echo "Done..."

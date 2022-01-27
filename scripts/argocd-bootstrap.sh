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

LABEL="gitops-bootstrap"
PROJECT_NAME="0-bootstrap"
BOOTSTRAP_APP_NAME="0-bootstrap"
if [[ -n "${PREFIX}" ]]; then
  BOOTSTRAP_APP_NAME="${PREFIX}-${BOOTSTRAP_APP_NAME}"
  LABEL="${PREFIX}-${LABEL}"
fi

echo "Creating bootstrap project and bootstrap application"
oc apply -f - << EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ${PROJECT_NAME}
  namespace: ${ARGOCD_NAMESPACE}
spec:
  destinations:
  - namespace: ${ARGOCD_NAMESPACE}
    server: https://kubernetes.default.svc
  sourceRepos:
  - ${GIT_REPO}
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${BOOTSTRAP_APP_NAME}
  namespace: ${ARGOCD_NAMESPACE}
spec:
  destination:
    namespace: ${ARGOCD_NAMESPACE}
    server: https://kubernetes.default.svc
  project: ${PROJECT_NAME}
  source:
    helm:
      parameters:
      - name: global.prefix
        value: ${PREFIX}
      - name: global.groupLabel
        value: ${LABEL}
    path: ${BOOTSTRAP_PATH}
    repoURL: ${GIT_REPO}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

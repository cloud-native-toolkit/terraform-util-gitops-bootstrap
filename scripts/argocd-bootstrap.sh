#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

ARGOCD_HOST="$1"
ARGOCD_USER="$2"
ARGOCD_NAMESPACE="$3"
GIT_REPO="$4"
GIT_USER="$5"
BOOTSTRAP_PATH="$6"
BRANCH="$7"
PREFIX="$8"

if [[ -z "${ARGOCD_HOST}" ]] || [[ -z "${ARGOCD_USER}" ]] || [[ -z "${ARGOCD_NAMESPACE}" ]] || [[ -z "${GIT_REPO}" ]] || [[ -z "${GIT_USER}" ]] || [[ -z "${BOOTSTRAP_PATH}" ]]; then
  echo "Usage: argocd-bootstrap.sh ARGOCD_HOST ARGOCD_USER ARGOCD_NAMESPACE GIT_REPO GIT_USER BOOTSTRAP_PATH"
  exit 1
fi

if [[ -z "${ARGOCD_PASSWORD}" ]] || [[ -z "${GIT_TOKEN}" ]]; then
  echo "ARGOCD_PASSWORD and GIT_TOKEN must be provided as environment variables"
  exit 1
fi

export PATH="${BIN_DIR}:${PATH}"

if ! command -v argocd 1> /dev/null 2> /dev/null; then
  echo "ArgoCD cli not found"
  exit 1
fi

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found"
  exit 1
fi

count=0
while [[ $(curl -s -o /dev/null -w "%{http_code}" "https://${ARGOCD_HOST}") == "404" ]] && [[ $count -lt 20 ]]; do
  echo "Waiting for ArgoCD SSL route to be ready"
  count=$((count + 1))
  sleep 30
done

ORG_NAME=$(echo "${GIT_REPO}" | sed -E 's~https?://[^/]+/([^/]+)/.*~\1~g' | sed "s/_/-/g" | tr '[:upper:]' '[:lower:]')
REPO_NAME=$(echo "${GIT_REPO}" | sed -E 's~https?://[^/]+/[^/]+/(.*)~\1~g' | sed "s/_/-/g" | tr '[:upper:]' '[:lower:]')

SECRET_NAME=$(echo "repo-${ORG_NAME}-${REPO_NAME}" | cut -c1-63)

oc apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${ARGOCD_NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${GIT_REPO}
  username: ${GIT_USER}
  password: ${GIT_TOKEN}
EOF

if [[ -n "${GIT_CA_CERT}" ]]; then
  GIT_HOST=$(echo "${GIT_REPO}" | sed -E "s~^https?://~~g" | sed -E "s~([^/]+)/.*~\1~g")

  echo "${GIT_CA_CERT}" | base64 -d | argocd cert add-tls "${GIT_HOST}"
fi

echo "Registering git repo: ${GIT_REPO}"
argocd repo add "${GIT_REPO}" --username "${GIT_USER}" --password "${GIT_TOKEN}" --upsert

LABEL="gitops-bootstrap"
PROJECT_NAME="0-bootstrap"
BOOTSTRAP_APP_NAME="0-bootstrap"
if [[ -n "${PREFIX}" ]]; then
  BOOTSTRAP_APP_NAME="${PREFIX}-${BOOTSTRAP_APP_NAME}"
  LABEL="${PREFIX}-${LABEL}"
fi

FINALIZERS=""
if [[ "${CASCADING_DELETE}" == "true" ]]; then
  FINALIZERS="finalizers: ['resources-finalizer.argocd.argoproj.io']"
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
  ${FINALIZERS}
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
    targetRevision: ${BRANCH}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

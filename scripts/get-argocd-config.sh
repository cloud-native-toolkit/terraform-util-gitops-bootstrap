#!/usr/bin/env bash

NAMESPACE="$1"
OUTPUT_FILE="$2"

OUTPUT_DIR=$(dirname "${OUTPUT_FILE}")
mkdir -p "${OUTPUT_DIR}"

ROUTE_NAME="openshift-gitops-server"
SECRET_NAME="openshift-gitops-cluster"

if ! kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}"; then
  echo "Unable to find route: ${NAMESPACE}/${ROUTE_NAME}"
  exit 1
fi

echo "Getting route from ${NAMESPACE}/${ROUTE_NAME}"
HOST=$(kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.spec.host')
USER="admin"

if ! kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}"; then
  echo "Unable to find secret: ${NAMESPACE}/${SECRET_NAME}"
  exit 1
fi

echo "Getting password from ${NAMESPACE}/${SECRET_NAME}"
PASSWORD=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.data["admin.password"]' | base64 -d)

echo '{}' | "${BIN_DIR}/jq" \
  --arg HOST "${HOST}" \
  --arg USER "${USER}" \
  --arg PASSWORD "${PASSWORD}" \
  '{"host": $HOST, "user": $USER, "password": $PASSWORD}' > "${OUTPUT_FILE}"

echo "Found argocd config"
cat "${OUTPUT_FILE}"

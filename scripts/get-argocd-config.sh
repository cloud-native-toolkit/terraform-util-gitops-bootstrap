#!/usr/bin/env bash

NAMESPACE="$1"
OUTPUT_FILE="$2"

OUTPUT_DIR=$(dirname "${OUTPUT_FILE}")
mkdir -p "${OUTPUT_DIR}"

HOST=$(kubectl get route openshift-gitops-server -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.spec.host')
USER="admin"
PASSWORD=$(kubectl get secret openshift-gitops-cluster -o json | "${BIN_DIR}/jq" -r '.data["admin.password"]' | base64 -d)

echo '{}' | "${BIN_DIR}/jq" \
  --arg HOST "${HOST}" \
  --arg USER "${USER}" \
  --arg PASSWORD "${PASSWORD}" \
  '{"host": $HOST, "user": $USER, "password": $PASSWORD}' > "${OUTPUT_FILE}"

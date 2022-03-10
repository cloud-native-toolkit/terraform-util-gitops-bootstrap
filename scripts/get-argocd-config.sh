#!/usr/bin/env bash

INPUT=$(tee)

export KUBECONFIG=$(echo "${INPUT}" | grep "kube_config" | sed -E 's/.*"kube_config": ?"([^"]*)".*/\1/g')
NAMESPACE=$(echo "${INPUT}" | grep "namespace" | sed -E 's/.*"namespace": ?"([^"]*)".*/\1/g')
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

ROUTE_NAME="openshift-gitops-server"
SECRET_NAME="openshift-gitops-cluster"

if ! ${BIN_DIR}/kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"status\": \"error\", \"message\": \"Unable to find route: ${NAMESPACE}/${ROUTE_NAME}\"}"
  exit 1
fi

HOST=$(${BIN_DIR}/kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.spec.host')
USER="admin"

if ! ${BIN_DIR}/kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"status\": \"error\", \"message\": \"Unable to find secret: ${NAMESPACE}/${SECRET_NAME}\"}"
  exit 1
fi

PASSWORD=$(${BIN_DIR}/kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.data["admin.password"]' | base64 -d)

echo '{}' | "${BIN_DIR}/jq" \
  --arg HOST "${HOST}" \
  --arg USER "${USER}" \
  --arg PASSWORD "${PASSWORD}" \
  '{"host": $HOST, "user": $USER, "password": $PASSWORD}'

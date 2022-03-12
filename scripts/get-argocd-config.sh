#!/usr/bin/env bash

INPUT=$(tee)

export KUBECONFIG=$(echo "${INPUT}" | grep "kube_config" | sed -E 's/.*"kube_config": ?"([^"]*)".*/\1/g')
NAMESPACE=$(echo "${INPUT}" | grep "namespace" | sed -E 's/.*"namespace": ?"([^"]*)".*/\1/g')
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

ROUTE_NAME="openshift-gitops-server"
SECRET_NAME="openshift-gitops-cluster"

export PATH="${BIN_DIR}:${PATH}"

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

if ! kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"status\": \"error\", \"message\": \"Unable to find route: ${NAMESPACE}/${ROUTE_NAME}\"}"
  exit 1
fi

HOST=$(kubectl get route "${ROUTE_NAME}" -n "${NAMESPACE}" -o json | jq -r '.spec.host')
USER="admin"

if ! kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"status\": \"error\", \"message\": \"Unable to find secret: ${NAMESPACE}/${SECRET_NAME}\"}"
  exit 1
fi

PASSWORD=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o json | jq -r '.data["admin.password"]' | base64 -d)

echo '{}' | jq \
  --arg HOST "${HOST}" \
  --arg USER "${USER}" \
  --arg PASSWORD "${PASSWORD}" \
  '{"host": $HOST, "user": $USER, "password": $PASSWORD}'

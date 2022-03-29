#!/usr/bin/env bash

INPUT=$(tee)

export KUBECONFIG=$(echo "${INPUT}" | grep "kube_config" | sed -E 's/.*"kube_config": ?"([^"]*)".*/\1/g')
NAMESPACE=$(echo "${INPUT}" | grep "namespace" | sed -E 's/.*"namespace": ?"([^"]*)".*/\1/g')
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

ROUTE_NAME="openshift-gitops-server"
SECRET_NAME="openshift-gitops-cluster"

export PATH="${BIN_DIR}:${PATH}"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

if ! oc get route "${ROUTE_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"host\": \"\", \"user\": \"\", \"password\":\"\", \"status\": \"error\", \"message\": \"Unable to find route: ${NAMESPACE}/${ROUTE_NAME}\"}"
  exit 0
fi

HOST=$(oc get route "${ROUTE_NAME}" -n "${NAMESPACE}" -o json | jq -r '.spec.host')
USER="admin"

if ! oc get secret "${SECRET_NAME}" -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "{\"host\": \"\", \"user\": \"\", \"password\":\"\", \"status\": \"error\", \"message\": \"Unable to find secret: ${NAMESPACE}/${SECRET_NAME}\"}"
  exit 0
fi

PASSWORD=$(oc get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o json | jq -r '.data["admin.password"]')

echo '{}' | jq \
  --arg HOST "${HOST}" \
  --arg USER "${USER}" \
  --arg PASSWORD "${PASSWORD}" \
  '{"host": $HOST, "user": $USER, "password": $PASSWORD | @base64d}'

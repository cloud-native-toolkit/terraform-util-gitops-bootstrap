#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"

export PATH="${BIN_DIR}:${PATH}"

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found"
  exit 1
fi

if kubectl get secret -n "${NAMESPACE}" "${SECRET_NAME}"; then
  kubectl delete secret -n "${NAMESPACE}" "${SECRET_NAME}"
else
  echo "Secret ${NAMESPACE}/${SECRET_NAME} not found"
fi

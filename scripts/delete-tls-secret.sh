#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"

if ${BIN_DIR}/kubectl get secret -n "${NAMESPACE}" "${SECRET_NAME}"; then
  ${BIN_DIR}/kubectl delete secret -n "${NAMESPACE}" "${SECRET_NAME}"
else
  echo "Secret ${NAMESPACE}/${SECRET_NAME} not found"
fi

#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"

export PATH="${BIN_DIR}:${PATH}"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found"
  exit 1
fi

if oc get secret -n "${NAMESPACE}" "${SECRET_NAME}"; then
  oc delete secret -n "${NAMESPACE}" "${SECRET_NAME}"
else
  echo "Secret ${NAMESPACE}/${SECRET_NAME} not found"
fi

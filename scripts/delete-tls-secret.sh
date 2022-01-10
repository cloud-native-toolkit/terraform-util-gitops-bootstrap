#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"

if kubectl get secret -n "${NAMESPACE}" "${SECRET_NAME}"; then
  kubectl delete secret -n "${NAMESPACE}" "${SECRET_NAME}"
else
  echo "Secret ${NAMESPACE}/${SECRET_NAME} not found"
fi

#!/usr/bin/env bash

ARGOCD_HOST="$1"
GIT_URL="$2"

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ -z "${ARGOCD_HOST}" ]] || [[ -z "${GIT_URL}" ]]; then
  echo "usage: argocd-webhook.sh ARGOCD_HOST GIT_URL"
  exit 1
fi

if [[ -z "${GIT_USERNAME}" ]] || [[ -z "${GIT_TOKEN}" ]]; then
  echo "GIT_USERNAME and GIT_TOKEN must be provided as an environment variable"
  exit 1
fi

if ! command -v gitu 1> /dev/null 2> /dev/null; then
  echo "gitu cli not found" >&2
  exit 1
fi

WEBHOOK_URL="https://${ARGOCD_HOST}/api/webhook"

gitu --gitUrl "${GIT_URL}" "${WEBHOOK_URL}" || echo "Error creating webhook"

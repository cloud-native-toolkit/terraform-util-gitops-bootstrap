#!/usr/bin/env bash

ARGOCD_HOST="$1"
GIT_URL="$2"

if [[ -z "${GIT_TOKEN}" ]]; then
  echo "GIT_TOKEN must be provided as an environment variable"
  exit 1
fi

WEBHOOK_URL="https://${ARGOCD_HOST}/api/webhook"

GIT_ORG=$(echo "${GIT_URL}" | sed -E "s~https://github.com/([^/]+)/(.*)~\1~")
GIT_REPO=$(echo "${GIT_URL}" | sed -E "s~https://github.com/([^/]+)/(.*)~\2~")

# TODO only supports github for now. replace with 'gitu' cli
GIT_API_URL="https://api.github.com/repos/${GIT_ORG}/${GIT_REPO}/hooks"

echo "Creating webhook using ${GIT_API_URL} to webhook url: ${WEBHOOK_URL}"
curl "${GIT_API_URL}" \
     -H "Authorization: Token ${GIT_TOKEN}" \
     -H "Accept: application/vnd.github.v3+json" \
     -X POST \
     -d @- << EOF
{
  "name": "argocd",
  "active": true,
  "events": [
    "push"
  ],
  "config": {
    "url": "${WEBHOOK_URL}",
    "content_type": "json",
    "insecure_ssl": 1
  }
}
EOF

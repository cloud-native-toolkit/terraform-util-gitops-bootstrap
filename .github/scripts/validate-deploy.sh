#!/usr/bin/env bash

export KUBECONFIG=$(cat .kubeconfig)

SECRET_NAME=$(cat .secret_name)
GITOPS_NAMESPACE=$(cat .gitops_namespace)
KUBESEAL_NAMESPACE=$(cat .kubeseal_namespace)
PROJECT_NAME=$(cat .project_name)
APP_NAME=$(cat .app_name)

if ! kubectl get secret "${SECRET_NAME}" -n "${KUBESEAL_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find secret: ${KUBESEAL_NAMESPACE}/${SECRET_NAME}"
  exit 1
else
  echo "Found secret: ${KUBESEAL_NAMESPACE}/${SECRET_NAME}"
fi

if ! kubectl get appproject "${PROJECT_NAME}" -n "${GITOPS_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find project: ${GITOPS_NAMESPACE}/${PROJECT_NAME}"
  exit 1
else
  echo "Found project: ${GITOPS_NAMESPACE}/${PROJECT_NAME}"
fi

if ! kubectl get application "${APP_NAME}" -n "${GITOPS_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find application: ${GITOPS_NAMESPACE}/${APP_NAME}"
  exit 1
else
  echo "Found application: ${GITOPS_NAMESPACE}/${APP_NAME}"
fi

#!/usr/bin/env bash

BIN_DIR=$(cat .bin_dir)
export KUBECONFIG=$(cat .kubeconfig)

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

GIT_REPO=$(cat git_repo)
GIT_USERNAME=$(cat git_username)
GIT_TOKEN=$(cat git_token)
BOOTSTRAP_PATH=$(cat bootstrap_path)
SECRET_NAME=$(cat .secret_name)
GITOPS_NAMESPACE=$(cat .gitops_namespace)
KUBESEAL_NAMESPACE=$(cat .kubeseal_namespace)
PROJECT_NAME=$(cat .project_name)
APP_NAME=$(cat .app_name)

KUBECTL="${BIN_DIR}/kubectl"

if ! ${KUBECTL} get secret "${SECRET_NAME}" -n "${KUBESEAL_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find secret: ${KUBESEAL_NAMESPACE}/${SECRET_NAME}"
  exit 1
else
  echo "Found secret: ${KUBESEAL_NAMESPACE}/${SECRET_NAME}"
fi

if ! ${KUBECTL} get appproject "${PROJECT_NAME}" -n "${GITOPS_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find project: ${GITOPS_NAMESPACE}/${PROJECT_NAME}"
  exit 1
else
  echo "Found project: ${GITOPS_NAMESPACE}/${PROJECT_NAME}"
fi

if ! ${KUBECTL} get application "${APP_NAME}" -n "${GITOPS_NAMESPACE}" 1> /dev/null 2> /dev/null; then
  echo "Unable to find application: ${GITOPS_NAMESPACE}/${APP_NAME}"
  exit 1
else
  echo "Found application: ${GITOPS_NAMESPACE}/${APP_NAME}"
fi


mkdir -p .testrepo

git clone "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_REPO}" .testrepo

cd .testrepo || exit 1

if [[ ! -f "${BOOTSTRAP_PATH}/metadata.yaml" ]]; then
  echo "Unable to find metadata.yaml" >&2
  ls "${BOOTSTRAP_PATH}" >&2

  exit 1
fi

cat "${BOOTSTRAP_PATH}/metadata.yaml"

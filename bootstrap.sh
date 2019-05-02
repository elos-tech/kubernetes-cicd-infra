#!/bin/bash

source ./config

TMP_DIR=$(mktemp -d)

function create_from_template {
  FILE=$1; shift

  if [ ! -f "$FILE" ]; then
    echo "ERROR: File '$FILE' doesn't exist!"
    exit 1
  fi

  set -x
  cp $FILE "${TMP_DIR}/$(basename $FILE)"

  while (( "$#" )); do
    #echo "Replacing parameter: $1 -> $2"
    sed -i 's@'$1'@'$2'@g' "${TMP_DIR}/$(basename $FILE)"
    shift
    shift
  done

  kubectl create -f "${TMP_DIR}/$(basename $FILE)"
  set +x
}


# Jenkins Namespace
create_from_template templates/jenkins-namespace.yaml \
  _PREFIX_ $PREFIX
kubectl config set-context $(kubectl config current-context) --namespace=${PREFIX}jenkins


# Storage Class (Azure File for ReadWriteMany PV types)
#create_from_template templates/azure-file-storage-class.yaml \
#  _PREFIX_ $PREFIX \
#  _STORAGE_ACCOUNT_ $STORAGE_ACCOUNT_NAME


# Jenkins
create_from_template templates/jenkins-persistent.yaml \
  _PREFIX_ $PREFIX


# Build and push Jenkins agent POD to ACR registry
az acr build -t ${PREFIX}jenkins/jenkins-agent-appdev:latest -r $REGISTRY_NAME artefacts/


# Set k8s secret for pulling images from ACR registry
ACR_CREDENTIALS=$(az acr credential show -n $REGISTRY_NAME)
ACR_USERNAME=$(echo $ACR_CREDENTIALS | jq '.username' | sed 's/"//g')
ACR_PASSWORD=$(echo $ACR_CREDENTIALS | jq '.passwords[0].value' | sed 's/"//g')
ACR_HOSTNAME=$(az acr show -n $REGISTRY_NAME | jq '.loginServer' | sed 's/"//g')
kubectl create secret docker-registry cloud-technologies-registry \
    --docker-server=$ACR_HOSTNAME \
    --docker-username=$ACR_USERNAME \
    --docker-password=$ACR_PASSWORD \
    --docker-email='ls@elostech.cz'


rm -rf $TMP_DIR

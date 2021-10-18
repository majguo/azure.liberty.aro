#!/bin/bash

#      Copyright (c) Microsoft Corporation.
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#           http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Create service principal
sp=$(az ad sp create-for-rbac --sdk-auth)
if [[ $? != 0 ]]; then
  echo "Failed to create a service principal." >&2
  exit 1
fi
appClientId=$(echo $sp | jq -r '.clientId')
appClientSecret=$(echo $sp | jq -r '.clientSecret')

# Get object IDs
appSpObjectId=$(az ad sp show --id ${appClientId} --query 'objectId' -o tsv)
if [[ $? != 0 ]]; then
  echo "Failed to get objectId for ${appClientId}." >&2
  exit 1
fi
aroRpSpObjectId=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].objectId' -o tsv)
if [[ $? != 0 ]]; then
  echo "Failed to get objectId for \"Azure Red Hat OpenShift RP\"." >&2
  exit 1
fi

# Set values for secrets in the keyvault
az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name ${AAD_CLIENT_ID} --value ${appClientId}
if [[ $? != 0 ]]; then
  echo "Failed to set value for secret ${AAD_CLIENT_ID} in the keyvault ${KEY_VAULT_NAME}." >&2
  exit 1
fi
az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name ${AAD_CLIENT_SECRET} --value ${appClientSecret}
if [[ $? != 0 ]]; then
  echo "Failed to set value for secret ${AAD_CLIENT_SECRET} in the keyvault ${KEY_VAULT_NAME}." >&2
  exit 1
fi
az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name ${AAD_OBJECT_ID} --value ${appSpObjectId}
if [[ $? != 0 ]]; then
  echo "Failed to set value for secret ${AAD_OBJECT_ID} in the keyvault ${KEY_VAULT_NAME}." >&2
  exit 1
fi
az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name ${RP_OBJECT_ID} --value ${aroRpSpObjectId}
if [[ $? != 0 ]]; then
  echo "Failed to set value for secret ${RP_OBJECT_ID} in the keyvault ${KEY_VAULT_NAME}." >&2
  exit 1
fi

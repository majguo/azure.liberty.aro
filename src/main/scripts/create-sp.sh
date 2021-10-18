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
displayName=create-sp-$(date '+%Y-%m-%d-%H-%M-%S')
appClientSecret=$(cat /proc/sys/kernel/random/uuid)
app=$(az ad app create --display-name ${displayName} --password ${appClientSecret})
if [[ $? != 0 ]]; then
  echo "Failed to register application ${displayName}." >&2
  exit 1
fi
appClientId=$(echo $app | jq -r '.appId')
objectId=$(echo $app | jq -r '.objectId')
az ad sp create --id ${objectId}
if [[ $? != 0 ]]; then
  echo "Failed to create service principal for object id ${objectId}." >&2
  exit 1
fi

# Get service principal object IDs
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

# Add access policy for the uami associated with the deployment script
principalId=$(az identity show --ids ${AZ_SCRIPTS_USER_ASSIGNED_IDENTITY} --query "principalId" -o tsv)
az keyvault set-policy --name ${KEY_VAULT_NAME} --object-id ${principalId} --secret-permissions set
if [[ $? != 0 ]]; then
  echo "Failed to add access policy for the keyvault ${KEY_VAULT_NAME}." >&2
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

# Remove the previous added access poliy
az keyvault delete-policy --name ${KEY_VAULT_NAME} --object-id ${principalId}

#!/bin/bash

# This provisions the AKS cluster.

set -e

function usage() {
    cat <<USAGE

    Usage: $0 [-e|--azure-env-name] [-l|--location] [-h|--help]

    Options:
        -e|--azure-env-name                     Environment name.
        -l|--location                           Location to provision.

        -h|--help:                              Show this message.

USAGE

    exit 0
}

AZURE_ENV_NAME=
AZ_LOCATION=

if [[ $# -eq 0 ]]; then
    AZURE_ENV_NAME=
    AZ_LOCATION=
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -e | --azure-env-name)
            shift
            AZURE_ENV_NAME="$1"
        ;;

        -l | --location)
            shift
            AZ_LOCATION="$1"
        ;;

        -h | --help)
            usage
            exit 0
        ;;

        *)
            usage
            exit 0
        ;;
    esac

    shift
done

if [ -z "$AZURE_ENV_NAME" ] || [ -z "$AZ_LOCATION" ] ; then
    echo "Both 'azure-env-name' and 'location' must be provided" >&2
    exit 1
fi

# Get the resource token calculated from the subscription ID and the environment name
get_resource_token() {
    local subscription_id="$1"
    local azure_env_name="$2"

    local alphabets="abcdefghijklmnopqrstuvwxyz"
    local base_string="$subscription_id|$azure_env_name"

    # local hashed_string=$(echo -n "$base_string" | sha256sum | cut -d " " -f 1)
    local hashed_string=$(echo -n "$base_string" | shasum -a 256 2>/dev/null || echo -n "$base_string" | sha256sum | cut -d " " -f 1)
    hashed_string=$(echo ${hashed_string//[ -]/})

    local resource_token=""
    for (( i=0; i<${#hashed_string}; i+=2 )); do
        index=$(( $(printf "%d" "0x${hashed_string:$i:2}") % 26 ))
        resource_token+="${alphabets:$index:1}"
    done

    resource_token="${resource_token:0:13}"

    echo "$resource_token"
}

REPOSITORY_ROOT=$(git rev-parse --show-toplevel)

AZ_RESOURCE_GROUP="rg-$AZURE_ENV_NAME"
AZ_NODE_RESOURCE_GROUP="rg-$AZURE_ENV_NAME-mc"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_TOKEN=$(get_resource_token "$SUBSCRIPTION_ID" "$AZURE_ENV_NAME")

ACR_NAME="acr$RESOURCE_TOKEN"
AKS_CLUSTER_NAME="aks-$RESOURCE_TOKEN"

# Create a Resource Group
echo -e "\e[36mCreating a resource group '$AZ_RESOURCE_GROUP' in $AZ_LOCATION...\e[0m" >&2

AZ_GROUP_EXISTS=$(az group list --query "[?name == '$AZ_RESOURCE_GROUP'].name" -o tsv)
if [ -z "$AZ_GROUP_EXISTS" ] ; then
    GROUP=$(az group create -n $AZ_RESOURCE_GROUP -l $AZ_LOCATION)
fi

echo -e "\e[36m... Resource Group '$AZ_RESOURCE_GROUP' created\e[0m" >&2

# Create an Azure Container Registry
echo -e "\e[36mCreating an Azure Container Registry '$ACR_NAME' in $AZ_LOCATION in $AZ_RESOURCE_GROUP ...\e[0m" >&2

ACR_EXISTS=$(az acr list -g $AZ_RESOURCE_GROUP --query "[?name == '$ACR_NAME'].name" -o tsv)
if [ -z "$ACR_EXISTS" ] ; then
    ACR=$(az acr create \
        -g $AZ_RESOURCE_GROUP \
        -n $ACR_NAME \
        -l $AZ_LOCATION \
        --sku Basic \
        --admin-enabled true)
fi

echo -e "\e[36m... Azure Container Registry '$ACR_NAME' created\e[0m" >&2

# Gets the ACR login details
ACR_LOGIN_SERVER=$(az acr show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "loginServer" -o tsv)
ACR_USERNAME=$(az acr credential show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "passwords[0].value" -o tsv)

# Create an AKS cluster
echo -e "\e[36mCreating an AKS cluster '$AKS_CLUSTER_NAME' in $AZ_LOCATION in $AZ_RESOURCE_GROUP ...\e[0m" >&2

AKS_EXISTS=$(az aks list -g $AZ_RESOURCE_GROUP --query "[?name == '$AKS_CLUSTER_NAME'].name" -o tsv)
if [ -z "$AKS_EXISTS" ] ; then
    AKS=$(az aks create \
        -g $AZ_RESOURCE_GROUP \
        -n $AKS_CLUSTER_NAME \
        -l $AZ_LOCATION \
        --node-resource-group $AZ_NODE_RESOURCE_GROUP \
        --node-vm-size Standard_B2s \
        --network-plugin azure \
        --generate-ssh-keys \
        --attach-acr $ACR_NAME)
fi

echo "" >&2
echo -e "\e[36m... AKS cluster '$AKS_CLUSTER_NAME' created\e[0m" >&2

jq -n \
   --arg azureEnvName "$AZURE_ENV_NAME" \
   --arg location "$AZ_LOCATION" \
   --arg resourceGroup "$AZ_RESOURCE_GROUP" \
   --arg nodeResourceGroup "$AZ_NODE_RESOURCE_GROUP" \
   --arg acrName "$ACR_NAME" \
   --arg acrLoginServer "$ACR_LOGIN_SERVER" \
   --arg acrUsername "$ACR_USERNAME" \
   --arg acrPassword "$ACR_PASSWORD" \
   --arg aksClusterName "$AKS_CLUSTER_NAME" \
   '{
     "azureEnvName": $azureEnvName,
     "location": $location,
     "resourceGroup": $resourceGroup,
     "nodeResourceGroup": $nodeResourceGroup,
     "acrName": $acrName,
     "acrLoginServer": $acrLoginServer,
     "acrUsername": $acrUsername,
     "acrPassword": $acrPassword,
     "aksClusterName": $aksClusterName
   }'

# echo "{
#   \"azureEnvName\": \"$AZURE_ENV_NAME\",
#   \"location\": \"$AZ_LOCATION\",
#   \"resourceGroup\": \"$AZ_RESOURCE_GROUP\",
#   \"nodeResourceGroup\": \"$AZ_NODE_RESOURCE_GROUP\",
#   \"acrName\": \"$ACR_NAME\",
#   \"acrLoginServer\": \"$ACR_LOGIN_SERVER\",
#   \"acrUsername\": \"$ACR_USERNAME\",
#   \"acrPassword\": \"$ACR_PASSWORD\",
#   \"aksClusterName\": \"$AKS_CLUSTER_NAME\"
# }"

AKS=
AKS_EXISTS=
ACR_PASSWORD=
ACR_USERNAME=
ACR_LOGIN_SERVER=
ACR=
ACR_EXISTS=
GROUP=
AZ_GROUP_EXISTS=
AKS_CLUSTER_NAME=
ACR_NAME=
RESOURCE_TOKEN=
SUBSCRIPTION_ID=
AZ_LOCATION=
AZ_NODE_RESOURCE_GROUP=
AZ_RESOURCE_GROUP=
AZURE_ENV_NAME=
REPOSITORY_ROOT=

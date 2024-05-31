#!/bin/bash

# This destroys the AKS cluster.

set -e

function usage() {
    cat <<USAGE

    Usage: $0 [-e|--azure-env-name] [-h|--help]

    Options:
        -e|--azure-env-name                     Environment name.

        -h|--help:                              Show this message.

USAGE

    exit 0
}

AZURE_ENV_NAME=

if [[ $# -eq 0 ]]; then
    AZURE_ENV_NAME=
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -e | --azure-env-name)
            shift
            AZURE_ENV_NAME="$1"
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

if [ -z "$AZURE_ENV_NAME" ] ; then
    echo "'azure-env-name' must be provided"
    exit 1
fi

AZ_RESOURCE_GROUP="rg-$AZURE_ENV_NAME"

# Delete a resource group
echo -e "\e[36mDeleting a resource group '$AZ_RESOURCE_GROUP' ...\e[0m"

az group delete -n $AZ_RESOURCE_GROUP -y --no-wait

echo -e "\e[36m... Resource group '$AZ_RESOURCE_GROUP' being deleted\e[0m"

AZ_RESOURCE_GROUP=
AZURE_ENV_NAME=

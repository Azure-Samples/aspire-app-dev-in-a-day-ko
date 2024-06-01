# Provisions the AKS cluster.
Param(
    [string]
    [Parameter(Mandatory=$false)]
    $AzureEnvName = "",

    [string]
    [Parameter(Mandatory=$false)]
    $Location = "",

    [switch]
    [Parameter(Mandatory=$false)]
    $Help
)

function Show-Usage {
    Write-Host "    This provisions the AKS cluster.

    Usage: $(Split-Path $MyInvocation.ScriptName -Leaf) ``
            [-AzureEnvName      <Environment name>] ``
            [-Location          <Location>] ``

            [-Help]

    Options:
        -AzureEnvName       Environment name.
        -Location           Location to provision.

        -Help:              Show this message.
"

    Exit 0
}

# Get the resource token calculated from the subscription ID and the environment name
function Get-ResourceToken {
    param (
        [string] $SubscriptionId,
        [string] $AzureEnvName
    )

    $alphabets = "abcdefghijklmnopqrstuvwxyz"
    $baseString = "$SubscriptionId|$AzureEnvName"
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create('SHA256')
    $hashedBytes = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($baseString))
    
    $resourceToken = $($($hashedBytes | ForEach-Object { $alphabets[$_%26] }) -join "").Substring(0, 13)
   
    return $resourceToken
}

# Show usage
$needHelp = $Help -eq $true
if ($needHelp -eq $true) {
    Show-Usage
    Exit 0
}

if (($AzureEnvName -eq "") -or ($Location -eq "")) {
    Write-Host "Both ``AzureEnvName`` and ``Location`` must be provided"
    Exit 0
}

$REPOSITORY_ROOT = git rev-parse --show-toplevel

$AZURE_ENV_NAME = $AzureEnvName
$AZ_RESOURCE_GROUP = "rg-$AZURE_ENV_NAME"
$AZ_NODE_RESOURCE_GROUP = "rg-$AZURE_ENV_NAME-mc"
$AZ_LOCATION = $Location

$SUBSCRIPTION_ID = az account show --query id -o tsv
$RESOURCE_TOKEN = Get-ResourceToken -SubscriptionId $SUBSCRIPTION_ID -AzureEnvName $AZURE_ENV_NAME

$ACR_NAME = "acr$RESOURCE_TOKEN"
$AKS_CLUSTER_NAME = "aks-$RESOURCE_TOKEN"

# Create a Resource Group
Write-Host "Creating a resource group '$AZ_RESOURCE_GROUP' in $AZ_LOCATION..." -ForegroundColor Cyan

$AZ_GROUP_EXISTS = az group list --query "[?name == '$AZ_RESOURCE_GROUP'].name" | ConvertFrom-Json
if ($AZ_GROUP_EXISTS -eq $null) {
    $GROUP = az group create -n $AZ_RESOURCE_GROUP -l $AZ_LOCATION
}

Write-Host "... Resource Group '$AZ_RESOURCE_GROUP' created" -ForegroundColor Cyan

# Create an Azure Container Registry
Write-Host "Creating an Azure Container Registry '$ACR_NAME' in $AZ_LOCATION in $AZ_RESOURCE_GROUP ..." -ForegroundColor Cyan

$ACR_EXISTS = az acr list -g $AZ_RESOURCE_GROUP --query "[?name == '$ACR_NAME'].name" | ConvertFrom-Json
if ($ACR_EXISTS -eq $null) {
    $ACR = az acr create `
        -g $AZ_RESOURCE_GROUP `
        -n $ACR_NAME `
        -l $AZ_LOCATION `
        --sku Basic `
        --admin-enabled true
}

Write-Host "... Azure Container Registry '$ACR_NAME' created" -ForegroundColor Cyan

# Gets the ACR login details
$ACR_LOGIN_SERVER = az acr show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "loginServer" -o tsv
$ACR_USERNAME = az acr credential show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "username" -o tsv
$ACR_PASSWORD = az acr credential show -g $AZ_RESOURCE_GROUP -n $ACR_NAME --query "passwords[0].value" -o tsv

# Create an AKS cluster
Write-Host "Creating an AKS cluster '$AKS_CLUSTER_NAME' in $AZ_LOCATION in $AZ_RESOURCE_GROUP ..." -ForegroundColor Cyan

$AKS_EXISTS = az aks list -g $AZ_RESOURCE_GROUP --query "[?name == '$AKS_CLUSTER_NAME'].name" | ConvertFrom-Json
if ($AKS_EXISTS -eq $null) {
    $AKS = az aks create `
        -g $AZ_RESOURCE_GROUP `
        -n $AKS_CLUSTER_NAME `
        -l $AZ_LOCATION `
        --tier free `
        --node-resource-group $AZ_NODE_RESOURCE_GROUP `
        --node-vm-size Standard_B2s `
        --network-plugin azure `
        --generate-ssh-keys `
        --attach-acr $ACR_NAME
}

Write-Host ""
Write-Host "... AKS cluster '$AKS_CLUSTER_NAME' created" -ForegroundColor Cyan

$PROVISIONED = @{
    "azureEnvName" = $AZURE_ENV_NAME;
    "location" = $AZ_LOCATION;
    "resourceGroup" = $AZ_RESOURCE_GROUP;
    "nodeResourceGroup" = $AZ_NODE_RESOURCE_GROUP;
    "acrName" = $ACR_NAME;
    "acrLoginServer" = $ACR_LOGIN_SERVER;
    "acrUsername" = $ACR_USERNAME;
    "acrPassword" = $ACR_PASSWORD;
    "aksClusterName" = $AKS_CLUSTER_NAME;
}

Write-Host ""

Write-Output $PROVISIONED | ConvertTo-Json

Remove-Variable -Name PROVISIONED
Remove-Variable -Name AKS
Remove-Variable -Name AKS_EXISTS
Remove-Variable -Name ACR_PASSWORD
Remove-Variable -Name ACR_USERNAME
Remove-Variable -Name ACR_LOGIN_SERVER
Remove-Variable -Name ACR
Remove-Variable -Name ACR_EXISTS
Remove-Variable -Name GROUP
Remove-Variable -Name AZ_GROUP_EXISTS
Remove-Variable -Name AKS_CLUSTER_NAME
Remove-Variable -Name ACR_NAME
Remove-Variable -Name RESOURCE_TOKEN
Remove-Variable -Name SUBSCRIPTION_ID
Remove-Variable -Name AZ_LOCATION
Remove-Variable -Name AZ_NODE_RESOURCE_GROUP
Remove-Variable -Name AZ_RESOURCE_GROUP
Remove-Variable -Name AZURE_ENV_NAME
Remove-Variable -Name REPOSITORY_ROOT

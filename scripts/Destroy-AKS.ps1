# Destroys the AKS cluster.
Param(
    [string]
    [Parameter(Mandatory=$false)]
    $AzureEnvName = "",

    [switch]
    [Parameter(Mandatory=$false)]
    $Help
)

function Show-Usage {
    Write-Host "    This destroys the AKS cluster.

    Usage: $(Split-Path $MyInvocation.ScriptName -Leaf) ``
            [-AzureEnvName      <Environment name>] ``

            [-Help]

    Options:
        -AzureEnvName       Environment name.

        -Help:              Show this message.
"

    Exit 0
}

# Show usage
$needHelp = $Help -eq $true
if ($needHelp -eq $true) {
    Show-Usage
    Exit 0
}

if ($AzureEnvName -eq "") {
    Write-Host "``AzureEnvName`` must be provided"
    Exit 0
}

$AZURE_ENV_NAME = $AzureEnvName
$AZ_RESOURCE_GROUP = "rg-$AZURE_ENV_NAME"

# Delete a resource group
Write-Host "Deleting a resource group '$AZ_RESOURCE_GROUP' ..." -ForegroundColor Cyan

az group delete -n $AZ_RESOURCE_GROUP -y --no-wait

Write-Host "... Resource group '$AZ_RESOURCE_GROUP' being deleted" -ForegroundColor Cyan

Remove-Variable -Name AZ_RESOURCE_GROUP
Remove-Variable -Name AZURE_ENV_NAME

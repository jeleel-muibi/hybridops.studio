# file: New-HybridOpsTag.ps1
# purpose: Build a standard environment/role tag string
# author: Jeleel Muibi
# date: 2025-11-26

function New-HybridOpsTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter(Mandatory)]
        [string]$Role
    )

    $env = ($Environment).Trim()
    if (-not $env) { $env = "unknown" }

    $roleValue = ($Role).Trim()
    if (-not $roleValue) { $roleValue = "generic" }

    "env-$env`_role-$roleValue"
}

Export-ModuleMember -Function New-HybridOpsTag

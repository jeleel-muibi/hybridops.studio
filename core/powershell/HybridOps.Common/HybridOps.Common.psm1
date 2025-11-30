# file: HybridOps.Common.psm1
# purpose: Entry module for HybridOps.Common PowerShell utilities
# author: Jeleel Muibi
# date: 2025-11-26

$script:ModuleRoot = Split-Path -Parent $PSCommandPath
$functionsPath = Join-Path $ModuleRoot "functions"

Get-ChildItem -Path $functionsPath -Filter *.ps1 -File | ForEach-Object {
    . $_.FullName
}

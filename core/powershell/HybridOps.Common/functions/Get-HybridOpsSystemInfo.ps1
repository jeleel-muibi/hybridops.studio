# file: Get-HybridOpsSystemInfo.ps1
# purpose: Return basic system information for HybridOps evidence and troubleshooting
# author: Jeleel Muibi
# date: 2025-11-26

function Get-HybridOpsSystemInfo {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue

    [pscustomobject]@{
        ComputerName  = $env:COMPUTERNAME
        OSName        = $os.Caption
        OSVersion     = $os.Version
        Manufacturer  = $cs.Manufacturer
        Model         = $cs.Model
        TotalMemoryGB = if ($cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { $null }
        Domain        = $cs.Domain
        Timestamp     = (Get-Date).ToString("s")
    }
}

Export-ModuleMember -Function Get-HybridOpsSystemInfo

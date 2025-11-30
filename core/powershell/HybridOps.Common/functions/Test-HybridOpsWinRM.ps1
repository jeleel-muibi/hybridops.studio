# file: Test-HybridOpsWinRM.ps1
# purpose: Test WinRM connectivity to a remote host
# author: Jeleel Muibi
# date: 2025-11-26

function Test-HybridOpsWinRM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [int]$Port = 5985
    )

    $result = [ordered]@{
        ComputerName = $ComputerName
        Port         = $Port
        Reachable    = $false
        WinRM        = $false
        Error        = $null
    }

    try {
        $tcp = Test-NetConnection -ComputerName $ComputerName -Port $Port -WarningAction SilentlyContinue -ErrorAction Stop
        $result.Reachable = [bool]$tcp.TcpTestSucceeded
    } catch {
        $result.Error = $_.Exception.Message
        return [pscustomobject]$result
    }

    if (-not $result.Reachable) {
        return [pscustomobject]$result
    }

    try {
        $wsman = Test-WSMan -ComputerName $ComputerName -Port $Port -ErrorAction Stop
        if ($wsman) {
            $result.WinRM = $true
        }
    } catch {
        $result.Error = $_.Exception.Message
    }

    [pscustomobject]$result
}

Export-ModuleMember -Function Test-HybridOpsWinRM

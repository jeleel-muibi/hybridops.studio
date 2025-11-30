# HybridOps.Common PowerShell Module

**Location:** `core/powershell/HybridOps.Common`  
**Purpose:** Shared PowerShell helpers for HybridOps.Studio Windows and infrastructure automation.

## Contents

- `HybridOps.Common.psm1`  
  Script module that loads all functions from the `functions/` directory.

- `functions/Test-HybridOpsWinRM.ps1`  
  Verifies basic WinRM reachability to a remote host (TCP + WSMan).

- `functions/New-HybridOpsTag.ps1`  
  Builds a standard tag string (for example `env-dev_role-k3s-node`) aligned with Ansible/Terraform tagging conventions.

- `functions/Get-HybridOpsSystemInfo.ps1`  
  Returns basic operating system and hardware information for diagnostics and evidence collection.

## Usage

```powershell
# Adjust path to the cloned repository
$modulePath = "C:\path\to\hybridops-studio\core\powershell\HybridOps.Common\HybridOps.Common.psm1"

Import-Module $modulePath -Force

# Generate a standard tag
$tag = New-HybridOpsTag -Environment "dev" -Role "k3s-node"

# Test WinRM connectivity
$result = Test-HybridOpsWinRM -ComputerName "win-lab-01"

# Capture system information
$info = Get-HybridOpsSystemInfo
```

## Usage scenarios

Typical scenarios for this module include:

- Windows-focused automation workflows that require:
  - WinRM connectivity checks,
  - consistent tagging across Windows, Ansible, and Terraform,
  - lightweight system information for logging or evidence.

- Integration with CI/CD pipelines or Ansible roles that need common PowerShell helpers.

Role-specific or one-off PowerShell scripts should remain within the corresponding Ansible role under  
`core/ansible/collections/.../roles/<role_name>/files/`. The `HybridOps.Common` module is reserved for generic, reusable functionality that is applicable across multiple roles or environments.

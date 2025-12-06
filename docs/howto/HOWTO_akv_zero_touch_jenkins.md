---
title: "Azure Key Vault — Zero-Touch Secrets (Jenkins)"
topic: "bootstrap"
summary: "Configure Jenkins on ctrl-01 to pull secrets from Azure Key Vault at runtime—no UI credential entry and no secrets in Git."
difficulty: "Intermediate"
video: ""
draft: false
---

# Azure Key Vault — Zero-Touch Secrets (Jenkins)

This HOWTO shows how to make Jenkins on `ctrl-01` fetch secrets from **Azure Key Vault (AKV)** at runtime.  
No credentials are added in the Jenkins UI, and no secrets are stored in Git. All configuration is code-driven.

---

## ⚡ TL;DR (Copy & Paste)

On **ctrl-01** (Service Principal path):

```bash
# Create AKV secrets (example)
az keyvault secret set --vault-name kv-hybridops --name PACKER_CLIENT_SECRET --value '***'

# Write SP env for Jenkins (root-only) and load via systemd drop-in
sudo tee /etc/jenkins/akv.env >/dev/null <<'EOF'
AZURE_TENANT_ID=<tenant-id>
AZURE_CLIENT_ID=<app-id>
AZURE_CLIENT_SECRET=<client-secret>
AZURE_SUBSCRIPTION_ID=<subscription-id>
AKV_URL=https://kv-hybridops.vault.azure.net/
EOF
sudo chown jenkins:jenkins /etc/jenkins/akv.env && sudo chmod 600 /etc/jenkins/akv.env
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/10-akv-env.conf >/dev/null <<'EOF'
[Service]
EnvironmentFile=/etc/jenkins/akv.env
EOF
sudo systemctl daemon-reload && sudo systemctl restart jenkins
```

In **JCasC**:

```yaml
unclassified:
  azureKeyVault:
    keyVaultURL: "${AKV_URL:-https://kv-hybridops.vault.azure.net/}"
```

In a **pipeline**:

```groovy
azureKeyVault(keyVaultURL: env.AKV_URL, secrets: [[secretType: 'Secret', name: 'PACKER_CLIENT_SECRET', envVariable: 'PACKER_CLIENT_SECRET']]) {
  sh 'packer build images/base/packer.pkr.hcl'
}
```

---

## Objective

- Pipelines retrieve secrets **just-in-time** from AKV.
- Jenkins controller is configured via **JCasC** and **systemd** (no click-ops).
- Identity is least-privilege and **read-only** on the vault.

## How it works (at a glance)

- **AKV** holds pipeline secrets (Packer, Terraform, registry tokens).
- **Jenkins** authenticates with Azure via **DefaultAzureCredential**:
  - **On-prem** `ctrl-01`: Service Principal (SP) with **Key Vault Secrets User** + (optional) **Reader** on the vault.
  - **Azure-hosted Jenkins**: Managed Identity with the same roles.
- Pipelines declare secret names; the wrapper injects values as env vars scoped to the step.

## Prerequisites

- Azure subscription with a Key Vault (e.g., `kv-hybridops`).
- One of:
  - **On-prem** SP (App Registration) → assign **Key Vault Secrets User** on the vault scope.  
  - **Azure VM** Jenkins → enable Managed Identity and assign the same role on the vault.
- Jenkins on `ctrl-01` with outbound HTTPS.

> Create SP (CLI example):  
> `az ad sp create-for-rbac --name sp-hybridops-akv --sdk-auth`  
> Assign role:  
> `az role assignment create --role "Key Vault Secrets User" --assignee <APP_ID> --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>`

---

## Step 1 — Create secrets in Key Vault

Examples:

- `PACKER_CLIENT_SECRET`
- `TF_VAR_arm_client_secret`
- `REGISTRY_PAT`

```bash
az keyvault secret set --vault-name kv-hybridops --name PACKER_CLIENT_SECRET --value '***'
```

## Step 2 — Provide non-interactive credentials to Jenkins

### A) On-prem (Service Principal)

```bash
# 1) Secure env file for Jenkins
sudo tee /etc/jenkins/akv.env >/dev/null <<'EOF'
AZURE_TENANT_ID=<tenant-id>
AZURE_CLIENT_ID=<app-id>
AZURE_CLIENT_SECRET=<client-secret>
AZURE_SUBSCRIPTION_ID=<subscription-id>
AKV_URL=https://kv-hybridops.vault.azure.net/
EOF
sudo chown jenkins:jenkins /etc/jenkins/akv.env
sudo chmod 600 /etc/jenkins/akv.env

# 2) systemd drop-in to load envs
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/10-akv-env.conf >/dev/null <<'EOF'
[Service]
EnvironmentFile=/etc/jenkins/akv.env
EOF

# 3) reload Jenkins
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

### B) Azure-hosted Jenkins (Managed Identity)

Skip the file. Assign the VM’s identity **Key Vault Secrets User** on the vault.  
The SDK authenticates automatically—no client secret needed.

## Step 3 — Configure JCasC (no click-ops)

```yaml
# jenkins.yaml (snippet)
unclassified:
  azureKeyVault:
    keyVaultURL: "${AKV_URL:-https://kv-hybridops.vault.azure.net/}"
```

Reload as part of Day-1 bootstrap or via your safe reload job.

## Step 4 — Use in pipelines

**Scripted:**
```groovy
node('linux') {
  azureKeyVault(keyVaultURL: env.AKV_URL, secrets: [
    [secretType: 'Secret', name: 'PACKER_CLIENT_SECRET', envVariable: 'PACKER_CLIENT_SECRET'],
    [secretType: 'Secret', name: 'TF_VAR_arm_client_secret', envVariable: 'TF_VAR_arm_client_secret']
  ]) {
    sh '''
      set -eu
      packer validate images/base/packer.pkr.hcl
      packer build    images/base/packer.pkr.hcl
    '''
  }
}
```

**Declarative:**
```groovy
pipeline {
  agent { label 'linux' }
  stages {
    stage('Build Image') {
      steps {
        azureKeyVault(
          keyVaultURL: "${AKV_URL}",
          secrets: [[secretType: 'Secret', name: 'PACKER_CLIENT_SECRET', envVariable: 'PACKER_CLIENT_SECRET']]
        ) {
          sh 'packer build images/base/packer.pkr.hcl'
        }
      }
    }
  }
}
```

## Verification

- Jenkins logs show AKV wrapper activity without printing secret values.  
- On host: `sudo journalctl -u jenkins --since "5 min ago" --no-pager`  
- Temporarily remove vault role → pipeline should fail at secret fetch.

## Security Notes

- Scope roles to the **vault**. Avoid Owner/Contributor.  
- Rotate SP secrets; update `/etc/jenkins/akv.env` and restart Jenkins.  
- **Never commit** secrets. The only on-disk secret (SP) stays root/jenkins-owned outside Git.  
- AKV audit logs + Jenkins build logs = evidence trail.

## Troubleshooting

- `403` from AKV → check role assignments and principal/identity.  
- Plugin auth issues → verify `AZURE_*` vars are visible to Jenkins (System Information) or Managed Identity is enabled.  
- Secret name mismatch → confirm exact casing in AKV and pipeline.

---

## Related

- [ADR-0015 — Secrets strategy: AKV now; SOPS fallback; Vault later](../adr/ADR-0015_secrets-strategy_akv-now_sops-fallback_vault-later.md)
- Runbook — [Zero-Touch Secrets with AKV (Jenkins)](../runbooks/ops/ops_rotate_jenkins_sp_secret_akv.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

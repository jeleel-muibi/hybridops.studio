# Secrets Lifecycle and Responsibilities

Owner: HybridOps.Studio  
Scope: Ctrl-01, Proxmox, Azure, GCP, RKE2

Related ADR: [ADR-0020 — Secrets Strategy (AKV primary, SOPS DR fallback, Vault optional later)](../adr/ADR-0020_secrets-strategy_akv-now_sops-fallback_vault-later.md)

This document describes how secrets are handled across the platform from bootstrap to steady state and disaster recovery.

---

## 1. Goals

- Single source of truth for application and platform secrets.
- Clear separation between:
  - Infra bootstrap connectivity.
  - Runtime secrets for workloads.
  - Disaster recovery (break-glass) secrets.
- No hardcoded credentials in playbooks, pipelines, or templates.

---

## 2. Secret classes

### 2.1 Infra bootstrap secrets

Purpose: allow Ctrl-01 to reach Proxmox, Azure, and GCP to create infrastructure.

Location (on Ctrl-01):

```text
infra/env/
  env-proxmox   # Proxmox API, storage, network
  env-azure     # Azure subscription + service principal
  env-gcp       # GCP project + service account
```

Characteristics:

- Used by Packer/Terraform/Ansible on Ctrl-01.
- Not committed to git.
- Minimal set of credentials:
  - Proxmox API token.
  - Azure service principal (for AKV + infra).
  - GCP service account.
- Rotated manually and updated via `init-*-env.sh` helpers.

Usage examples:

- Packer builds templates using `env-proxmox`.
- Terraform configures Proxmox SDN, Azure VNET/AKV, GCP networks from these env files.
- Ansible uses the same env to connect to Proxmox and cloud resources during bootstrap.

### 2.2 Platform and application secrets (steady state)

Purpose: secrets used by Jenkins, NetBox, RKE2 workloads, databases, and application services.

Source of truth: **Azure Key Vault (AKV)**.

Examples:

- Jenkins admin password and service accounts.
- NetBox database credentials.
- Application API keys, tokens, and certificates.
- RKE2 cluster-level secrets (e.g. registry credentials).

Access patterns:

- Ctrl-01:
  - Jenkins and NetBox read from AKV (plugin, CLI, or env injection).
- RKE2:
  - External Secrets Operator syncs secrets from AKV into Kubernetes Secrets.
  - Reloader restarts pods when secrets or configuration change.
  - Kubernetes RBAC controls which workloads can see which secrets.

Constraints:

- No application secrets are stored in git.
- No long-lived application secrets are stored in `infra/env/*`.
- AKV is treated as the single authoritative store for app/platform secrets.

### 2.3 Disaster recovery (break-glass) secrets

Purpose: restore access if AKV or control-plane integration is temporarily unavailable.

Location (optional):

```text
docs/secrets/
  secrets.dr.enc.yaml   # sops-encrypted file with minimal break-glass values
```

Characteristics:

- Contains only the minimal critical secrets required to:
  - Recreate AKV access (e.g. a backup SP or root credential).
  - Recover critical databases if backups need manual restore.
- Encrypted with sops and not usable without the decryption key.
- Access tightly restricted; usage is documented in a DR runbook.
- Not part of normal operations; only referenced in DR scenarios.

---

## 3. Lifecycle by phase

### 3.1 Bootstrap (Ctrl-01, before RKE2)

Steps:

1. Ctrl-01 is provisioned with SSH access and minimal base tools.
2. Per-provider env files are created:

   ```bash
   infra/env/env-proxmox
   infra/env/env-azure
   infra/env/env-gcp
   ```

3. Packer uses `env-proxmox` to build Proxmox templates.
4. Terraform uses all three env files to:
   - Configure Proxmox (SDN, VMs).
   - Create Azure networking and AKV.
   - Create GCP networking (if in scope).
5. Ansible configures:
   - Jenkins and NetBox on Ctrl-01 (Docker or OS-level).
   - RKE2 on the Proxmox VMs.

Security intent:

- Bootstrap secrets live only in `infra/env/*` and are not replicated elsewhere.
- App/platform secrets (Jenkins admin, DB creds, etc.) are loaded into AKV once AKV exists.

### 3.2 Steady state (RKE2 online)

Once RKE2 is running:

- Jenkins agents migrate to Kubernetes (pods).
- Workloads run inside RKE2.
- Secrets pipeline:

  - Terraform manages AKV configuration and access policies.
  - External Secrets Operator reads from AKV and writes Kubernetes Secrets.
  - Reloader triggers rolling restarts on secret/config changes.
  - Kubernetes RBAC, Pod Security, and NetworkPolicies enforce access at runtime.

Ctrl-01 responsibilities:

- Retain per-provider bootstrap env (`infra/env/*`) and root-of-trust credentials.
- Run Terraform and Ansible for infra/platform changes.
- Avoid storing app secrets locally; defer to AKV wherever possible.

### 3.3 Disaster recovery

If AKV or cloud connectivity is unavailable and recovery is required:

- Use the sops-encrypted DR file (if enabled):

  ```text
  docs/secrets/secrets.dr.enc.yaml
  ```

- Follow the DR runbook to:
  - Decrypt the file on a secure workstation.
  - Restore access to AKV or recreate a minimal AKV instance.
  - Reapply Terraform/Ansible as needed to restore the platform.

Normal operations do not rely on the DR file. It exists purely for break-glass scenarios.

---

## 4. Design principles

- **Single source of truth for app secrets:** AKV.
- **Per-provider env files for bootstrap:** only connectivity and infra credentials, not app secrets.
- **Clear phase separation:** bootstrap (Ctrl-01), steady state (RKE2 + AKV), DR (manual, sops).
- **No duplicate secret systems:** no continuous mirroring of AKV to local stores.
- **Auditability and rotation:** rely on AKV for rotation and logging; keep env files and DR artifacts minimal and documented.

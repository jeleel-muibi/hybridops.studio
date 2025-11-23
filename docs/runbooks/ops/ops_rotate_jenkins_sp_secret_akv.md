---
title: "Rotate Jenkins Service Principal Secret — Azure Key Vault (Zero‑Touch)"
category: "ops"
severity: "P2"
last_updated: "2025-10-21"
draft: false
---

# Rotate Jenkins Service Principal Secret — Azure Key Vault (Zero‑Touch)

Design reference: see [ADR‑0015 — Secrets strategy: AKV‑first; SOPS fallback](../../adr/ADR-0015_secrets-strategy_akv-now_sops-fallback_vault-later.md).

This runbook rotates the **Azure AD application (service principal) client secret** used by Jenkins,
with **no UI credential entry**. Jenkins retrieves the secret at runtime from **Azure Key Vault (AKV)**.

---

## Pre‑checks

- **Identify auth mode** used by Jenkins pipelines:
  - **Managed Identity (MI):** If pipelines use MI to access AKV and Azure APIs, **no secret rotation** is needed. Skip to _Verify_.
  - **Client Secret (SP):** Continue with rotation steps below.
- Confirm access:
  - Azure CLI logged in with rights to **create SP credentials** and **set AKV secrets**.
  - You know the Key Vault name and the **secret name** Jenkins expects (e.g., `jenkins-sp-client-secret`).
- Ensure **Jenkins pipelines use AKV integration** (e.g., Azure Key Vault plugin / service connection) so no UI updates are required.

> Zero‑touch principle: Jenkins **never stores** the secret; it requests it dynamically from AKV each run.

---

## Execute (Rotation)

### A. If using **Managed Identity**
No rotation is required. Validate MI access and RBAC only (see _Verify_).

### B. If using **Client Secret**
1) **Create a new client secret** for the Azure AD application (service principal).
   - Use portal _or_ CLI (example CLI shown):
   ```bash
   az ad app credential reset      --id "<APP_REGISTRATION_ID_OR_APP_ID>"      --display-name "jenkins-rotation-$(date +%Y%m%d)"      --years 1      --query password -o tsv > /tmp/new_sp_secret.txt
   ```
   The newly issued **secret value** is the only time it will be revealed. Handle it securely.

2) **Update AKV with the new value** under the same secret name Jenkins expects:
   ```bash
   az keyvault secret set      --vault-name "<KEYVAULT_NAME>"      --name "jenkins-sp-client-secret"      --file /tmp/new_sp_secret.txt      --output jsonc
   ```
   This creates a **new version** of the same secret name. Jenkins will resolve latest at next run.

3) **Invalidate any cached secret** in agents or temporary files:
   ```bash
   shred -u /tmp/new_sp_secret.txt || rm -f /tmp/new_sp_secret.txt
   ```

4) **Trigger a safe pipeline** (validate stage only) to confirm the new secret works.

5) (Optional) **Retire the old SP credential** if it was created as an additional credential and you need to remove it:
   ```bash
   # If you created an extra credential keyId, remove it by keyId; otherwise skip.
   # az ad app credential list --id <APP_ID>
   # az ad app credential delete --id <APP_ID> --key-id <KEY_ID>
   ```

---

## Verify

- **Jenkins pipeline success** using AKV‑fetched secret (e.g., lightweight `packer validate` or `terraform init` stage).
- **AKV secret version** shows a recent timestamp for `jenkins-sp-client-secret`.
- **Azure AD sign‑in logs** show successful SP authentications after rotation.
- No secret material is present in Jenkins UI, job config, or logs.

Example quick check:
```bash
az keyvault secret show --vault-name "<KEYVAULT_NAME>" --name "jenkins-sp-client-secret" --query "properties.version" -o tsv
```

---

## Artifacts

Write the following to the repo **output/** area (created by `make env.setup`):

- `output/logs/akv/rotation_<YYYYMMDDTHHMMZ>.log` — CLI transcript (without secret values)
- `output/decision/akv_secret_rotation.json` — rotation metadata (vault, secret name, new version, operator)
- `output/audit/jenkins_validation.txt` — validation build URL / console summary

> Ensure logs never contain the secret value. Capture only **version IDs** and metadata.

---

## Rollback

1) **Repoint AKV secret to previous version** (Key Vault retains older versions):
   ```bash
   # Option A: set the previous value back under the same name (explicitly).
   # Option B: rotate again with the prior value if it’s securely stored (generally discouraged).
   ```
2) **Re-run validation pipeline** to confirm working state.
3) If the SP credential itself was removed, **issue a new credential** and set that value in AKV again.

---

## See also

- [ADR‑0015: Secrets strategy — AKV now; SOPS fallback; Vault later](../../adr/ADR-0015_secrets-strategy_akv-now_sops-fallback_vault-later.md)
- [HOWTO: Azure Key Vault — Zero‑Touch Secrets (Jenkins)](../../howto/HOWTO_akv_zero_touch_jenkins.md)

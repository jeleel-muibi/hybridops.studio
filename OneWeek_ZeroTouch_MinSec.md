# HybridOps.Studio — One‑Week Plan (Zero‑Touch + Minimum Security)

**Objective (this week):** Stand up a *zero‑touch* build path that creates **gold images with Packer** and can **provision ephemeral Proxmox agents** and **RKE2 nodes** from those images — with **Azure Key Vault (AKV)** as the *single source of secrets*. Evidence (logs/artifacts) must land under `output/` and link into the docs.

**Chosen direction:** CI‑driven images (Packer) + AKV for secrets (no secrets in Git).  
**Assumption:** `ctrl-01` (Jenkins controller) is online and can reach Azure and Proxmox.

---

## Guardrails & Principles

- **Zero‑touch:** Pipelines fetch secrets at runtime from **AKV**; no GUI credential pasting.  
- **Single bootstrap secret:** The Proxmox Day‑0 script accepts *AKV client credentials* via env vars; that’s the only human‑provided secret. Everything else comes from AKV.  
- **Immutable images first:** Bake **Ubuntu (RKE2)** and **Windows base** images; keep provisioning thin.  
- **Evidence‑first:** Every job writes machine‑readable outputs to `output/` and a short `README.md` nearby for auditors.  
- **No breaking changes in public Git:** All sensitive values live in AKV or in a local, git‑ignored file.

---

## High‑Level Flow (this week)

```mermaid
graph LR
  A[Day‑0 Proxmox Script] --> B[ctrl‑01 Jenkins]
  B --> C[Fetch secrets from AKV]
  C --> D[Packer Build (gold images)]
  D --> E[Publish images (Blob/Proxmox templates)]
  E --> F[Terraform (ephemeral agents / RKE2 nodes)]
  F --> G[Evidence → output/ + docs links]
```
> Bootstrap input = AKV Service Principal creds via env to the Day‑0 script (never committed).

---

## Day‑by‑Day

### MON — AKV & Bootstrap Wiring
**Goals**
- Create **Azure AD App/Service Principal** for AKV access (least privilege).  
- Create **Key Vault** and populate *initial* secrets:  
  - `jenkins_admin_pass` (for Day‑1)  
  - `azure_sp_client_id`, `azure_sp_client_secret`, `azure_tenant_id`  
  - `azure_storage_conn` (or `blob_sas`) for image publishing  
- Enable network access so `ctrl-01` can reach AKV.
- Update **Day‑0** provisioner to accept envs and persist for Jenkins:
  - `AKV_NAME`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`

**CLI Sketch**
```bash
# login as your admin (one time, local machine)
az login
az ad sp create-for-rbac --name "hybridops-akv" --role "Key Vault Secrets Officer"   --scopes /subscriptions/<sub>/resourceGroups/<rg> -o json > sp.json

# create Key Vault and set secrets (examples)
az keyvault create -n <kv-name> -g <rg>
az keyvault secret set --vault-name <kv-name> -n jenkins_admin_pass --value '<strong-password>'
az keyvault secret set --vault-name <kv-name> -n azure_sp_client_id --value "$(jq -r .appId sp.json)"
az keyvault secret set --vault-name <kv-name> -n azure_sp_client_secret --value "$(jq -r .password sp.json)"
az keyvault secret set --vault-name <kv-name> -n azure_tenant_id --value "$(jq -r .tenant sp.json)"
```

**Definition of Done**
- `ctrl-01` can run `az keyvault secret show -n jenkins_admin_pass -o tsv` using the SP creds injected by Day‑0.
- ADR updated to **AKV‑first** wording (SOPS as fallback): `docs/adr/ADR-0015_secrets-strategy_akv-now_sops-fallback_vault-later.md`.

**Evidence**
- Paste the exact `az` commands (with IDs redacted) into `output/logs/akv_bootstrap/$(date)/commands.txt`.
- Store a JSON sample of `az keyvault secret show` output (value redacted).

---

### TUE — Jenkins ↔ AKV Plumbing (No GUI Secrets)
**Goals**
- Add a small helper: `control/tools/akv.sh get <secret>` → prints value using `az`+SP envs.  
- Jenkins shared library function `akvGet('name')` shells to the helper.  
- Seed jobs from Git (JCasC) — no manual credential entry.

**Jenkinsfile Excerpt**
```groovy
pipeline {
  agent { label 'ctrl01' }
  stages {
    stage('Fetch secrets') {
      steps {
        script {
          env.JENKINS_ADMIN_PASS = sh(script: "control/tools/akv.sh get jenkins_admin_pass", returnStdout: true).trim()
        }
      }
    }
  }
}
```

**Definition of Done**
- A seed pipeline can read `jenkins_admin_pass` from AKV and write a redacted line to `output/logs/jenkins/secrets_test.log`.
- No credentials stored in Jenkins UI — only file/env injected by Day‑0.

**Evidence**
- `output/logs/jenkins/secrets_test.log` with timestamps & redacted values.
- Screenshot (or text capture) of JCasC showing no inline secrets.

---

### WED — Packer Image Builds (Ubuntu + Windows Base)
**Goals**
- Create **Packer** templates under `packer/ubuntu-rke2/` and `packer/windows-base/`.
- Variables come from AKV via pipeline env injection.
- Post‑processors: checksums + upload to **Azure Blob** and (optionally) import to **Proxmox template**.

**CLI/Pipeline Sketch**
```bash
packer init packer/ubuntu-rke2
packer validate -var "blob_sas=$BLOB_SAS" packer/ubuntu-rke2
packer build -var "blob_sas=$BLOB_SAS" packer/ubuntu-rke2
```

**Definition of Done**
- `output/artifacts/images/ubuntu-rke2/VERSION/sha256.txt` exists.
- Blob container has the image; optional: Proxmox has an imported template.

**Evidence**
- `output/artifacts/images/<name>/<version>/manifest.json`
- `output/logs/packer/<name>-<timestamp>.log`

---

### THU — Terraform Provision from Images (Ephemeral Agents / RKE2 Node)
**Goals**
- Create Terraform module `terraform/proxmox/agent/` that consumes an image/template name and provisions an ephemeral VM agent.
- Optional: module for a **single RKE2 worker** to validate the image.
- Capture outputs to JSON in `output/artifacts/terraform/...`.

**CLI/Pipeline Sketch**
```bash
terraform -chdir=terraform/proxmox/agent init
terraform -chdir=terraform/proxmox/agent apply -auto-approve   -var "template=ubuntu-rke2-<version>"
```

**Definition of Done**
- An ephemeral agent can connect back to Jenkins (SSH/agent).  
- JSON outputs exist under `output/artifacts/terraform/proxmox-agent/`.

**Evidence**
- Terraform state redacted export & `terraform show -json`.
- `output/logs/terraform/proxmox-agent-apply-<timestamp>.log`.

---

### FRI — Dry‑Run DR/Burst & Documentation
**Goals**
- Wire the thin **decision** stub: `control/decision/run_action.sh` that (for now) only logs chosen target; cost gate left as TODO.
- Manually trigger a small “provision 1 worker” flow to prove end‑to‑end.
- Update HOWTO, Runbook, and the repo README Quickstart.

**Definition of Done**
- One end‑to‑end run: secrets→packer→blob→terraform→evidence.  
- HOWTO index & Runbook index regenerate without errors.

**Evidence**
- `output/decision/dryrun/<timestamp>/summary.json`  
- `docs/evidence_map.md` updated with links to fresh artifacts.

---

## Weekend Buffer (Polish / Risks / Stretch)
- **Polish:** README Quickstart & screenshots; fix any dead links.  
- **Risks:** AKV SP expiry → add reminder task; Proxmox network/vLAN; packer permissions.  
- **Stretch:** Import image into **Azure Compute Gallery** and publish one image version; add checksum verification in Terraform prior to deploy.

---

## Repo Touch Points (this week)

- `control/tools/akv.sh` — thin helper wrapper around `az keyvault secret show`.  
- `packer/ubuntu-rke2/` & `packer/windows-base/` — first two templates.  
- `terraform/proxmox/agent/` — minimal module to spin ephemeral agents.  
- `control/decision/run_action.sh` — logs a choice only (cost gates are future work).  
- `docs/howto/HOWTO_ctrl01_provisioner.md` — ensure **AKV envs** are documented in Day‑0.  
- `docs/runbooks/bootstrap/bootstrap-rke2-install.md` — verify image‑based path notes.

> **gitignore:** ensure `output/`, `etc/local/`, any `*.local.yaml`, and `sp.json` are ignored.

---

## Evidence Expectations (for public readers)

- Every job writes a **log** and **machine‑readable artifact** under `output/`.  
- HOWTO & Runbook READMEs cross‑link into those artifacts.  
- ADR‑0015 reflects **AKV‑first** with **SOPS fallback**; link it prominently.

---

## What’s *not* in scope (this week)

- Full **cost/telemetry gates** (Decision Service) — the folder is scaffolded, not enforced.
- Multi‑cloud image publishing (keep to Azure Blob + Proxmox for now).
- Cluster‑wide RKE2 deployment — validate 1 node only.

---

**Owner:** Jeleel Muibi  
**Last updated:** {{ set on commit }}  
**License:** MIT‑0 / CC‑BY‑4.0

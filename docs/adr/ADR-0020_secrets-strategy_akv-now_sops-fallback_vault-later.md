---
id: ADR-0020
title: "Secrets Strategy — Azure Key Vault primary; SOPS DR fallback; Vault optional later"
status: Accepted
date: 2025-10-20
domains: ["governance", "secops", "platform"]
owners: ["HybridOps.Studio"]
access: public        # public | internal | confidential
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks:
    - "../runbooks/bootstrap/bootstrap-ctrl01-node.md"
  howtos:
    - "../howto/HOWTO_ctrl01_provisioner.md"
  guides:
    - "../guides/secrets-lifecycle.md"
  evidence: []
  diagrams: []
---

# Secrets Strategy — Azure Key Vault primary; SOPS DR fallback; Vault optional later

**Status:** Accepted — Centralises all runtime secrets in Azure Key Vault with a minimal SOPS DR fallback, simplifying governance while keeping a clear, auditable DR path.


Related guide: [Secrets lifecycle and responsibilities](../guides/secrets-lifecycle.md)

---

## 1. Context

HybridOps.Studio needs a consistent approach to managing secrets across:

- Ctrl-01 (the on-premises control node).
- Proxmox-based infrastructure (Packer / Terraform / Ansible).
- Cloud providers (Azure, GCP).
- The RKE2-based Kubernetes platform and workloads running on it.

The portfolio must:

- Demonstrate zero-touch automation (no manual UI configuration).
- Avoid hardcoded credentials in playbooks, pipelines, or templates.
- Support homelab constraints (single operator, limited hardware) while staying aligned with enterprise patterns.
- Provide a credible story for disaster recovery without introducing unnecessary complexity.

Earlier sketches considered multiple overlapping secret systems:

- Per-provider env files on Ctrl-01.
- A local SOP (Secrets Operations Platform) abstraction on Ctrl-01.
- Azure Key Vault (AKV).
- Potential future adoption of HashiCorp Vault.

This ADR narrows that down to a clear hierarchy and single source of truth for application and platform secrets.

---

## 2. Decision

1. **Azure Key Vault (AKV) is the single source of truth** for:
   - Jenkins, NetBox, and application secrets.
   - RKE2 and in-cluster workload secrets (via operators).

2. **Per-provider env files under `infra/env/` are used only for bootstrap connectivity**, not as an application secret store:

   ```text
   infra/env/
     env-proxmox   # Proxmox API / storage / network bootstrap
     env-azure     # Azure subscription + service principal for AKV + infra
     env-gcp       # GCP project + service account
   ```

3. **RKE2 uses AKV via External Secrets Operator as the runtime secrets layer**:
   - External Secrets Operator syncs from AKV into Kubernetes Secrets.
   - Reloader (or equivalent) restarts pods when secrets/configs change.
   - Kubernetes RBAC, Pod Security and NetworkPolicies govern access.

4. **A sops-encrypted DR file is permitted as a manual, break-glass fallback**, containing only the minimal secrets required to restore AKV and critical databases:

   ```text
   docs/secrets/secrets.dr.enc.yaml
   ```

   - It is not used in normal operations.
   - It is decrypted only under a documented DR procedure.

5. **HashiCorp Vault remains an optional, future enhancement**:
   - May be introduced later for dynamic database credentials or advanced cloud auth.
   - Must not change the principle that there is a single active source of truth for app/platform secrets at any point in time.

Detailed lifecycle and responsibilities are described in the guide  
`docs/guides/secrets-lifecycle.md`.

---

## 3. Rationale

- **Clarity and simplicity:** A single primary store for application and platform secrets (AKV) avoids drift, confusion, and duplicated rotation logic.
- **Alignment with target audience:** Many organisations already use Azure AD and AKV; adopting AKV fits a realistic enterprise path.
- **Bootstrap vs. runtime separation:** Per-provider env files are a pragmatic way to bootstrap Packer/Terraform/Ansible without mixing them into application secrets.
- **Evidence-focused:** The approach makes it easy to collect evidence:
  - `infra/env/*` for bootstrap.
  - Terraform state and AKV access policies.
  - External Secrets Operator manifests.
  - RKE2 workloads consuming secrets.
- **DR without over-engineering:** A single sops-encrypted DR artefact gives a credible break-glass story without building a second live secret platform.

Alternatives that mirrored secrets between AKV and a local SOP on Ctrl-01 were rejected as over-complex and hard to reason about under failure.

---

## 4. Consequences

### 4.1 Positive consequences

- Clear, documented hierarchy:
  - Bootstrap connectivity: `infra/env/*`.
  - Application/platform secrets: AKV.
  - DR-only secrets: sops-encrypted file.
- Reduced risk of secrets drift or multiple conflicting sources of truth.
- Easier to teach and demonstrate in the HybridOps Academy:
  - Simple timelines (bootstrap → steady state → DR).
  - Concrete implementation in Terraform, Ansible, and RKE2 manifests.
- Compatible with future Vault adoption:
  - Vault can be added later as a single active provider at a time, not as a parallel system.

### 4.2 Negative consequences / risks

- Strong dependency on AKV for steady-state operations:
  - If AKV or Azure are unavailable, platform operations may be degraded.
- Additional work required to:
  - Implement External Secrets Operator and reloader correctly.
  - Maintain appropriate RBAC and Pod Security configurations.
- DR process is intentionally manual:
  - sops DR flow requires operator discipline and secure key handling.

---

## 5. Alternatives considered

- **Local SOP on Ctrl-01 mirroring AKV:**
  - Would copy secrets from AKV to a local store on Ctrl-01 for “offline” use.
  - Rejected as over-engineering:
    - Harder to reason about which copy is correct.
    - Adds rotational and auditing complexity.

- **Single giant `.env` file for all providers:**
  - Simpler in the short term, but mixes concerns and encourages dumping app secrets into bootstrap files.
  - Rejected in favour of `infra/env/env-proxmox`, `env-azure`, `env-gcp`.

- **HashiCorp Vault as the initial primary store:**
  - Powerful and flexible, but heavier to deploy and maintain in a homelab.
  - Deferred to a later phase once AKV-based patterns are stable and evidence-backed.

---

## 6. Implementation notes

- **Bootstrap env files:**
  - Created and maintained by:
    - `control/tools/provision/init/init-proxmox-env.sh`
    - `control/tools/provision/init/init-azure-env.sh`
    - `control/tools/provision/init/init-gcp-env.sh`
  - Consumed by:
    - Packer (Proxmox templates).
    - Terraform (Proxmox SDN/VMs, Azure/GCP infra, AKV).
    - Ansible (Ctrl-01, Jenkins, NetBox, RKE2 nodes).

- **AKV integration:**
  - Terraform modules create AKV, secrets, and access policies.
  - Jenkins and NetBox on Ctrl-01 read secrets from AKV (plugin, CLI, or env).

- **RKE2 integration:**
  - External Secrets Operator pulls from AKV.
  - Kubernetes Secrets are not treated as a source of truth; they are derived objects.
  - Reloader restarts pods when secrets or configs change.

- **DR artefact:**
  - Optional `docs/secrets/secrets.dr.enc.yaml` may be created with sops.
  - DR runbook defines how and when to decrypt and use it.

The guide: [Secrets lifecycle and responsibilities](../guides/secrets-lifecycle.md) provides day-to-day operational detail and examples.

---

## 7. Operational impact and validation

- **Runbooks:**
  - Ctrl-01 bootstrap and verification.
  - AKV provisioning and rotation checks.
  - RKE2 platform bootstrap and secret consumption tests.
  - DR drill for sops-encrypted secrets (optional).

- **Evidence:**
  - `infra/env/*` (redacted examples) for connectivity.
  - Terraform plans and state for AKV and infra.
  - External Secrets Operator manifests and logs.
  - RKE2 workload manifests and pod logs confirming secret injection.

- **Validation:**
  - CI job(s) that:
    - Lint Terraform/Ansible and RKE2 manifests.
    - Optionally perform a smoke test that reads a sample secret from AKV via External Secrets Operator.

---

## 8. References

- Guide: [Secrets lifecycle and responsibilities](../guides/secrets-lifecycle.md)
- How-to: [Provision ctrl-01](../howto/HOWTO_ctrl01_provisioner.md)
- Runbook: [ctrl-01 bootstrap / verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)
- Related cost & telemetry considerations: [Cost & Telemetry](../guides/cost-model.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

# Control — Operator Entry Points

Thin, reproducible entry points for day‑to‑day operations. These wrappers invoke canonical playbooks, Terraform, and GitOps manifests so runs are consistent across on‑premises and cloud targets.

- **Scope:** orchestration wrappers, shared utilities, and decision logic used in DR/burst flows.
- **Outputs:** human‑readable logs and artifacts under `out/` (created by `make env.setup`).

---

## Intended audience

- Stakeholders and reviewers seeking an overview of operational entry points.
- Operations engineers using consistent, repeatable shortcuts for routine tasks.

---

## Prerequisites

- **Runtime:** Bash, Python 3
- **Tools:** `ansible`, `terraform`, `kubectl`, `jq` (optional: `yq`)
- **Access:** kubeconfig for target clusters; cloud CLIs/credentials when running DR/burst
- **Environment variables:**

| Variable | Purpose |
|---|---|
| `NETBOX_URL` / `NETBOX_TOKEN` | NetBox API endpoint and token for SoT sync / dry‑run |
| `RKE2_SERVER_URL` / `RKE2_TOKEN` | Join parameters for RKE2 agent nodes |
| `CLOUD_PROVIDER` | Target cloud for DR/burst (`azure` or `gcp`) |
| `KUBECONFIG` | Path to the kubeconfig used by clients |

An example environment file is provided under `control/.env.example` and can be copied and edited in place.

```bash
cp control/.env.example control/.env
$EDITOR control/.env
```

---

## Contents

- **bin/** — operator scripts (wrappers) that call canonical playbooks, Terraform plans/applies, and GitOps actions.
- **tools/** — shared utilities consumed by wrappers:
  - `bash/lib/common.sh` — helpers for path resolution and required‑command checks.
  - `python/decision/choose_target.py` — evaluates signals (Prometheus federation, cloud monitors, credit thresholds) and emits a provider choice.
  - `powershell/` — optional helpers for Windows administration when called from Ansible or CI.
- **examples/** — sample outputs (e.g., `out/decision/decision.json`) illustrating artifacts produced by live runs.

> Canonical playbooks and Terraform modules reside under **Deployment** and **Terraform Infra**. The control layer orchestrates these components in a predictable manner.

---

## Quick start

**Via Make**

```bash
# Prepare local folders and validate tools
make env.setup sanity

# Baseline bootstrap (on‑prem)
make control.orchestrate.onprem

# End‑to‑end DR flow (Decision Service or explicit provider)
CLOUD_PROVIDER=azure make control.orchestrate.dr    # or: gcp

# Convert TF outputs → CSV → plan a NetBox sync
make control.tf.csv
NETBOX_URL=https://netbox.local NETBOX_TOKEN=*** make control.netbox.plan
```

**Direct script invocation** (paths may differ depending on naming):

```bash
control/bin/orchestrate_onprem.sh          # baseline bootstrap
control/bin/dr_cutover.sh                   # provider chosen by Decision Service
control/bin/dns_cutover.sh                  # DNS cutover to Azure/GCP endpoints
control/bin/inventory_render.sh             # NetBox → Ansible inventory (dry render)
```

Each run prints a brief summary, writes logs to `out/logs/`, and stores artifacts under `out/artifacts/` (decisions, rendered inventories, and similar outputs).

---

## Included wrappers (overview)

| Script (control/bin) | Purpose | Mutates state | Requirements |
|---|---|---:|---|
| `rke2-server.sh` | Install / start **RKE2 server** (control‑plane) | ✅ | `sudo` |
| `rke2-agent.sh` | Join host as **RKE2 agent** | ✅ | `RKE2_SERVER_URL`, `RKE2_TOKEN` |
| `gitops-bootstrap.sh` | Apply **GitOps bootstrap** (Argo/Flux) on current kube‑context | ✅ | `kubectl`, kube access |
| `tf-outputs-to-csv.sh` | `terraform output -json` → **CSV** for inventory/NetBox | ❌ | `python3`, `jq` |
| `netbox-plan-sync.sh` | **Plan** NetBox sync from CSV (no writes unless enabled) | ❌ | `NETBOX_URL`, `NETBOX_TOKEN` |
| `dr-dns-cutover.sh` | **DNS cutover** to Azure/GCP endpoints | ✅ | cloud credentials; provider arg |

*Names are illustrative and may differ by repository.*

---

## Conventions

- **Non‑destructive by default:** wrappers prefer validate/lint/dry‑run modes; destructive actions are explicit and documented in runbooks.
- **Idempotent:** re‑running a wrapper yields the same result unless inputs change (source of truth, variables, or infrastructure state).
- **Secrets:** CI uses secrets stores (for example, GitHub Actions secrets); local runs use documented environment variables. Long‑lived credentials are avoided.
- **Evidence:** Significant runs export JSON/CSV alongside screenshots for traceability (see Evidence Map).

---

## Related

- **[Runbooks](../docs/runbooks/README.md)** — procedural steps for DR, burst, bootstrap, DNS, VPN, secrets
- **[Deployment](../deployment/)** — environment-specific playbooks and GitOps overlays
- **[Terraform Infra](../terraform-infra/)** — environment directories and modules
- **[Core](../core/)** — reusable Ansible collection, Python utilities, PowerShell module
- **[Evidence Map](../docs/evidence_map.md)** — claim → proof links for KPIs and architecture
- **[Proof Archive](../docs/proof/README.md)** — curated screenshots and exports

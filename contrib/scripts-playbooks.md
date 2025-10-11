# Scripts ↔ Playbooks Reference
_Last updated: 2025-10-08 21:59 UTC_

A quick mapping of **operator scripts** to the **Ansible playbooks/roles** they invoke. This gives assessors a clear view of execution flow without diving into every folder.

---

## Common flows

| Task | How to run | Playbook | Key roles (collection) | Artifacts & Evidence |
|---|---|---|---|---|
| **Bootstrap RKE2 control plane** | `make kubernetes.rke2_install` _or_ `control/bin/orchestrate.sh kubernetes.rke2_install` | `deployment/kubernetes/playbooks/rke2_install.yml` | `hybridops.common.rke2_install` | Ansible logs → `output/logs/ansible/` |
| **Seed NetBox (SoT)** | `make netbox.seed` _or_ `control/bin/orchestrate.sh netbox.seed` | `deployment/netbox/playbooks/seed.yml` | `hybridops.common.netbox.seed` | Inventory export → `output/artifacts/inventories/` |
| **Baseline Linux hardening** | `make linux.baseline` _or_ `control/bin/orchestrate.sh linux.baseline` | `deployment/linux/playbooks/baseline.yml` | `hybridops.common.harden_ssh`, `hybridops.common.user_management` | Logs → `output/logs/ansible/` |
| **DR cutover (end‑to‑end)** | `control/bin/orchestrate.sh dr` | composite: DB promote → attach cluster → GitOps sync → DNS cutover | `hybridops.common.*` + Terraform | Evidence → `docs/runbooks/dr/dr-failover-to-cloud.md` · Artifacts → `output/artifacts/dr-drills/` |
| **DNS cutover** | `make network.dns_cutover` _or_ `control/bin/orchestrate.sh network.dns_cutover` | `deployment/network/playbooks/dns_cutover.yml` | provider‑specific role | Runbook → `docs/runbooks/ops/ops-dns-cutover.md` |

> The `control/` wrappers set repo‑root paths, env vars, and logging so commands run the same on laptops and control nodes.

---

## How the wrappers call playbooks

- **Resolution & logging** — wrappers source `control/tools/bash/lib/common.sh` for root resolution and `tee` logs into `output/logs/...` with UTC timestamps.
- **Inventory** — first bootstrap uses `deployment/inventories/bootstrap/`; production comes from **NetBox** via the dynamic inventory.
- **Variables & secrets** — env‑specific vars live under `deployment/<domain>/vars/`; secrets are resolved at deploy time (e.g., External Secrets with cloud KMS).

**Example (sketch):**
```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../tools/bash/lib/common.sh"

# Example: baseline Linux
ansible-playbook   -i deployment/inventories/bootstrap/hosts.ini   deployment/linux/playbooks/baseline.yml | tee "output/logs/ansible/linux_$(date -Iseconds).log"
```

---

## See also
- **Run procedures:** [Runbooks](../docs/runbooks/README.md)
- **Architecture & evidence:** [Docs index](../docs/README.md) · [Evidence Map](../docs/evidence_map.md)

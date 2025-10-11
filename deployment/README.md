# Deployment — Playbooks, Inventories & GitOps

Operational playbooks, inventories, and GitOps overlays used to bring up and run HybridOps.Studio.
This area is runnable and intentionally concise; deeper guidance lives under [docs](../docs/) and [contrib](../contrib/).

---

## What this area provides

- **Domain playbooks:** `linux/`, `kubernetes/`, `netbox/`, `network/`, `windows/`
- **Inventories:** static bootstrap → NetBox dynamic handoff
- **GitOps:** app-of-apps with Kustomize overlays for **dev**, **stage**, and **dr**
- **Orchestration:** invoked via the root **Makefile** and **control** wrappers

> Reusable logic (roles, modules, helpers) lives in **Core**. This folder contains the environment-specific glue.

---

## Source of Truth handoff

1. **Bootstrap** against the static inventory to baseline hosts.
2. **Switch SoT:** Terraform emits facts → seed **NetBox** → switch Ansible to the NetBox dynamic inventory.

```bash
# Inspect inventory from NetBox
ansible-inventory -i deployment/inventories/netbox/netbox.yml --graph

# Example baseline run from NetBox inventory
ansible-playbook -i deployment/inventories/netbox/netbox.yml   deployment/linux/playbooks/baseline.yml
```

Secrets are not committed. Provide them via Ansible Vault or CI secrets.

---

## Makefile routing (from repo root)

The root Makefile forwards targets to per-domain Makefiles under `deployment/`.

```bash
make env.setup sanity

# Examples
make linux.rke2_install_server
make kubernetes.gitops_bootstrap
make netbox.seed
make windows.domain_join
make network.configure_bgp
```

Logs land in `output/artifacts/ansible-runs/<domain>/TIMESTAMP.log`.
Override inventory per run if needed:

```bash
INVENTORY=deployment/inventories/bootstrap/hosts.ini   make linux.rke2_install_server
```

---

## GitOps (Argo CD)

App-of-apps with Kustomize overlays.

```bash
# Bootstrap GitOps
kubectl apply -f deployment/kubernetes/gitops/bootstrap.yaml

# Build overlays locally or in CI
kustomize build deployment/gitops/overlays/dev   > output/gitops_dev.yaml
kustomize build deployment/gitops/overlays/stage > output/gitops_stage.yaml
kustomize build deployment/gitops/overlays/dr    > output/gitops_dr.yaml
```

---

## Layout (high level)

```
deployment/
  inventories/
    bootstrap/           # static inventory before NetBox SoT
    netbox/              # dynamic inventory after seeding
  linux|kubernetes|.../
    Makefile             # domain router (called by root Makefile)
    playbooks/           # thin playbooks that call reusable roles
    files|templates/     # env-specific helpers (only if needed)
  gitops/                # base/apps/overlays
```

---

## Related

- **[Runbooks](../docs/runbooks/README.md)** — procedural steps for DR, burst, bootstrap, DNS, VPN, secrets
- **[Deployment (this folder)](./)** — environment-specific playbooks and GitOps overlays
- **[Terraform Infra](../terraform-infra/README.md)** — environment directories and modules
- **[Core](../core/)** — reusable Ansible collection, Python utilities, PowerShell module
- **[Evidence Map](../docs/evidence_map.md)** — claim → proof links for KPIs and architecture
- **[Scripts ↔ Playbooks Reference](../contrib/scripts-playbooks.md)** — orchestration patterns and examples

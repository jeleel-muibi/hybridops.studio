# Deployment — Playbooks, Inventories & GitOps

Operational playbooks, inventories, and GitOps overlays used to bring up and run HybridOps.Studio.  
This area is runnable and intentionally concise; deeper guidance lives on the docs site at **[docs.hybridops.studio](https://docs.hybridops.studio)**.

---

## Scope

This tree provides:

- **Domain playbooks** – `linux/`, `windows/`, `netbox/`, `network_config/`, `kubernetes/`, `moodle/`
- **Inventories** – static / env-based → NetBox / Nornir handoff
- **GitOps overlays** – Kustomize structure for Kubernetes workloads (dev, stage, dr)
- **Orchestration hooks** – invoked via the root **Makefile** and **control** wrappers

> Reusable logic (roles, plugins, modules) lives in standalone **hybridops.\*** Ansible collections.  
> `deployment/` contains the environment-specific glue that *consumes* those collections.

---

## Inventories and Source of Truth

Inventories live under `deployment/inventories/`:

```text
deployment/inventories/
  ansible/
    static/    # bootstrap hosts, minimal facts
    env/       # env-derived inventory (if used)
    netbox/    # NetBox dynamic inventory
  nornir/
    ...        # Nornir inventory (YAML or plugin-specific)
```

Typical SoT handoff:

1. **Bootstrap** with the static inventory to baseline hosts (SSH, users, agents, etc.).
2. **Seed NetBox** from Terraform outputs.
3. **Switch Ansible** to the NetBox inventory for ongoing operations.

Examples:

```bash
# Inspect inventory from NetBox
ansible-inventory -i deployment/inventories/ansible/netbox/netbox.yml --graph

# Example baseline run from NetBox inventory
ansible-playbook \
  -i deployment/inventories/ansible/netbox/netbox.yml \
  deployment/linux/playbooks/baseline.yml
```

Secrets are not committed. Provide them via:

- Ansible Vault files (encrypted), or
- CI-secured variables / secret stores.

---

## Makefile routing (from repo root)

The root `Makefile` forwards targets to per-domain Makefiles under `deployment/`.

```bash
make env.setup sanity

# Examples (domain-level)
make linux.rke2_install_server
make kubernetes.gitops_bootstrap
make netbox.seed
make windows.domain_join
make network.configure_bgp
```

You can override inventory per run:

```bash
INVENTORY=deployment/inventories/ansible/static/hosts.ini \
  make linux.rke2_install_server
```

Logs are written under:

```text
output/
  artifacts/
    ansible-runs/<domain>/
  logs/
    ansible/
```

---

## GitOps and Workloads

GitOps overlays and workload definitions live under `deployment/k8s_workload/gitops/`:

```text
deployment/k8s_workload/gitops/
  base/       # shared base manifests
  apps/       # application definitions
  overlays/   # dev / stage / dr overlays
```

Examples:

```bash
# Build overlays locally or in CI
kustomize build deployment/k8s_workload/gitops/overlays/dev   > output/gitops_dev.yaml
kustomize build deployment/k8s_workload/gitops/overlays/stage > output/gitops_stage.yaml
kustomize build deployment/k8s_workload/gitops/overlays/dr    > output/gitops_dr.yaml
```

Argo CD (or another GitOps controller) can then watch the appropriate paths and apply these manifests.

---

## Layout (high level)

```text
deployment/
  inventories/
    ansible/
      static/        # initial bootstrap inventory
      env/           # env-derived inventory (optional)
      netbox/        # NetBox dynamic inventory
    nornir/          # Nornir inventory files
  linux/             # Linux host configuration playbooks, files, templates, vars
  windows/           # Windows host configuration
  netbox/            # NetBox bootstrap and seeding
  network_config/    # Network device configuration (BGP, VLANs, backups, etc.)
  kubernetes/        # Cluster-level configuration playbooks
  k8s_workload/
    gitops/          # app/base/overlays for GitOps
  moodle/            # Moodle stack (Ansible + Docker config)
```

---

## Related

For design rationale, detailed HOWTOs and runbooks, see the docs site:

- **[Deployment and operations overview](https://docs.hybridops.studio/ops/deployment-overview/)**  
- **[Ansible collections (hybridops.\*)](https://docs.hybridops.studio/ansible/collections/)**  
- **[GitOps and workloads](https://docs.hybridops.studio/gitops/overview/)**

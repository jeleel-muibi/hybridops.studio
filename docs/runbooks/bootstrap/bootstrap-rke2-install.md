---
title: "Bootstrap: RKE2 (On-Prem)"
category: bootstrap
summary: "Provision VMs, harden Linux, and install RKE2 control plane and workers."
last_updated: 2025-10-08
severity: P1
---

# Bootstrap: RKE2 (On‑Prem)

**Purpose:** Provision Linux VMs, harden them, and install RKE2 control/workers.
**Owner:** Platform SRE · **When:** Cluster creation/rebuild.
**Time:** 30–45m

## Pre‑requisites
- Proxmox (or chosen hypervisor) credentials/config.
- Ansible control node with SSH reachability to provisioned VMs.
- `deployment/linux/playbooks/baseline.yml` ready (users, SSH, hardening).

## Rollback
- Destroy VMs via Terraform, or `rke2-killall.sh && rke2-uninstall.sh` on nodes.

## Steps

1) **Provision VMs (Terraform)**
```bash
make linux.bootstrap   # or: terraform -chdir=terraform-infra/environments/onprem/dev apply
```

2) **Baseline hardening (Ansible)**
```bash
ANSIBLE_LOG_PATH=output/logs/ansible/$(date -Iseconds)_linux_baseline.log ansible-playbook -i deployment/inventories/bootstrap/hosts.ini   deployment/linux/playbooks/baseline.yml
```

3) **Install RKE2**
```bash
ansible-playbook -i deployment/inventories/bootstrap/hosts.ini   deployment/kubernetes/playbooks/rke2_install.yml
```

4) **Join workers & verify**
```bash
kubectl --kubeconfig ~/.kube/onprem get nodes -o wide   | tee "output/artifacts/inventories/$(date -Iseconds)_rke2_nodes.txt"
```

## Verification
- `kubectl get nodes` shows all nodes `Ready`.
- Optional: Rancher sees a healthy cluster.

## Artifacts
- Baseline log, node list, kubeconfig path snapshot → `output/artifacts/inventories/`.

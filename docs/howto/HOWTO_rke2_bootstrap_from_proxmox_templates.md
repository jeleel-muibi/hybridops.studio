---
title: "Bootstrap an RKE2 Cluster from Proxmox Templates"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Use Terraform and Ansible to create RKE2 nodes from Proxmox templates and bring up the primary HybridOps.Studio cluster with evidence capture."
difficulty: "Intermediate"

topic: "rke2-bootstrap"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["rke2", "kubernetes", "proxmox", "terraform", "ansible"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Bootstrap an RKE2 Cluster from Proxmox Templates

This HOWTO shows how to use **Packer-built Proxmox templates**, **Terraform**, and **Ansible** to bootstrap the main **RKE2 cluster** for HybridOps.Studio, and where to capture **proof artefacts** for Evidence 4.

It assumes that:

- Proxmox VM templates already exist, built using the standard Packer pipeline per [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md).
- RKE2 is the primary runtime per [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md).

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Use Terraform to create RKE2 control-plane and worker VMs from Proxmox templates.
- Use Ansible to install and configure RKE2 on those nodes.
- Verify that the cluster is healthy with `kubectl`.
- Store logs and artefacts under [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/) so another engineer or assessor can verify the process.

---

## 2. Prerequisites

### 2.1 Infrastructure and access

You should have:

- A Proxmox cluster reachable from your control node and/or Jenkins agent.
- Packer-built templates available in Proxmox, for example:
  - `tpl-ubuntu-22.04` for RKE2 nodes.
- Network configuration aligned with ADR-0015 (for example, management and workload networks).
- SSH access to the nodes via cloud-init or injected keys.

### 2.2 Code layout

The exact paths may vary, but this HOWTO assumes:

- Terraform configuration for the RKE2 cluster under something like:

  - [`infra/terraform/live-v1/rke2-cluster/`](../../infra/terraform/live-v1/rke2-cluster/)

- Ansible playbooks and roles for RKE2 under something like:

  - [`core/ansible/rke2/`](../../core/ansible/rke2/)

- A proof folder for RKE2 operations:

  - [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)

Adjust paths to match your actual repository layout.

### 2.3 Credentials and environment

You will need:

- Proxmox API credentials (token ID and secret) available as environment variables or Terraform variables.
- SSH keys or credentials for Ansible to connect to the new nodes.
- `kubectl` available on the control node, configured to talk to the RKE2 cluster once bootstrapped.

### 2.4 Related decisions and docs

- [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

## 3. Prepare Terraform variables

1. Navigate to the RKE2 Terraform directory, for example:

   ```bash
   cd infra/terraform/live-v1/rke2-cluster/
   ```

2. Copy the example variables file if necessary:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` to reference the correct Proxmox templates and node sizes, for example:

   ```hcl
   proxmox_endpoint   = "https://<PROXMOX_IP>:8006/api2/json"
   proxmox_token_id   = "automation@pam!infra-token"
   proxmox_token_secret = "<SECRET>"

   rke2_template_name = "tpl-ubuntu-22.04"

   rke2_controlplane_count = 3
   rke2_worker_count       = 2

   rke2_network_name = "vmbr0"
   ```

4. Save the file and keep it out of version control if it contains secrets.

---

## 4. Create RKE2 VMs with Terraform

1. Initialise the Terraform working directory:

   ```bash
   terraform init
   ```

2. Review the plan to see which VMs will be created:

   ```bash
   terraform plan -out=tfplan-rke2-bootstrap
   ```

3. Apply the plan:

   ```bash
   terraform apply tfplan-rke2-bootstrap
   ```

4. Wait for Terraform to complete. When finished, it should output:

   - IP addresses or hostnames of the control-plane nodes.
   - IP addresses or hostnames of the worker nodes.

5. Capture the plan and apply output into the proof folder, for example:

   ```bash
   mkdir -p docs/proof/infra/rke2/$(date -Iseconds)
   terraform show tfplan-rke2-bootstrap > docs/proof/infra/rke2/$(date -Iseconds)/terraform-plan.txt
   ```

   Adjust the folder name pattern if you already have a standard.

---

## 5. Install and configure RKE2 with Ansible

1. Navigate to the Ansible RKE2 playbook directory, for example:

   ```bash
   cd core/ansible/rke2/
   ```

2. Ensure your inventory file lists the control-plane and worker nodes created by Terraform, for example:

   ```ini
   [rke2_controlplane]
   cp-01 ansible_host=10.0.0.11
   cp-02 ansible_host=10.0.0.12
   cp-03 ansible_host=10.0.0.13

   [rke2_workers]
   wk-01 ansible_host=10.0.1.21
   wk-02 ansible_host=10.0.1.22
   ```

3. Run the Ansible playbook to install and configure RKE2:

   ```bash
   ansible-playbook -i inventory.ini site-rke2.yml
   ```

4. Monitor the output for:

   - Installation of RKE2 server and agent components.
   - Configuration of systemd services.
   - Retrieval of the kubeconfig file to a known location (for example, `/etc/rancher/rke2/rke2.yaml` on the first control-plane node or copied back to the control node).

5. Save the Ansible run log into the proof folder:

   ```bash
   ansible-playbook -i inventory.ini site-rke2.yml | tee docs/proof/infra/rke2/$(date -Iseconds)/ansible-rke2-bootstrap.log
   ```

---

## 6. Verify the RKE2 cluster

1. On the control node (or your workstation with access), configure `kubectl` to use the RKE2 kubeconfig, for example:

   ```bash
   export KUBECONFIG=~/.kube/rke2-hybridops.yaml
   ```

2. Check node status:

   ```bash
   kubectl get nodes -o wide
   ```

   You should see all control-plane and worker nodes in `Ready` state.

3. Verify core components (namespaces and pods), for example:

   ```bash
   kubectl get ns
   kubectl get pods -A
   ```

4. Capture selected `kubectl` outputs into the proof folder:

   ```bash
   kubectl get nodes -o wide > docs/proof/infra/rke2/$(date -Iseconds)/kubectl-get-nodes.txt
   kubectl get pods -A > docs/proof/infra/rke2/$(date -Iseconds)/kubectl-get-pods-all.txt
   ```

These commands provide a minimum evidence set that the cluster is up and functioning.

---

## 7. Optional: Tag the cluster for DR and cost modelling

If your Terraform or Ansible roles support tagging or labelling for DR and cost modelling:

1. Ensure nodes or namespaces are labelled with environment and role, for example:

   ```bash
   kubectl label node cp-01 env=onprem role=controlplane
   kubectl label node wk-01 env=onprem role=worker
   ```

2. Confirm that these labels appear in Prometheus metrics and cost artefacts, where applicable.

This helps link the cluster to DR and cost decisions described in ADR-0701 and ADR-0801.

---

## 8. Validation checklist

Use this checklist to confirm bootstrap is complete:

- [ ] Terraform created the expected RKE2 control-plane and worker VMs from the correct Proxmox template.  
- [ ] Ansible successfully installed and started RKE2 on all nodes.  
- [ ] `kubectl get nodes` shows all nodes in `Ready` state.  
- [ ] Core namespaces and system pods are running without crash loops.  
- [ ] Evidence artefacts (Terraform plan/apply output, Ansible logs, `kubectl` snapshots) exist under [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/).  
- [ ] Any DR or cost labels/metadata are applied if you are using them.

---

## References

- [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

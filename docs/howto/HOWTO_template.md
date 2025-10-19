---
title: "HOWTO Template"
category: "howto"
summary: "Template for authoring new HOWTO guides (excluded from index)."
difficulty: "Intermediate"
video: ""                # optional — YouTube demo link
source: ""               # optional — GitHub or script reference
draft: true              # ensures it’s skipped from the index
template: true           # double assurance for filtering
# tags: ["template", "skip"]
---

# <Short, Descriptive Title>

**Demo:** [Watch on YouTube](${video})  
**Source:** [View Script on GitHub](${source})

> This HOWTO is part of the **HybridOps.Studio Learning Series** — a collection of self-contained, reproducible guides that accompany the live demo and runbook library.

---

## Objective

Explain in one or two sentences what the reader will achieve and what problem this HOWTO solves.

**Example:**  
Deploy a zero-touch control plane (`ctrl-01`) on Proxmox and validate that it self-configures from Git within 10 minutes.

---

## Context

- This HOWTO complements the operational [Runbook: bootstrap-ctrl01-node](../runbooks/bootstrap/bootstrap-ctrl01-node.md).  
- It is suitable for workshops, public demos, and reviewers exploring the automation flow.  
- No prior environment is required beyond SSH access to a Proxmox host.

---

## Steps

1. **Prepare the Proxmox environment**
   ```bash
   ssh root@<proxmox-host>
   apt install -y qemu-guest-agent curl jq
   ```
   > Verify: network and storage ready for VM creation.

2. **Fetch and run the control node provisioner**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jeleel-muibi/hybridops.studio/main/control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh      -o /root/provision-ctrl01.sh && sudo bash /root/provision-ctrl01.sh
   ```
   > Observe: VM spins up and cloud-init bootstraps Day-1 automatically.

3. **Verify the outcome**
   ```bash
   ssh ubuntu@172.16.10.5
   sudo tail -n 100 /var/log/ctrl01_bootstrap.log
   ```
   > Jenkins should be online and emitting audit evidence.

---

## Expected Outcome

By the end of this HOWTO, you should see:
- Jenkins controller operational (`ctrl-01`)  
- Evidence logs in `/var/log/ctrl01_bootstrap.log`  
- Git-synced Day-1 configuration complete  

---

## References

- [Runbook: bootstrap-ctrl01-node](../runbooks/bootstrap/bootstrap-ctrl01-node.md)  
- [Evidence Map](../evidence_map.md)  
- [YouTube Demo](${video})  
- [HybridOps.Studio Repository](https://github.com/jeleel-muibi/hybridops.studio)

---

**Author:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0

---
title: "Network Infrastructure Prerequisites"
category: "prerequisites"
summary: "Required network infrastructure for Packer template builds on Proxmox VE."
related: ["../adr/ADR-0015-network-infrastructure-assumptions.md"]
---

# Network Infrastructure Prerequisites

> **Context:** See [ADR-0015 — Network Infrastructure Assumptions](../adr/ADR-0015-network-infrastructure-assumptions.md) for decision rationale.

Packer template builds require **enterprise-standard network infrastructure** in place before execution.

---

## Required Components

### Management Network
- **Bridge:** `vmbr0` (or equivalent) uplinked to management network
- **DHCP:** Active with available leases
- **DNS:** Recursive or corporate DNS resolving external domains
- **Internet:** Outbound access to package repositories (or internal mirrors)

**Proxmox Bridge Example:**
```bash
# /etc/network/interfaces
auto vmbr0
iface vmbr0 inet manual
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
```

**Verification:**
```bash
# Bridge exists
ip link show vmbr0

# DHCP responds (from test VM)
dhclient -v ens18

# Connectivity
ping -c2 8.8.8.8
curl -I https://releases.ubuntu.com
```

---

## ISO Management

**ISO Configuration:** Per-template `.pkrvars.hcl` files

**Example (Linux):** `linux/ubuntu/ubuntu-22.04.pkrvars.hcl`
```hcl
iso_file     = "local:iso/ubuntu-22.04.1-live-server-amd64.iso"
iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
iso_checksum = "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
```

**Example (Windows):** `windows/server/windows-server-2022.pkrvars.hcl`
```hcl
iso_file     = "local:iso/windows-server-2022.iso"
iso_checksum = "sha256:xxxxx"
```

**Storage Location:**
- Local: `/var/lib/vz/template/iso/`
- Network: NFS/CIFS (if configured)

**Verification:**
```bash
ssh root@proxmox 'ls -lh /var/lib/vz/template/iso/'
```

**Prestaging:**
ISOs are automatically downloaded and validated during builds. Manual prestaging:
```bash
# Linux
control/tools/provision/packer/bin/prestage-iso.sh <proxmox-ip> \
  --pkrvars linux/ubuntu/ubuntu-22.04.pkrvars.hcl iso

# Windows
control/tools/provision/packer/bin/prestage-iso.sh <proxmox-ip> \
  --pkrvars windows/server/windows-server-2022.pkrvars.hcl iso
```

---

## Responsibility Matrix

| Component | Owner | Phase |
|-----------|-------|-------|
| Physical switching | Network Team | Pre-deployment |
| VLANs, DHCP, DNS | Network Team | Pre-deployment |
| Proxmox bridges | Platform Team | Terraform (Phase 2) |
| VM templates | Platform Team | Packer (Phase 1) |
| VM provisioning | Platform Team | Terraform (Phase 3) |
| VM configuration | Platform Team | Ansible (Phase 4) |

---

## Troubleshooting

### Bridge Not Found
```bash
ip -br link show type bridge
```

### DHCP Not Responding
```bash
tcpdump -i vmbr0 port 67 or port 68
```

### DNS Not Resolving
```bash
resolvectl status
dig @8.8.8.8 releases.ubuntu.com
```

### No Internet Access
```bash
ip route show
iptables -t nat -L POSTROUTING -n -v
```

---

## Related Documentation
- [ADR-0015 — Network Infrastructure Assumptions](../adr/ADR-0015-network-infrastructure-assumptions.md)
- [ADR-0016 — Packer + Cloud-Init VM Templates](../adr/ADR-0016-packer-cloudinit-vm-templates.md)
- [HOWTO — Build Your First Packer Template](../howtos/HOWTO_packer_proxmox_template.md)
- [Runbook — Proxmox VM Template Build](../runbooks/platform/packer-proxmox-template-build.md)

---

**Last Updated:** 2025-11-17 21:02 UTC · **Project:** HybridOps.Studio

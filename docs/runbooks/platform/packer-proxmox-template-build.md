---
title: "Build Proxmox VM Templates with Packer"
category: "platform"
summary: "Operational runbook for building VM templates on Proxmox VE using Packer."
severity: "P2"
trigger: "New base image required / monthly refresh / CVE patching"
eta: "<10 minutes per template"
---

# Build Proxmox VM Templates with Packer

**Purpose:** Reproducible VM template builds on Proxmox VE using HashiCorp Packer  
**Audience:** Platform engineers  
**Frequency:** Monthly refresh or on-demand for CVE patches

> **Templates:** [infra/packer-multi-os](../../../infra/packer-multi-os/) · **Toolkit:** [control/tools/provision/packer](../../../control/tools/provision/packer/) · **HOWTO:** [First Build Guide](../../howtos/HOWTO_packer_proxmox_template.md)

---

## Preconditions

- Proxmox VE 7.x/8.x with root SSH access
- Workstation: Packer ≥1.10, `make`, `ssh`, `curl`
- Repository: `git clone <repo-url> ~/hybridops-studio`
- Network: DHCP-enabled bridge (see [ADR-0015](../../adr/ADR-0015-network-infrastructure-assumptions.md))

---

## Standard Operating Procedure

### 1 — Initialise Proxmox API env (first run or after changes)

From the repository root:

```bash
cd infra/packer-multi-os
make init


See [HOWTO Step 2](../../howtos/HOWTO_packer_proxmox_template.md#step-2-initialize-proxmox-api) for details.

**Repeat only if:**
- `.env` deleted or credentials expired
- Proxmox node/storage configuration changes

---

### 2. Validate Templates

```bash
make validate
```

**Expected:** All templates pass HCL validation

**Failures:**
```bash
make clean
make check-env
make validate
```

---

### 3. Build Template

**Linux:**
```bash
make build-ubuntu-22.04   # <10 min, VMID 9000
make build-rocky-9        # <10 min, VMID 9002
```

**Windows:**
```bash
make build-windows-server-2022      # <10 min, VMID 9100
make build-windows-11-enterprise    # <10 min, VMID 9102
```

See [Available Templates](../../../infra/packer-multi-os/README.md#available-templates) for full list.

**Monitor:**
```bash
tail -f output/logs/packer/builds/<template>/latest/packer.log
```

---

### 4. Verify Template

```bash
# Check template exists
ssh root@192.168.0.27 'qm list | grep template'

# Verify configuration
ssh root@192.168.0.27 'qm config 9000 | grep -E "template|agent|ide2"'
```

**Expected:**
- `template: 1`
- `agent: 1`
- `ide2: local:cloudinit` (Linux templates)

**Web UI:** `https://192.168.0.27:8006` → Node → VMs (templates have 📦 icon)

---

## Verification Checklist

### Linux Templates
- [ ] Build time <10 minutes
- [ ] Cloud-init drive present (`qm config <vmid> | grep ide2`)
- [ ] QEMU Guest Agent installed
- [ ] SSH key injected correctly
- [ ] Package updates applied
- [ ] Evidence artifacts generated

### Windows Templates
- [ ] Build time <10 minutes
- [ ] Cloudbase-Init installed
- [ ] QEMU Guest Agent installed
- [ ] Sysprep completed
- [ ] WinRM disabled in template
- [ ] Evidence artifacts generated

---

## Common Issues

### Permission Errors (403)

**Symptom:** `403 Forbidden` during build

**Fix:**
```bash
make init  # Re-creates API token with correct ACLs
```

**Required ACLs:**
- `Datastore.Audit` + `Datastore.AllocateSpace` on storage
- `SDN.Use` (if SDN enabled)
- `VM.Allocate`, `VM.Config.*` on `/vms`

---

### VMID Conflicts

**Symptom:** "VM <vmid> already exists"

**Resolution:** Automatic (build-wrapper auto-increments)

**Logs show:**
```
INFO: VMID 9000 in use, using 9001 instead
INFO: Starting Packer build with VMID 9001...
```

**Manual override:**
```bash
UBUNTU22_VMID=9100 make build-ubuntu-22.04
```

---

### Network Issues

**No DHCP:**
- Verify DHCP service on bridge network
- See [ADR-0015](../../adr/ADR-0015-network-infrastructure-assumptions.md) for prerequisites

**No Internet:**
```bash
# Check bridge routing
ssh root@192.168.0.27 'ip route show'

# Check firewall
ssh root@192.168.0.27 'iptables -L -n'
```

---

### Build Failures

**ISO not found:**
```bash
# Upload ISO manually
scp ubuntu-22.04.5-live-server-amd64.iso root@192.168.0.27:/var/lib/vz/template/iso/

# Or use prestage script
../../control/tools/provision/packer/bin/prestage-iso.sh 192.168.0.27 \
  --pkrvars linux/ubuntu/ubuntu-22.04.pkrvars.hcl iso
```

**Packer plugin errors:**
```bash
cd linux/ubuntu
packer init .
```

**Boot command timeout:**
- Adjust `boot_wait` in `.pkrvars.hcl`
- Console into VM via Proxmox UI to debug

---

### SSH/WinRM Timeout

**Linux:**
```bash
# Check SSH service started
ssh root@192.168.0.27 'qm guest exec <vmid> -- systemctl status ssh'
```

**Windows:**
```bash
# Check WinRM enabled (should be disabled in template)
ssh root@192.168.0.27 'qm guest exec <vmid> -- powershell Get-Service WinRM'
```

---

## Maintenance

### Monthly Template Refresh
```bash
make build-ubuntu-22.04
make build-ubuntu-24.04
make build-rocky-9
make build-windows-server-2022
```

### Token Rotation
```bash
make init  # Generates new API token
```

### Evidence Review
```bash
cat docs/proof/platform/packer-builds/builds/ubuntu-2204/latest/README.md
```

### Cleanup Old Templates
```bash
# List templates
ssh root@192.168.0.27 'qm list | grep template'

# Delete old template
ssh root@192.168.0.27 'qm destroy 9000'
```

---

## Chain ID Correlation

All build artifacts share a chain ID for audit traceability:

```bash
# From log file (first line)
head -1 output/logs/packer/builds/rocky-9/latest/packer.log
# [CHAIN] CHAIN_ID=CHAIN-20251117T220037Z-rocky-9

# From chain.id file
cat output/logs/packer/builds/rocky-9/latest/chain.id
# CHAIN-20251117T220037Z-rocky-9

# Find all related artifacts
grep -r "CHAIN-20251117T220037Z-rocky-9" output/ docs/
```

See [Toolkit README — Evidence Output](../../../control/tools/provision/packer/README.md#evidence-output) for structure.

---

## References

- [Template README](../../../infra/packer-multi-os/README.md)
- [Toolkit README](../../../control/tools/provision/packer/README.md)
- [HOWTO — First Build](../../howtos/HOWTO_packer_proxmox_template.md)
- [ADR-0016 — Packer + Cloud-Init](../../adr/ADR-0016-packer-cloudinit-vm-templates.md)
- [ADR-0015 — Network Infrastructure](../../adr/ADR-0015-network-infrastructure-assumptions.md)

---

**Maintainer:** HybridOps. Studio  
**Last Updated:** 2025-11-17 22:00 UTC

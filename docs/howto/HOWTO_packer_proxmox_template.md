---
title: "Build Your First Proxmox VM Template with Packer"
category: "howto"
summary: "Step-by-step guide to build production-ready VM templates on Proxmox VE using Packer and cloud-init."
difficulty: "Intermediate"
source: "infra/packer-multi-os"
---

# Build Your First Proxmox VM Template with Packer

> **Templates:** [Packer workspace](../../infra/packer-multi-os/) · **Toolkit:** [Provisioning tools](../../control/tools/provision/packer/) · **Architecture:** [ADR-0016 — Packer + Cloud-Init VM Templates](../adr/ADR-0016-packer-cloudinit-vm-templates.md)

---

## Objective

Create golden VM templates on Proxmox VE using HashiCorp Packer with automated installation.

**Supported:**

- **Linux:** Ubuntu 22.04/24.04, Rocky Linux 9/10 (cloud-init)
- **Windows:** Server 2022/2025, Windows 11 Enterprise (Cloudbase-Init)

---

## Prerequisites

- **Proxmox VE** 7.x/8.x with root SSH access
- **Workstation:** Packer ≥1.10, SSH client, Make
- **Network:** DHCP-enabled bridge (see [ADR-0015 — Network Infrastructure](../adr/ADR-0015-network-infrastructure-assumptions.md))
- **Repository:**
  ```bash
  git clone <repo-url> ~/hybridops-studio
  cd ~/hybridops-studio
  ```

---

## Step 1: Configure Proxmox Connection

Create `control/tools/provision/packer/proxmox.conf`:

```bash
PROXMOX_IP=192.168.0.27
USER_FQ=automation@pam
TOKEN_NAME=infra-token
FALLBACK_STORAGE_VM=local-lvm
FALLBACK_STORAGE_ISO=local
FALLBACK_BRIDGE=vmbr0
HTTP_PORT=8802
TLS_SKIP=true
```

**Key fields:**

- `PROXMOX_IP` — Proxmox node IP address
- `USER_FQ` — Proxmox user (PAM)
- `TOKEN_NAME` — API token name
- `FALLBACK_STORAGE_VM` / `FALLBACK_STORAGE_ISO` — Used if auto-detection fails
- `FALLBACK_BRIDGE` — Network bridge for builds
- `HTTP_PORT` — Local HTTP server port for autoinstall configs
- `TLS_SKIP` — `true` for self-signed certs, `false` for valid TLS

---

## Step 2: Initialize Proxmox API

From the Packer workspace:

```bash
cd infra/packer-multi-os
make init
```

**This step:**

1. Uploads your SSH key to Proxmox
2. Creates `automation@pam` with least-privilege ACLs
3. Generates an API token
4. Auto-detects node, storage pools, network bridge
5. Writes `infra/env/.env.proxmox` with Packer variables
6. Renders unattended installation templates (cloud-init / Autounattend)
7. Creates init proof under `docs/proof/platform/packer-builds/init/`

**Generated env file (excerpt):**

```bash
PROXMOX_URL=https://192.168.0.27:8006/api2/json
PROXMOX_TOKEN_ID=automation@pam!infra-token
PROXMOX_TOKEN_SECRET=<secret>
PROXMOX_NODE=pve
PROXMOX_STORAGE_VM=local-lvm
PROXMOX_BRIDGE=vmbr0
PACKER_HTTP_BIND_ADDRESS=192.168.0.26
PACKER_HTTP_PORT=8802
```

**Logs:** `output/logs/packer/init/latest/init-packer.log`

---

## Step 3: Validate Templates

Run:

```bash
make validate
```

**Expected output (summary):**

```text
=== Packer Validation ===

Linux Templates:
  ✓ Ubuntu 22.04 LTS
  ✓ Ubuntu 24.04 LTS
  ✓ Rocky Linux 9
  ✓ Rocky Linux 10

Windows Templates:
  ✓ Windows Server 2022
  ✓ Windows Server 2025
  ✓ Windows 11 Enterprise

✓ All validations passed
```

If validation fails, see the [Runbook — Template Build](../runbooks/platform/packer-proxmox-template-build.md) for troubleshooting steps.

---

## Step 4: Build Your First Template

### Linux (recommended first build)

```bash
make build-ubuntu-22.04
```

**Build flow:**

1. ISO boots on Proxmox
2. Local HTTP server serves `user-data` (cloud-init autoinstall)
3. OS installs unattended (DHCP during build)
4. Provisioning:
   - Package updates
   - QEMU Guest Agent
   - Cloud-init configuration
   - Security baseline
5. VM is converted to a Proxmox template

**Defaults:**

- **Build time:** Typically <10 minutes
- **VMID:** `9000`  
  Override if needed:

```bash
UBUNTU22_VMID=9100 make build-ubuntu-22.04
```

### Windows

```bash
make build-windows-server-2022
```

**Build flow:**

1. Windows ISO boots
2. `Autounattend.xml` provides installation answers
3. Cloudbase-Init is installed and configured
4. Sysprep generalizes the image
5. VM is converted to a Proxmox template

**Defaults:**

- **Build time:** Typically <10 minutes
- **VMID:** `9100`  
  Override if needed:

```bash
WIN2022_VMID=9300 make build-windows-server-2022
```

---

## Step 5: Verify Template

From your workstation:

```bash
# Confirm template exists
ssh root@192.168.0.27 'qm list | grep template'

# Inspect template configuration (example: Ubuntu 22.04, VMID 9000)
ssh root@192.168.0.27 'qm config 9000 | grep -E "template|agent|ide2"'
```

**Expected flags (Linux):**

- `template: 1`
- `agent: 1`
- `ide2: local:cloudinit`

You can also verify in the Proxmox web UI:

- `https://192.168.0.27:8006` → Node → VMs  
  Templates show with the 📦 icon.

---

## Build Monitoring

### Watch logs during build

```bash
tail -f output/logs/packer/builds/ubuntu-2204/latest/packer.log
```

### Evidence and proof artifacts

See **Toolkit README → Evidence Output** in:

- [Provisioning toolkit README](../../control/tools/provision/packer/README.md#evidence-output)

for the structure of logs and proof archives.

---

## Troubleshooting

### Permission errors (HTTP 403)

Re-run initialization to refresh ACLs and tokens:

```bash
make init
```

### VMID conflicts

- **Automatic:** The build wrapper auto-increments VMIDs (9000 → 9001, etc.)
- **Manual:** Override via environment variables, for example:

```bash
UBUNTU22_VMID=9100 make build-ubuntu-22.04
WIN2022_VMID=9300 make build-windows-server-2022
```

### ISO not found

Upload the ISO to the Proxmox ISO storage:

```bash
scp ubuntu-22.04.5-live-server-amd64.iso   root@192.168.0.27:/var/lib/vz/template/iso/
```

Confirm the storage path matches the one configured in Proxmox and in your `infra/env/.env.proxmox`.

### Network issues

- **No DHCP:** Engage the network team to provide DHCP on the build VLAN or bridge (per [ADR-0015](../adr/ADR-0015-network-infrastructure-assumptions.md)).
- **No Internet:** Check routing and firewall rules from the Proxmox host.

### Plugin or init errors

From a specific template directory (for example, Ubuntu):

```bash
cd linux/ubuntu
packer init .
```

For more detailed failure analysis, follow the steps in the [Runbook — Template Build](../runbooks/platform/packer-proxmox-template-build.md).

---

## Next Steps

### Clone templates with Terraform

Example `proxmox_vm_qemu` resource:

```hcl
resource "proxmox_vm_qemu" "web" {
  name  = "web-01"
  clone = "ubuntu-2204-template"

  ipconfig0 = "ip=10.10.1.100/24,gw=10.10.1.1"
  ciuser    = "ubuntu"
  sshkeys   = file("~/.ssh/id_ed25519.pub")
}
```

### Configure new VMs with Ansible

Example play:

```yaml
- hosts: new_vms
  roles:
    - common
    - security-baseline
```

### Keep templates fresh

Run periodic rebuilds to pull in OS and security updates:

```bash
make build-ubuntu-22.04
make build-rocky-9
make build-windows-server-2022
```

Integrate these into a monthly or quarterly maintenance window, and capture new proof artifacts for compliance.

---

## Related Guides

- Guide: [Packer Templates Overview](../../infra/packer-multi-os/README.md)
- Guide: [Provisioning Toolkit](../../control/tools/provision/packer/README.md)
- Runbook: [Template Build Operations](../runbooks/platform/packer-proxmox-template-build.md)
- ADR: [ADR-0016 — Packer + Cloud-Init VM Templates](../adr/ADR-0016-packer-cloudinit-vm-templates.md)
- ADR: [ADR-0015 — Network Infrastructure Assumptions](../adr/ADR-0015-network-infrastructure-assumptions.md)

---

**Author:** jeleel-muibi  
**Last Updated:** 2025-11-17 21:58 UTC

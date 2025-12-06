---
title: "HOWTO: Use Nornir + NETCONF to Collect Evidence from CSR1000v"
category: "networking"
summary: "Learning guide for wiring Cisco CSR1000v into a Nornir-based NETCONF evidence pipeline."
difficulty: "Intermediate"

topic: "netconf-nornir-evidence"

video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
source: ""

draft: false
tags: ["netconf", "nornir", "csr1000v", "automation", "adr-0602"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Use Nornir + NETCONF to Collect Evidence from CSR1000v

**Purpose:**  
Show how to move from **plain SSH CLI** to **NETCONF-driven, Nornir‑based evidence collection** on Cisco CSR1000v, aligned with [ADR‑0602 – NETCONF and Nornir Automation for CSR1000v](../../adr/ADR-0602-netconf-nornir-automation-csr1000v.md).

You will:

- Enable NETCONF safely on CSR1000v.
- Build a minimal Nornir inventory for CSR endpoints.
- Run a collector that saves structured XML/YANG state under `docs/proof/networking/netconf-csr1000v/`.

This is a **learning guide**, not an incident runbook. Use it to understand and rehearse the pattern; runbooks will link back here for deeper background.

---

## Demo / Walk-through

??? info "▶ Watch the NETCONF + Nornir evidence demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="NETCONF + Nornir Evidence Collection – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. NETCONF vs CLI – Why Bother?

Traditional SSH/CLI scraping:

- Parses unstructured text (fragile and vendor‑specific).
- Makes it hard to do diffing, validation, and correlation in pipelines.
- Does not map cleanly to data models.

NETCONF with YANG models:

- Returns **structured XML** (or JSON) based on well‑defined schemas.
- Supports **transactional operations** and rollback (candidate vs running‑config).
- Works consistently across platforms that implement the same models.

In HybridOps.Studio, NETCONF + Nornir gives you:

- Repeatable, machine‑readable evidence of router state for audits.
- A foundation for pre/post‑change validation in CI/CD.
- A vendor‑agnostic path as you extend from CSR to vEOS / vSRX later.

See [ADR‑0602](../../adr/ADR-0602-netconf-nornir-automation-csr1000v.md) for the architectural decision.

---

## 2. Lab Assumptions and Prerequisites

### 2.1 Topology Assumptions

- At least one CSR1000v VM (for example `csr-lab-01`) reachable from the automation host.
- Management network that allows:
  - SSH on port **22**.
  - NETCONF over SSH on port **830**.
- Git repo layout similar to:

```text
core/
  automation/
    networking/
      nornir/
        inventory/
          hosts.yaml
          groups.yaml
          defaults.yaml
        tasks/
          netconf_collect.py
docs/
  proof/
    networking/
      netconf-csr1000v/
```

### 2.2 Software Prerequisites

On the automation host:

- Python **3.10+** (or similar).
- Virtual environment created (recommended).
- Packages:

```bash
pip install nornir nornir-utils nornir-netmiko ncclient
```

- Access to the HybridOps.Studio repo (or equivalent layout) so the collector can write into `docs/proof/networking/netconf-csr1000v/`.

---

## 3. Enabling NETCONF on CSR1000v

> **Goal:** Turn on NETCONF over SSH securely, with restricted access.

### 3.1 Backup Existing Config

On CSR:

```bash
copy running-config bootflash:pre-netconf-backup.cfg
```

### 3.2 Enable NETCONF Over SSH

Example minimal config:

```bash
conf t
 !
 username netconf-admin privilege 15 secret 0 STRONG_PASSWORD
 !
 ip access-list standard ACL_NETCONF_MGMT
  permit 10.10.0.0 0.0.0.255      ! Management VLAN
  permit 192.168.0.0 0.0.0.255    ! Jump host / lab
 !
 line vty 0 4
  transport input ssh
 !
 netconf-yang
 !
 xml agent tty
 !
 ip ssh version 2
 ip ssh source-interface GigabitEthernet1
 !
 ip access-list standard ACL_NETCONF_MGMT
  permit 10.10.0.0 0.0.0.255
  permit 192.168.0.0 0.0.0.255
 !
 ip ssh access-group ACL_NETCONF_MGMT
end
write memory
```

Key points:

- Use a **dedicated account** (for example `netconf-admin`).
- Restrict access with an ACL bound to SSH.
- Enable `netconf-yang` globally.

### 3.3 Verify NETCONF Status

From the router:

```bash
show netconf-yang status
show netconf-yang sessions
```

From the automation host (basic sanity):

```bash
nc -vz csr-lab-01 830
```

If port 830 is reachable and `netconf-yang` is enabled, you are ready for Nornir.

---

## 4. Nornir Inventory Layout

> **Goal:** Define which routers to talk to and how.

Inside `core/automation/networking/nornir/inventory/`:

### 4.1 `hosts.yaml`

```yaml
csr-lab-01:
  hostname: 10.10.0.50
  port: 830
  platform: ios
  groups:
    - csr
```

### 4.2 `groups.yaml`

```yaml
csr:
  username: netconf-admin
  password: ${NETCONF_PASSWORD}
  connection_options:
    netconf:
      hostname: null          # use host.hostname
      port: 830
      username: netconf-admin
      password: ${NETCONF_PASSWORD}
      extras:
        hostkey_verify: false
```

> You can inject `NETCONF_PASSWORD` via environment variables or a `.env` file (never commit secrets).

### 4.3 `defaults.yaml`

```yaml
---
data:
  evidence_root: "docs/proof/networking/netconf-csr1000v"
```

This keeps the evidence path configurable and consistent with ADR‑0602.

---

## 5. Writing a Minimal NETCONF Collector

> **Goal:** Connect to CSR via NETCONF and write structured evidence into `docs/proof/`.

Create `core/automation/networking/nornir/tasks/netconf_collect.py`:

```python
#!/usr/bin/env python3
import os
from datetime import datetime
from pathlib import Path

from nornir import InitNornir
from nornir.core.task import Task, Result
from ncclient import manager


def _timestamp() -> str:
    return datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")


def netconf_collect(task: Task) -> Result:
    evidence_root = Path(task.host.get("evidence_root", "docs/proof/networking/netconf-csr1000v"))
    ts = _timestamp()

    host_dir = evidence_root / task.host.name / ts
    host_dir.mkdir(parents=True, exist_ok=True)

    with manager.connect(
        host=task.host.hostname,
        port=task.host.port,
        username=task.host.username,
        password=task.host.password,
        hostkey_verify=False,
        device_params={"name": "csr"},
        allow_agent=False,
        look_for_keys=False,
        timeout=30,
    ) as m:

        caps = "\n".join(sorted(m.server_capabilities))
        with (host_dir / "capabilities.txt").open("w", encoding="utf-8") as fh:
            fh.write(caps)

        running = m.get_config(source="running").data_xml
        with (host_dir / "running-config.xml").open("w", encoding="utf-8") as fh:
            fh.write(running)

    return Result(
        host=task.host,
        changed=False,
        result=f"NETCONF evidence written to {host_dir}",
    )


def main() -> None:
    nr = InitNornir(config_file="core/automation/networking/nornir/config.yaml")
    r = nr.run(task=netconf_collect)
    for host, result in r.items():
        print(f"{host}: {result[0].result}")


if __name__ == "__main__":
    main()
```

Example `config.yaml`:

```yaml
---
inventory:
  plugin: nornir.plugins.inventory.simple.SimpleInventory
  options:
    host_file: core/automation/networking/nornir/inventory/hosts.yaml
    group_file: core/automation/networking/nornir/inventory/groups.yaml
    defaults_file: core/automation/networking/nornir/inventory/defaults.yaml
```

---

## 6. Running the Collector

From the repo root:

```bash
python core/automation/networking/nornir/tasks/netconf_collect.py
```

Expected behaviour:

- A new timestamped folder appears under:

  ```text
  docs/proof/networking/netconf-csr1000v/csr-lab-01/2025XXXXTXXXXXXZ/
    capabilities.txt
    running-config.xml
  ```

- The script prints a summary, for example:

  ```text
  csr-lab-01: NETCONF evidence written to docs/proof/networking/netconf-csr1000v/csr-lab-01/20251130T153000Z
  ```

You can now commit this evidence in a feature branch as part of a change, or keep it as local proof for experiments.

---

## 7. Integrating with CI/CD

Typical patterns:

- **Jenkins job** that:
  - Runs before a planned change (captures “before”).
  - Runs after the change (captures “after”).
  - Stores both under a shared correlation ID (for example `CHANGE-2025-001`).

- **Pipeline variables**:
  - `EVIDENCE_TAG=CHANGE-2025-001` injected as an extra directory level.
  - `TARGETS=csr-edge-01,csr-edge-02` for selective collection.

You can wrap the Python script in a small shell wrapper that:

- Exports `NETCONF_PASSWORD` from Jenkins credentials.
- Logs output to `output/logs/netconf/…`.
- Pushes evidence to your Git remote or object storage.

---

## 8. Validation

Checklist:

- ✔ NETCONF is enabled and restricted to management addresses.  
- ✔ Nornir can connect to all target CSRs on port 830.  
- ✔ `capabilities.txt` and `running-config.xml` are created per host with current data.  
- ✔ Evidence folder structure matches:

  ```text
  docs/proof/networking/netconf-csr1000v/<hostname>/<timestamp>/
  ```

- ✔ Spot‑check: `running-config.xml` content aligns with `show running-config` on the router.

---

## 9. Troubleshooting

### 9.1 Connection Timeouts

Symptoms:

- Nornir task fails with timeout.
- `nc -vz csr-lab-01 830` fails.

Actions:

- Verify ACLs on CSR permit the automation host.
- Confirm `netconf-yang` is enabled.
- Check SSH source interface and routing on CSR.

### 9.2 Capability List Is Empty or Truncated

Symptoms:

- `capabilities.txt` missing expected models.

Actions:

- Confirm you are running a NETCONF/YANG‑capable IOS XE image.
- Check CSR logs for NETCONF errors (`show logging | inc netconf`).
- Increase session timeout in the Python script if needed.

### 9.3 Running-Config Dump Looks Wrong

Symptoms:

- Only partial config present.
- XML missing key sections (for example BGP).

Actions:

- Check the filter in `get_config` (this HOWTO uses full `source="running"`).
- Ensure no on‑box RBAC is hiding parts of the config.
- Compare with `show running-config` on CSR for differences.

### 9.4 CPU Spikes During Collection

Symptoms:

- CSR CPU peaks during NETCONF pulls.

Actions:

- Stagger collections (limit parallelism in Nornir).
- Filter to specific subtrees (for example only BGP or only interfaces).
- Schedule heavy evidence jobs during maintenance windows.

---

## 10. References

- [ADR‑0602 – NETCONF and Nornir Automation for CSR1000v](../../adr/ADR-0602-netconf-nornir-automation-csr1000v.md)  
- Runbook: [NETCONF Setup on CSR1000v](../../runbooks/networking/netconf-csr1000v-setup.md)  
- [Evidence](docs/proof/networking/netconf-csr1000v/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

# Programmatic Network Automation (Nornir) — BSc Project (Curated Showcase)

# Case Study: Network Automation & Abstraction (Nornir)

This case study documents the BSc project showcasing multi-vendor automation with **Nornir** over an **EVE‑NG** topology hosted on **Proxmox**.

- **Maintainer:** HybridOps.Studio
- **Last Updated:** 2025-09-18
- **SPDX-License-Identifier:** MIT

## Highlights
- Vendor-agnostic abstractions (Cisco/Arista/Fortigate)
- Jinja templating with idempotent configuration tasks
- CI: lint, tests, and dry-runs

## Evidence
Add run outputs, config diffs, and screenshots here.


**What**
Multivendor, multisite network automation (Cisco / Arista / Fortinet / pfSense) using **Python + Nornir** with vendor-agnostic task interfaces and per-vendor templates.

**Why it matters**
This project **seeded the multivendor automation patterns** later adopted in **HybridOps.Studio** (idempotent tasks, dry-run safety, JSON artifacts, topology-aligned inventories).

**Original full repo:** [Network automation & abstraction (Nornir)](https://github.com/jeleel-muibi/Network_automation_and_Abstraction)

---

## Scope (what’s included here)
- Inventory-driven tasks for **BGP / OSPF**, interface/VLAN baselines, and **idempotent config pushes**.
- **Validation**: neighbor/session health, path reachability, before/after diffs.
- **Artifacts**: each run emits JSON results and optional redacted diffs to `./artifacts/<task>/<timestamp>/`.

---

## Topology
- **Primary lab (used by default)**: [`../topology/eveng-core-min/`](../topologies/eveng-core-min/)
- **Full program topology (B1/B2)**: [`../topology/eveng-b1-b2/`](../topologies/eveng-b1-b2/) (optional expansion)

> Inventories map directly to the **eveng-core-min** lab; switch to **B1/B2** by pointing the `--inventory` flag at the alternate inventory set.

---

## Quick Start

```bash
# 1) Create a local venv
python3 -m venv .venv && . .venv/bin/activate

# 2) Install requirements
pip install -r requirements.txt

# 3) Dry-run a safe task (no changes)
python src/runner.py --task verify_ospf --inventory inventories/lab --check

# 4) Apply a scoped change (example)
python src/runner.py --task push_bgp --inventory inventories/lab --limit edge*

# 5) Review artifacts
ls -lah artifacts/<task>/*   # JSON results, optional redacted diffs
```

**Flags**
- `--check` dry-run (no device changes)
- `--limit` subset of hosts (glob)
- `--inventory` select inventory directory

---

## Tasks (curated)
| Task             | Purpose                              | Notes                                  |
|------------------|--------------------------------------|----------------------------------------|
| `backup_config`  | Capture & redact running config      | Writes to `artifacts/backup_config/`   |
| `verify_ospf`    | Assert OSPF neighbors/areas/LSAs     | Emits JSON assertions                   |
| `push_bgp`       | Apply BGP policy (per-vendor templ.) | Idempotent + pre/post checks            |
| `lldp_map`       | Build LLDP/adjacency map             | Export graph data for diagrams          |

---

## Safety & Idempotence
- All change tasks support **`--check`** and pre/post validation.
- Templates enforce **deterministic output**; tasks return **structured JSON** for audit/evidence.
- Config artifacts are **redacted** by default (remove secrets/comments).

---

## Evidence Pointers
- Example run artifacts: `./artifacts/…`
- Screenshots/logs (optional): `./docs/`
- Original BSc project (full history): [Network automation & abstraction (Nornir)](https://github.com/jeleel-muibi/Network_automation_and_Abstraction)

---

## Folder Layout
```
programmatic-nornir/
├── README.md
├── requirements.txt
├── inventories/
│   └── lab/              # host/group vars aligned to eveng-core-min
├── src/
│   ├── runner.py
│   └── tasks/
│       ├── backup_config.py
│       ├── verify_ospf.py
│       ├── push_bgp.py
│       └── lldp_map.py
├── artifacts/.gitkeep
└── docs/                 # optional screenshots / diagrams
```

> This curated showcase is **kept intentionally small** so assessors can run it quickly; see the original repo for the complete academic work.

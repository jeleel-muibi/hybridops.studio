---
title: "Configure VLAN-Aware Bridge and VLAN Subinterfaces on Proxmox"
category: "networking"
summary: "Step-by-step guide to enable a VLAN-aware bridge and per-VLAN gateways on Proxmox VE."
difficulty: "Intermediate"

topic: "proxmox-vlan-bridge"

video: ""
source: ""

draft: false
tags: ["proxmox", "networking", "vlan", "routing"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Configure VLAN-Aware Bridge and VLAN Subinterfaces on Proxmox

**Purpose:** Configure a VLAN-aware bridge (`vmbr0`) and per-VLAN gateway interfaces on a Proxmox host, aligned with the HybridOps Studio VLAN plan (management, observability, dev, staging, prod, lab).  
**Difficulty:** Intermediate  
**Target host:** Proxmox VE hypervisor (single-node homelab)  

---

## Demo / Walk-through

??? info "▶ Watch the demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="HybridOps.Studio HOWTO Demo"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

## 1. Prerequisites

- Proxmox VE installed and reachable on the management LAN.
- SSH or console access with root privileges.
- Host has at least one physical NIC connected to the upstream router/switch (e.g. `enp87s0`).
- No NetworkManager managing interfaces (standard Proxmox `/etc/network/interfaces` model).
- Backup of current network configuration.

**Backup current config:**

```bash
cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
```

---

## 2. Define VLAN Plan

HybridOps Studio uses the following VLAN and subnet layout (see ADR-0101):

| VLAN | Subnet        | Purpose         |
|------|---------------|-----------------|
| 10   | 10.10.0.0/24  | Management      |
| 11   | 10.11.0.0/24  | Observability   |
| 20   | 10.20.0.0/24  | Development     |
| 30   | 10.30.0.0/24  | Staging         |
| 40   | 10.40.0.0/24  | Production      |
| 50   | 10.50.0.0/24  | Lab / Testing   |

Gateway IPs are the `.1` address in each subnet, hosted on the Proxmox bridge:

- 10.10.0.1 → VLAN 10
- 10.11.0.1 → VLAN 11
- 10.20.0.1 → VLAN 20
- 10.30.0.1 → VLAN 30
- 10.40.0.1 → VLAN 40
- 10.50.0.1 → VLAN 50

---

## 3. Configure VLAN-Aware Bridge

Edit `/etc/network/interfaces` and define the main bridge `vmbr0` as VLAN-aware.

```bash
vi /etc/network/interfaces
```

Example configuration (Ethernet uplink on `enp87s0`):

```bash
# Loopback
auto lo
iface lo inet loopback

# Primary uplink bridge (VLAN-aware)
auto vmbr0
iface vmbr0 inet static
    address 192.168.0.27/24
    gateway 192.168.0.1
    bridge-ports enp87s0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 10 11 20 30 40 50
```

Adjust the `address`, `gateway`, and `bridge-ports` values to match the environment.

---

## 4. Add VLAN Subinterfaces and Gateways

In the same file, add VLAN subinterfaces on `vmbr0` for each subnet:

```bash
# VLAN 10 - Management
auto vmbr0.10
iface vmbr0.10 inet static
    address 10.10.0.1/24

# VLAN 11 - Observability
auto vmbr0.11
iface vmbr0.11 inet static
    address 10.11.0.1/24

# VLAN 20 - Development
auto vmbr0.20
iface vmbr0.20 inet static
    address 10.20.0.1/24

# VLAN 30 - Staging
auto vmbr0.30
iface vmbr0.30 inet static
    address 10.30.0.1/24

# VLAN 40 - Production
auto vmbr0.40
iface vmbr0.40 inet static
    address 10.40.0.1/24

# VLAN 50 - Lab / Testing
auto vmbr0.50
iface vmbr0.50 inet static
    address 10.50.0.1/24
```

Save and exit.

---

## 5. Apply Configuration Safely

Apply the updated configuration with minimal disruption:

```bash
ifreload -a
```

If SSH disconnects, reconnect to the same management IP (e.g. `192.168.0.27`).  
If reconnection fails, use the Proxmox console or physical access.

---

## 6. Validate Bridge and VLAN Interfaces

**Check bridge status:**

```bash
ip link show vmbr0
```

Expected: `state UP`, `master` is the bridge, and `enp87s0` enslaved.

**Check VLAN subinterfaces:**

```bash
ip addr show | grep vmbr0.
```

Expected entries:

```text
vmbr0.10: ... inet 10.10.0.1/24 ...
vmbr0.11: ... inet 10.11.0.1/24 ...
vmbr0.20: ... inet 10.20.0.1/24 ...
vmbr0.30: ... inet 10.30.0.1/24 ...
vmbr0.40: ... inet 10.40.0.1/24 ...
vmbr0.50: ... inet 10.50.0.1/24 ...
```

**Verify routing:**

```bash
ip route | grep 10.
```

Expected: routes to all VLAN subnets via `vmbr0`.

---

## 7. Smoke Tests from a VM

For a test VM attached to VLAN 20:

- Net device in Proxmox: `vmbr0`, VLAN tag `20`
- Inside the VM, configure IP `10.20.0.10/24`, gateway `10.20.0.1`

From inside the VM:

```bash
ping -c3 10.20.0.1     # Gateway
ping -c3 10.10.0.1     # Management gateway
```

Both should succeed once routing and firewall (see ADR-0103) are in place.

---

## 8. Troubleshooting

**Symptom:** No connectivity from VM to gateway.

- Confirm VLAN tag set on VM NIC in Proxmox (e.g. 20 for dev).
- Check `bridge-vids` includes the VLAN ID:
  ```bash
  bridge vlan show
  ```
- Verify `vmbr0.20` is `UP`:
  ```bash
  ip link show vmbr0.20
  ```

**Symptom:** Proxmox loses external connectivity after `ifreload -a`.

- Validate management IP / gateway in `vmbr0` section.
- Confirm upstream router is reachable:
  ```bash
  ping -c3 192.168.0.1
  ```
- If required, restore backup:
  ```bash
  cp /etc/network/interfaces.backup-YYYYMMDD* /etc/network/interfaces
  ifreload -a
  ```

---

## 9. References

- [ADR-0101: VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0102: Proxmox as Layer 3 Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0103: Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)
- [Network Architecture](../architecture/network-architecture.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

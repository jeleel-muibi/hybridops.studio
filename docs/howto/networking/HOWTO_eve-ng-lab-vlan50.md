---
title: "HOWTO: Bootstrap EVE-NG Network Lab in VLAN 50"
category: "networking"
summary: "Bring up an isolated EVE-NG lab in VLAN 50 for safe WAN, routing, and firewall experiments."
difficulty: "Intermediate"

topic: "eve-ng-lab-vlan50"

video: "https://www.youtube.com/watch?v=YOUR_EVE_NG_VIDEO_ID"
source: ""

draft: false
tags: ["eve-ng", "lab", "vlan50", "network-simulation"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Bootstrap EVE-NG Network Lab in VLAN 50

**Purpose:** Deploy an EVE-NG VM in the Lab/Testing VLAN (VLAN 50) so you can run routing, firewall, and WAN experiments without touching production traffic.  
**Difficulty:** Intermediate  
**Prerequisites:**
- VLAN 50 configured on Proxmox as per ADR‑0101 and ADR‑0201.
- EVE-NG ISO/OVA downloaded and available to Proxmox.
- At least 8–16 GB RAM and 4+ vCPUs free for the lab host.

---

## Demo / Walk-through

??? info "▶ Watch the EVE-NG lab bootstrap demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_EVE_NG_VIDEO_ID"
      title="EVE-NG Lab in VLAN 50 – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_EVE_NG_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Context

This HOWTO complements:

- ADR-0101 – VLAN Allocation Strategy
- ADR-0103 – Inter-VLAN Firewall Policy
- ADR-0201 – EVE-NG Network Lab Architecture

EVE-NG is positioned as **parallel lab infrastructure**, not in the production data path:

- VLAN 50 is fully isolated by default.  
- Optional VLAN trunks can be added for specific “hybrid” experiments.

---

## 2. Lab Assumptions

| Item              | Example value     |
|-------------------|------------------|
| VLAN ID           | 50               |
| Subnet            | 10.50.0.0/24     |
| Gateway (Proxmox) | 10.50.0.1        |
| EVE-NG VM IP      | 10.50.0.10       |
| DNS               | 8.8.8.8 / 1.1.1.1 |

- Proxmox has a bridge `vmbr0.50` or equivalent for VLAN 50.  
- Management access is via jump host (e.g. in VLAN 10) with firewall rules allowing SSH/HTTPS into VLAN 50 for admin only (optional).

---

## 3. Create the EVE-NG VM in Proxmox

### 3.1 Upload ISO or QCOW2

- Upload `eve-ng-community-*.iso` or a prepared QCOW2 to your Proxmox ISO storage.  

### 3.2 Create VM (GUI or Terraform)

Minimum spec (community edition):

- vCPU: 4  
- RAM: 8–16 GB  
- Disk: 100–200 GB (thin provisioned)  

Attach NIC:

- Bridge: `vmbr0` (or your main bridge).  
- VLAN tag: `50`.  

Boot from ISO and follow the EVE-NG installation prompts (default Debian-based installer).

---

## 4. Assign IP in VLAN 50

Inside EVE-NG console:

```bash
# As root inside EVE-NG (Debian)
nano /etc/network/interfaces
```

Example config:

```bash
auto eth0
iface eth0 inet static
    address 10.50.0.10/24
    gateway 10.50.0.1
    dns-nameservers 8.8.8.8 1.1.1.1
```

Apply:

```bash
systemctl restart networking
```

Validate from Proxmox host or management jump:

```bash
ping -c3 10.50.0.10
```

---

## 5. Apply Firewall Isolation

Confirm firewall policy from ADR‑0103 enforces:

- VLAN 50 cannot reach operational VLANs (10/11/20/30/40).  
- Operational VLANs cannot reach VLAN 50, except:
  - Management host(s) for SSH/HTTPS UI (optional).

Example checks from a dev VM (VLAN 20):

```bash
ping -c3 10.50.0.10   # should FAIL
```

From management jump (if allowed by policy):

```bash
ping -c3 10.50.0.10   # should SUCCEED
```

---

## 6. Add Device Images and Create Your First Lab

In a browser (from allowed management host):

1. Open `https://10.50.0.10/` and log in to EVE-NG.  
2. Follow EVE-NG docs to upload device images (Cisco CSR, VyOS, pfSense, etc.).  
3. Create a simple lab:
   - Two routers and a single link.  
   - Verify ping and basic routing between them.

This lab is fully contained in VLAN 50 and has no impact on live infrastructure.

---

## 7. Optional: Trunk a Real VLAN into EVE-NG

For advanced testing, you can:

- Add a **second NIC** to the EVE-NG VM on a trunk bridge.  
- Map that NIC to a dedicated EVE-NG network that represents, for example, “on-prem dev”.  

Caution:

- Only do this when you fully understand the risk.  
- Keep firewall rules strict and treat this as a **temporary** test configuration.

---

## 8. Validation Checklist

- [ ] EVE-NG VM reachable at `10.50.0.10`.  
- [ ] VLAN 50 routing and gateway functional (VM can reach 10.50.0.1 and internet).  
- [ ] Operational VLANs cannot reach VLAN 50 (as per ADR‑0103), except explicitly allowed management hosts.  
- [ ] Basic lab runs successfully (e.g. two routers can ping each other).  
- [ ] (Optional) Trunk tests are documented and reverted when complete.

---

## References

- [ADR‑0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR‑0103 – Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR‑0201 – EVE-NG Network Lab Architecture](../adr/ADR-0201-eve-ng-network-lab-architecture.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

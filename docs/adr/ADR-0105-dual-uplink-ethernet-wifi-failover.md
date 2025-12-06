---
id: ADR-0105
title: "Dual Uplink Design (Ethernet/WiFi Failover)"
status: Accepted
date: 2025-11-30

category: "01-networking"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks:
    - "../runbooks/networking/ethernet-wifi-failover.md"
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["failover", "redundancy", "uplink", "wifi", "ethernet"]
access: public
---

# Dual Uplink Design (Ethernet/WiFi Failover)

**Status:** Accepted — Adopts a simple manual failover pattern between Ethernet and WiFi uplinks on vmbr0 so all VLANs keep stable gateways while upstream can be switched during outages or maintenance.

## Context

The Proxmox host provides Layer 3 routing and NAT for all VLANs (ADR-0102). Loss of upstream connectivity would impact all environments simultaneously.

Available uplinks:

- `enp87s0`: primary wired Ethernet.
- `wlp89s0`: secondary WiFi interface.

Automatic bonding between Ethernet and WiFi on a single subnet is not practical and would add unnecessary complexity. However, the ability to switch uplinks during maintenance or when the primary fails is desirable.

## Decision

Implement a **manual failover** pattern with two alternative vmbr0 definitions in `/etc/network/interfaces`:

- Ethernet-backed vmbr0 (active by default).
- WiFi-backed vmbr0 (commented out but ready for activation).

Failover consists of toggling which stanza is active and reloading networking. VLAN subinterfaces and gateway addresses remain unchanged, so VMs do not require reconfiguration.

### Configuration Pattern

**Ethernet (active):**

```bash
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

**WiFi (standby):**

```bash
#auto vmbr0
#iface vmbr0 inet static
#    address 192.168.0.30/24
#    gateway 192.168.0.1
#    bridge-ports wlp89s0
#    bridge-stp off
#    bridge-fd 0
#    bridge-vlan-aware yes
#    bridge-vids 10 11 20 30 40 50
```

VLAN subinterfaces (for example, vmbr0.10, vmbr0.20, etc.) are shared regardless of which uplink is active.

## Rationale

- **Manual, explicit failover** is predictable and easy to reason about in a homelab context.
- **No automatic bonding** avoids IP conflicts and routing complexity between WiFi and Ethernet on the same subnet.
- **Identical VLAN configuration** keeps the gateway IPs and subnets stable, avoiding changes to Terraform or VM definitions.
- **Distinct host IPs** (for example `.27` vs `.30`) allow monitoring to detect which uplink is active and avoid conflicts if misconfigured.

## Consequences

### Positive

- Upstream connectivity can be moved between Ethernet and WiFi with minimal service interruption.
- Physical relocation and testing of WiFi performance become straightforward.
- The configuration remains simple and is fully represented in a single file.

### Negative

- Failover is not automatic; operator action is required.
- Brief connectivity loss occurs when reloading networking.
- Both stanzas must be kept aligned when VLAN configuration changes.

### Neutral

- The pattern reflects a controlled maintenance activity rather than high-availability routing.
- Migration to more advanced edge designs (for example, dual-homed routers) remains possible in future phases.

## Implementation

The associated runbook describes the operational steps (connected via front matter links). At a high level:

1. Update `/etc/network/interfaces` to enable or disable the required uplink stanza.
2. Apply changes via `ifreload -a`.
3. Validate connectivity from the Proxmox host and representative VMs.
4. Update monitoring dashboards to reflect the active uplink if required.

## References

- VLAN allocation: [ADR-0101 VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- Routing design: [ADR-0102 Proxmox as Layer 3 Router](./ADR-0102-proxmox-intra-site-core-router.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)
- Runbook: [Ethernet/WiFi Failover](../runbooks/networking/ethernet-wifi-failover.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

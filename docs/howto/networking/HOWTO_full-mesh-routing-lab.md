---
title: "HOWTO: Build a Full-Mesh Routing Lab for High Availability"
category: "networking"
summary: "Guided lab for designing, configuring, and testing a full-mesh Layer-3 topology between core routers and firewalls."
difficulty: "Advanced"

topic: "full-mesh-routing-lab"

video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
source: ""

draft: false
tags: ["routing", "mesh", "ha", "bgp", "adr-0108"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Build a Full-Mesh Routing Lab for High Availability

**Purpose:**  
Design and deploy a full-mesh routing topology that matches [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-topology.md), then run failure drills and record convergence behaviour as evidence.

**Difficulty:** Advanced  
**Audience:** Network / platform engineers working through the HybridOps.Studio routing blueprint.  
**Prerequisites:**

- Working Proxmox and/or EVE-NG environment.
- At least three virtual network devices (CSR1000v, VyOS, pfSense, etc.).
- Basic familiarity with BGP, IP addressing, and Linux/Proxmox networking.
- SSH or console access to all routers / firewalls.

---

## 1. Context

This HOWTO is a learning guide that complements:

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0103 – Inter-VLAN Firewall Policy](../../adr/ADR-0103-inter-vlan-firewall-policy.md)
- [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](../../adr/ADR-0201-eve-ng-network-lab-architecture.md)

The goal is to:

- Replace hub-and-spoke “single transit” patterns with a resilient full mesh.  
- Exercise eBGP between multiple vendors (CSR, VyOS, pfSense) in a controlled lab.  
- Capture routing evidence (before/after tables, convergence times) under link and node failures.  

This is not an incident runbook. Use it to build, understand, and document the full-mesh design. Runbooks (for example, `full-mesh-topology.md`) provide the terse operational checklist.

---

## 2. Demo / Walk-Through

??? info "▶ Watch the full-mesh routing lab walkthrough"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="Full Mesh Routing Lab – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

---

## 3. Choose Your Lab Nodes

Pick at least **3–4 core devices** so you can see real path diversity. For example:

| Node ID        | Platform       | Role                 |
|----------------|----------------|----------------------|
| `csr-edge-01`  | Cisco CSR1000v | Cloud/WAN edge       |
| `vyos-edge-01` | VyOS           | Open-source edge     |
| `fw-01`        | pfSense        | Firewall / edge      |
| `fw-02`        | pfSense        | Firewall / edge HA   |

You can host them either:

- As Proxmox VMs on dedicated VLANs; or  
- Inside EVE-NG, following [ADR-0201](../../adr/ADR-0201-eve-ng-network-lab-architecture.md).

**Outcome:** You have a list of devices that will participate in the full mesh and where they run.

> Tip: Keep node names and roles consistent with your ADRs and diagrams so evidence lines up cleanly.

---

## 4. Design Transit Networks and ASNs

A clean addressing and ASN plan makes troubleshooting much easier.

### 4.1 Assign ASNs

Use private ASNs for the lab, for example:

| Node           | ASN  |
|----------------|------|
| `csr-edge-01`  | 65010 |
| `vyos-edge-01` | 65020 |
| `fw-01`        | 65030 |
| `fw-02`        | 65031 |

### 4.2 Allocate Transit Links

Allocate /30 or /31 networks for each point-to-point link. Example design sheet:

| Link ID | Subnet         | Node A        | IP A         | Node B        | IP B         |
|---------|----------------|---------------|--------------|---------------|--------------|
| T1      | 172.16.20.0/30 | csr-edge-01   | 172.16.20.1  | vyos-edge-01  | 172.16.20.2  |
| T2      | 172.16.20.4/30 | csr-edge-01   | 172.16.20.5  | fw-01         | 172.16.20.6  |
| T3      | 172.16.20.8/30 | vyos-edge-01  | 172.16.20.9  | fw-01         | 172.16.20.10 |
| T4      | 172.16.20.12/30| vyos-edge-01  | 172.16.20.13 | fw-02         | 172.16.20.14 |
| T5      | 172.16.20.16/30| csr-edge-01   | 172.16.20.17 | fw-02         | 172.16.20.18 |

Save this sheet under:

```text
docs/proof/networking/full-mesh-tests/design-sheet-full-mesh.md
```

You will reference it in ADR-0108 evidence.

---

## 5. Bring Up Transit Interfaces

For each transit link:

1. Create the interface or subinterface on both nodes (VLAN or routed interface).  
2. Assign the IPs from your design sheet.  
3. Verify basic reachability with `ping`.

Example (Cisco CSR snippet):

```bash
interface GigabitEthernet1.20
 description T1 to vyos-edge-01
 encapsulation dot1Q 20
 ip address 172.16.20.1 255.255.255.252
 no shut
```

Example (VyOS snippet):

```bash
set interfaces ethernet eth1 description 'T1 to csr-edge-01'
set interfaces ethernet eth1 vif 20 address '172.16.20.2/30'
commit; save
```

**Checks:**

```bash
# On each node
ping 172.16.20.2  # from csr to vyos
ping 172.16.20.1  # from vyos to csr
```

Capture a brief log of successful pings and store it under:

```text
docs/proof/networking/full-mesh-tests/transit-link-tests.txt
```

---

## 6. Configure eBGP Between All Nodes

For each transit link, configure an **eBGP session** between the two neighbours using the ASNs from Section 4.

### 6.1 Basic BGP Configuration Pattern

Cisco CSR example:

```bash
router bgp 65010
 bgp log-neighbor-changes
 neighbor 172.16.20.2 remote-as 65020
 neighbor 172.16.20.2 description vyos-edge-01 T1
 ! Advertise your local LAN prefixes here
```

VyOS example:

```bash
set protocols bgp 65020 neighbor 172.16.20.1 remote-as '65010'
set protocols bgp 65020 neighbor 172.16.20.1 description 'csr-edge-01 T1'
# Advertise your local LAN prefixes here
commit; save
```

Repeat for all links (T2, T3, T4, T5). Keep descriptions aligned with your design sheet.

### 6.2 Verify BGP Sessions

On each node, check BGP status, for example:

```bash
# Cisco CSR
show ip bgp summary

# VyOS
show ip bgp summary
```

All neighbours should be in `Established` state.

Save the outputs under:

```text
docs/proof/networking/full-mesh-tests/bgp-summary-initial.txt
```

---

## 7. Verify Full Routing Visibility

Once eBGP is up, each node should see all relevant prefixes via one or more next hops.

### 7.1 Check Routing Tables

Examples:

```bash
# Cisco CSR
show ip route bgp

# VyOS
show ip route protocol bgp
```

Confirm that:

- Each node has routes to LANs behind the other nodes.  
- Next hops align with your expectations (direct neighbours, not unintended transits).  

### 7.2 Trace Paths

Use simple traceroutes to confirm path selection:

```bash
# From csr-edge-01 to a LAN behind fw-02
traceroute 10.40.0.10
```

Observe whether traffic uses the intended path (for example, direct over T5 vs via another node).

Record interesting outputs in:

```text
docs/proof/networking/full-mesh-tests/paths-baseline.txt
```

---

## 8. Run Failure Drills and Measure Convergence

This section connects directly to ADR-0108’s “failover and convergence” story.

### 8.1 Single Link Failure

1. Pick one transit link (for example, T3 between vyos-edge-01 and fw-01).  
2. Shut it down on one side:

    ```bash
    # On vyos-edge-01
    set interfaces ethernet eth1 vif 30 disable
    commit; save
    ```

3. Measure:

    - How long before BGP session drops.  
    - How long until alternative paths are used.  

4. Capture:

    ```bash
    show ip bgp summary
    show ip route bgp
    ```

Store as:

```text
docs/proof/networking/full-mesh-tests/failure-single-link.txt
```

### 8.2 Single Node Failure

1. Power off or shutdown one router/firewall (for example, `fw-01`).  
2. Repeat the checks above from remaining nodes.  
3. Observe whether all prefixes remain reachable via alternative paths.

Store results under:

```text
docs/proof/networking/full-mesh-tests/failure-single-node.txt
```

### 8.3 Planned DR Path Change

1. Intentionally change BGP attributes (MED / local-pref) to prefer a different exit.  
2. Use `traceroute` and route inspection to confirm the new preferred path.  
3. Note the time between policy change and stable routing.

Save as:

```text
docs/proof/networking/full-mesh-tests/dr-cutover-tests.txt
```

---

## 9. Troubleshooting Patterns

Some common issues you may encounter:

### 9.1 BGP Session Flaps or Stays Idle

**Symptoms:**

- Neighbour never reaches `Established`.  
- Session bounces between `Active` and `Connect`.  

**Checks:**

- IP reachability on the transit link (`ping` both ways).  
- Matching ASNs on both ends.  
- Firewall/ACL rules allowing TCP/179 between neighbours.

### 9.2 Missing Prefixes

**Symptoms:**

- Some LANs not visible in `show ip route bgp`.  

**Checks:**

- Are the networks actually advertised (for example, `network` or `redistribute` statements)?  
- Are any outbound route-filters denying the prefix?  
- Is next-hop reachability correct end-to-end?

### 9.3 Unexpected / Asymmetric Paths

**Symptoms:**

- Traffic goes via an extra hop even though a direct link exists.  

**Checks:**

- Local-pref and MED values on all peers.  
- AS-path length differences.  
- Any leftover static routes overriding BGP decisions.

When in doubt, capture:

- `show ip bgp` for the affected prefix on all nodes.  
- `traceroute` from both directions.  

Save snapshots into `docs/proof/networking/full-mesh-tests/troubleshooting-snapshots/` for later review.

---

## 10. Validation Checklist

You are done when:

- [ ] All BGP sessions are `Established` across the mesh.  
- [ ] Each node sees routes to all other nodes’ LANs via BGP.  
- [ ] Single link failures do not break reachability.  
- [ ] Single node failures do not isolate remaining peers.  
- [ ] Convergence time under failure is within your target (for example, < 3 seconds).  
- [ ] Evidence files exist under `docs/proof/networking/full-mesh-tests/` and are linked from ADR-0108.

---

## 11. References

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0103 – Inter-VLAN Firewall Policy](../../adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-topology.md)  
- [ADR-0201 – EVE-NG Network Lab Architecture](../../adr/ADR-0201-eve-ng-network-lab-architecture.md)  
- [Runbook: Full Mesh Topology Configuration](../../runbooks/networking/full-mesh-topology.md)  
- [Evidence](docs/proof/networking/full-mesh-tests/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

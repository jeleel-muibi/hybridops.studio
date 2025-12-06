---
title: "Full Mesh Topology Configuration"
category: "networking"
summary: "Configure and validate a full mesh L3 topology between core routers and firewalls."
severity: "P2"

topic: "full-mesh-topology"

draft: false
tags: ["networking", "ha", "mesh", "routing", "wan"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Full Mesh Topology Configuration

**Purpose:** Establish and validate a full mesh Layer-3 topology between core routers and firewalls, as defined in ADR‑0108, to eliminate single points of routing failure and support hybrid DR tests.  
**Owner:** Platform / Network Engineering  
**Trigger:** Initial mesh rollout, topology redesign, or periodic validation before major DR / failover exercises.  
**Impact:** Short, controlled routing convergence events during testing; should be executed in a maintenance window for shared lab environments.  
**Severity:** P2 (important for resilience, but not user-facing production in this blueprint).  

---

## 1. Preconditions and Safety Checks

Before starting:

1. **Change window agreed** (if shared lab):  
   - No critical demos or recordings in progress.  
   - Stakeholders aware of brief routing flaps.

2. **Devices reachable out-of-band:**  
   - Console / VNC access to each router (CSR1000v, VyOS, pfSense).  
   - SSH access to all devices from the management VLAN (10).  

3. **Baseline connectivity snapshot taken:**  
   From the Proxmox management node or a jump host:

   ```bash
   mkdir -p output/artifacts/networking/full-mesh-$(date +%Y%m%dT%H%M%SZ)

   # Baseline routing and adjacency snapshots (examples)
   ssh csr-core-1 'show ip route summary'      > output/artifacts/networking/full-mesh-$(date +%Y%m%dT%H%M%SZ)/csr-core-1_route.txt

   ssh vyos-core-1 'show ip route'      > output/artifacts/networking/full-mesh-$(date +%Y%m%dT%H%M%SZ)/vyos-core-1_route.txt
   ```

4. **ADR alignment confirmed:**  
   - ADR‑0101, ADR‑0102, ADR‑0103, ADR‑0106, ADR‑0107, ADR‑0108 are accepted and network addressing is consistent with those documents.

---

## 2. High-Level Steps

1. Create / verify **transit VLANs** or links between all core nodes.  
2. Configure **L3 interfaces** and IP addressing.  
3. Enable **eBGP full mesh** (or chosen routing protocol) between peers.  
4. Apply **basic prefix filters / advertise only required networks**.  
5. Validate **neighbor state, routing tables, and convergence**.  
6. Simulate **link/node failures** and confirm alternate paths.  
7. Capture **evidence** into `docs/proof/networking/full-mesh-tests/`.

The exact CLI differs per vendor; this runbook focuses on sequence and verification, not full device configuration templates.

---

## 3. Configure / Verify Transit Links

> Run on each router. Replace interface names/IPs with your lab values.

### 3.1 Create Transit Interfaces

**On CSR1000v (example):**

```bash
conf t
 interface GigabitEthernet1.10
  description to-vyos-core-1
  encapsulation dot1Q 10
  ip address 172.16.10.1 255.255.255.252
 !
 interface GigabitEthernet1.20
  description to-pfsense-ha-1
  encapsulation dot1Q 20
  ip address 172.16.20.1 255.255.255.252
end
write memory
```

**On VyOS (example):**

```bash
configure
set interfaces ethernet eth0 vif 10 description 'to-csr-core-1'
set interfaces ethernet eth0 vif 10 address '172.16.10.2/30'

set interfaces ethernet eth0 vif 30 description 'to-pfsense-ha-1'
set interfaces ethernet eth0 vif 30 address '172.16.30.2/30'

commit
save
exit
```

**On pfSense (example):** through WebUI or CLI, ensure corresponding VLANs and IPs are defined.

### 3.2 Validate Link-Level Connectivity

From each device, ping its neighbors on the transit links:

```bash
# From CSR
ping 172.16.10.2
ping 172.16.20.2

# From VyOS
ping 172.16.10.1
ping 172.16.30.1
```

**Expected:** All pings succeed.  
If not, check VLAN tags, bridge assignments on Proxmox, and IP masks.

---

## 4. Configure eBGP Full Mesh

### 4.1 CSR1000v BGP

```bash
conf t
 router bgp 65010
  bgp log-neighbor-changes
  neighbor 172.16.10.2 remote-as 65020
  neighbor 172.16.20.2 remote-as 65030
  ! Advertise internal prefixes
  network 10.10.0.0 mask 255.255.255.0
  network 10.20.0.0 mask 255.255.255.0
end
write memory
```

### 4.2 VyOS BGP

```bash
configure
set protocols bgp 65020 parameters router-id '172.16.10.2'
set protocols bgp 65020 neighbor 172.16.10.1 remote-as '65010'
set protocols bgp 65020 neighbor 172.16.30.1 remote-as '65030'

set protocols bgp 65020 network 10.30.0.0/24
set protocols bgp 65020 network 10.50.0.0/24

commit
save
exit
```

### 4.3 pfSense BGP

Configure via FRR / BGP package:

- ASN: `65030`.  
- Neighbors: CSR (`172.16.20.1`), VyOS (`172.16.30.2`).  
- Networks: advertise any perimeter/lab prefixes.

---

## 5. Validate Neighbor and Route State

### 5.1 BGP Neighbors

```bash
# CSR
show ip bgp summary

# VyOS
show ip bgp summary

# pfSense (FRR shell)
vtysh -c 'show ip bgp summary'
```

**Expected:** All neighbors in `Established` state, prefixes exchanged.

### 5.2 End-to-End Reachability

From each core device, test reachability to representative subnets:

```bash
# From CSR
ping 10.30.0.10
ping 10.50.0.10

# From VyOS
ping 10.20.0.10
```

Capture outputs:

```bash
ts=$(date +%Y%m%dT%H%M%SZ)
base="output/artifacts/networking/full-mesh-${ts}"
mkdir -p "${base}"

ssh csr-core-1 'show ip bgp' > "${base}/csr-core-1_bgp.txt"
ssh vyos-core-1 'show ip bgp' > "${base}/vyos-core-1_bgp.txt"
```

---

## 6. Failure Scenarios

Perform these tests only when safe to flap links.

### 6.1 Single Link Failure

1. Shut a single transit interface (e.g., CSR ↔ VyOS).  
2. Confirm traffic still flows via alternate paths.

Example (CSR):

```bash
conf t
 interface GigabitEthernet1.10
  shutdown
end
```

Validate on CSR and VyOS:

```bash
show ip bgp summary
ping 10.30.0.10
```

**Expected:** Convergence within a few seconds; traffic rerouted via remaining peers.

### 6.2 Node Failure Simulation

- Power off or stop one router VM (e.g., VyOS).  
- Confirm CSR ↔ pfSense still exchange routes and workloads remain reachable through other paths.

Record:

```bash
ts=$(date +%Y%m%dT%H%M%SZ)
base="output/artifacts/networking/full-mesh-failure-${ts}"
mkdir -p "${base}"

ssh csr-core-1 'show ip route' > "${base}/csr-core-1_route_after_failure.txt"
```

---

## 7. Verification Checklist

**Mark each as PASS/FAIL during execution:**

- [ ] All transit VLANs/interfaces up and pingable between peers.  
- [ ] All BGP neighbors in `Established` state.  
- [ ] Expected prefixes visible in each router’s routing table.  
- [ ] End-to-end pings between lab subnets succeed.  
- [ ] Single-link failure recovers with minimal packet loss.  
- [ ] Single-node failure still leaves at least one alternate path.  
- [ ] Evidence stored under `docs/proof/networking/full-mesh-tests/` (or exported there).  

---

## 8. Rollback

If mesh configuration causes instability or you need to revert quickly:

1. **Disable BGP neighbors** on one or more nodes:

   ```bash
   # CSR
   conf t
    router bgp 65010
     neighbor 172.16.10.2 shutdown
     neighbor 172.16.20.2 shutdown
   end
   write memory
   ```

2. **Remove or shut transit interfaces** if required.  
3. Restore previously captured routing configuration from your Git-backed templates or device backups.  
4. Re-run basic reachability tests to confirm network is back to the prior known-good state.

---

## References

- [ADR-0101 – VLAN Allocation Strategy](../../adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)  
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../../adr/ADR-0107-vyos-edge-router.md)  
- [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-topology-ha.md)  
- [Evidence](docs/proof/networking/full-mesh-tests/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

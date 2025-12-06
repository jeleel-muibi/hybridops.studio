---
title: "Cross-Vendor VRRP Gateway Failover"
category: "networking"
summary: "Configure and validate VRRP between Cisco CSR1000v and Arista vEOS for shared default gateway failover."
severity: "P2"

topic: "vrrp-cross-vendor"

draft: false
tags: ["networking", "vrrp", "ha", "csr1000v", "veos"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Cross-Vendor VRRP Gateway Failover

**Purpose:** Configure VRRP between Cisco CSR1000v and Arista vEOS to provide a shared default gateway with fast failover for a Layer‑3 segment.  
**Owner:** Network / Platform team  
**Trigger:** New VLAN brought under HA gateway control, topology refactor, or post‑upgrade VRRP validation.  
**Impact:** Short (~1–2s) packet loss on the affected VLAN during role changes if executed in a maintenance window.  
**Severity:** P2 (affects reachability on a shared segment if misconfigured).  

---

## When to use this runbook

Use this runbook when:

- Introducing VRRP between CSR and vEOS on a user or transit VLAN.
- Revalidating VRRP after software upgrades or topology changes.
- Investigating VRRP flaps, asymmetric routing, or gateway instability.

If you are learning the design or lab patterns, use the HOWTO instead:

- HOWTO: VRRP Between Cisco IOS and Arista vEOS (planned).

---

## Preconditions and safety checks

Before making changes:

1. **L2 adjacency and addressing**
   - CSR and vEOS interfaces must be on the **same subnet** and VLAN.
   - Planned addressing example:
     - CSR: `172.16.20.2/24`
     - vEOS: `172.16.20.3/24`
     - Virtual IP (VRRP): `172.16.20.1/24`

2. **Access and change window**
   - SSH/console access to both CSR and vEOS.
   - Maintenance window agreed if the VLAN is currently used by live workloads.

3. **Baseline checks**
   - Current gateway model: single active router or static default gateway.
   - Capture pre‑change state and configs:
     ```bash
     # On CSR
     show vrrp
     show running-config | section interface GigabitEthernet1
     show ip route 172.16.20.0 255.255.255.0

     # On vEOS
     show vrrp
     show running-config section interface Ethernet1
     ```

4. **Monitoring**
   - Ensure Prometheus / logging pipeline is operational, so VRRP events and interface flaps are captured.

If any precondition is not met, fix or escalate before continuing.

---

## Steps

### 1. Document the target segment

**Action:** Confirm the VLAN and IP plan you will apply VRRP to.

Example segment (adjust to your lab):

- VLAN ID: `220`
- Subnet: `172.16.20.0/24`
- Virtual IP (gateway for hosts): `172.16.20.1`
- CSR interface: `Gi1` → `172.16.20.2/24`
- vEOS interface: `Eth1` → `172.16.20.3/24`
- VRRP group ID: `10`
- Priority: CSR = 150 (Master), vEOS = 110 (Backup)

Record this in your ticket/change record and keep consistent across both devices.

---

### 2. Configure CSR1000v for VRRP (Master)

**Action:** Configure VRRP on the CSR interface and enable preemption and tracking.

On CSR:

```bash
configure terminal
  interface GigabitEthernet1
    description VRRP L3 segment 172.16.20.0/24
    ip address 172.16.20.2 255.255.255.0

    ! VRRPv3, group 10
    vrrp 10 address-family ipv4
      vrrp 10 ip 172.16.20.1
      vrrp 10 priority 150
      vrrp 10 preempt
      vrrp 10 timers advertise 1
      vrrp 10 track GigabitEthernet0/0/0 20   ! track WAN/ISP link, decrement on failure
  exit
end
write memory
```

Verification:

```bash
show vrrp brief
show vrrp interface GigabitEthernet1
```

**Expected:**

- CSR shows `State: MASTER` for VRRP group 10.
- Virtual IP `172.16.20.1` is owned by CSR.

Capture output for evidence.

---

### 3. Configure Arista vEOS for VRRP (Backup)

**Action:** Configure vEOS to participate in the same VRRP group as Backup.

On vEOS:

```bash
configure
  interface Ethernet1
    description VRRP L3 segment 172.16.20.0/24
    ip address 172.16.20.3/24

    vrrp 10 ip 172.16.20.1
    vrrp 10 priority 110
    vrrp 10 preempt
    vrrp 10 advertisement-interval 1
  exit
commit
write memory
```

Verification:

```bash
show vrrp
show vrrp interface Ethernet1
```

**Expected:**

- vEOS shows `State: BACKUP` for group 10.
- Priority and timers align with CSR configuration.

Capture output for evidence.

---

### 4. Validate steady-state VRRP behaviour

**Action:** Confirm that hosts use the virtual IP and that CSR is effectively Master.

From a test host in the VLAN:

```bash
ip route | grep default
ping -c3 172.16.20.1
traceroute 8.8.8.8
```

From CSR:

```bash
show vrrp brief
show arp | include 172.16.20.1
```

From vEOS:

```bash
show vrrp
show ip route 0.0.0.0/0
```

**Expected:**

- Default gateway on the host is `172.16.20.1`.
- CSR is Master; ARP entry for 172.16.20.1 resolves to VRRP MAC.
- vEOS routes default traffic via its upstream but does not own the gateway IP.

---

### 5. Test failover (CSR → vEOS)

**Action:** Simulate CSR failure or WAN loss and observe VRRP failover.

Option A – Interface shutdown (lab only):

On CSR:

```bash
configure terminal
  interface GigabitEthernet1
    shutdown
  end
```

Option B – Track WAN loss (if using track):

- Shutdown or flap the tracked WAN interface (e.g. `GigabitEthernet0/0/0`).
- VRRP priority on CSR should decrement and trigger Backup takeover.

Verification:

On vEOS:

```bash
show vrrp
```

On CSR:

```bash
show vrrp brief
```

From the host:

```bash
ping -c5 172.16.20.1
ping -c5 8.8.8.8
```

**Expected:**

- VRRP Master role moves to vEOS (state BACKUP → MASTER).
- Only short packet loss (typically 1–3 pings) during transition.
- Host default gateway remains `172.16.20.1` (no change required on clients).

Capture `show vrrp` outputs and ping results for evidence.

Restore CSR interface after the test:

```bash
configure terminal
  interface GigabitEthernet1
    no shutdown
  end
```

Confirm that VRRP preemption returns Master back to CSR after stability:

```bash
show vrrp brief
```

---

### 6. Integrate with monitoring and logs

**Action:** Ensure VRRP events and interface state changes are visible to observability tools.

Typical integrations:

- SNMP traps from CSR and vEOS to Prometheus/Alertmanager or ELK.
- Syslog streams containing VRRP state changes.

High‑level checks:

```bash
# On CSR
show logging | include VRRP

# On vEOS
show logging | include VRRP
```

Ensure:

- VRRP state changes send alerts (e.g. MASTER → BACKUP) as informational events.
- Evidence is stored under `docs/proof/networking/vrrp-tests/`.

---

## Verification

Runbook is successful when:

- CSR is `MASTER` and vEOS is `BACKUP` under normal operation.
- Hosts use the virtual IP (e.g. `172.16.20.1`) as their default gateway.
- Forced failover to vEOS results in brief, controlled packet loss only.
- Preemption returns MASTER role to CSR after recovery (if configured).
- Monitoring shows VRRP transitions with correct timestamps.

Quick verification commands:

```bash
# CSR
show vrrp brief
show arp | include 172.16.20.1

# vEOS
show vrrp

# Host
ping -c5 172.16.20.1
```

---

## Rollback

If VRRP must be removed or causes instability:

1. **Remove VRRP from vEOS**

   ```bash
   configure
     interface Ethernet1
       no vrrp 10
     exit
   commit
   write memory
   ```

2. **Remove VRRP from CSR**

   ```bash
   configure terminal
     interface GigabitEthernet1
       no vrrp 10 address-family ipv4
     exit
   end
   write memory
   ```

3. **Restore single-router gateway**

   - Ensure one router (CSR or vEOS) owns the default gateway IP (e.g. 172.16.20.1) directly, or
   - Revert to pre‑change configuration using saved configs:
     ```bash
     # CSR
     configure replace bootflash:pre-vrrp-config.txt force

     # vEOS
     configure
       rollback absolute <id>   ! if using Arista rollback
     commit
     ```

4. **Validate**

   - Hosts can still reach the internet.
   - Routing tables reflect the expected single default gateway.
   - Monitoring no longer reports VRRP events.

---

## References

- [ADR-0110 – VRRP Between Cisco IOS and Arista vEOS](../../adr/ADR-0110-vrrp-cisco-arista.md)
- [Network Architecture](../../prerequisites/network-architecture.md)
- [Evidence: VRRP Failover Tests](../../proof/networking/vrrp-tests/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

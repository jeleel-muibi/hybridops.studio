---
title: "HOWTO: Configure Cross-Vendor VRRP Gateway (Cisco IOS + Arista vEOS)"
category: "networking"
summary: "End-to-end guide to build a shared VRRP default gateway between Cisco IOS/CSR1000v and Arista vEOS."
difficulty: "Advanced"

topic: "vrrp-cross-vendor-gateway"

video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
source: "https://github.com/jeleel-muibi/hybridops.studio"

draft: false
tags: ["vrrp", "ha", "cisco", "arista", "default-gateway", "redundancy"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Configure Cross-Vendor VRRP Gateway (Cisco IOS + Arista vEOS)

**Purpose:** Build a shared VRRP default gateway between Cisco IOS/CSR1000v and Arista vEOS so that either router can forward traffic for a LAN segment with fast failover.  
**Audience:** Network / platform engineers comfortable with basic routing, VLANs, and vendor CLIs.  
**Difficulty:** Advanced (multi-vendor HA, routing, and failover testing).

**Prerequisites:**

- Working L3 reachability between both routers and the LAN segment (same VLAN / subnet).  
- IOS/CSR and vEOS images that support **VRRPv3**.  
- Console/SSH access to both routers and at least one test host on the LAN.  
- Basic understanding of your HybridOps.Studio topology (see ADRs below).

---

## 1. Context

This HOWTO is a teaching guide that complements:

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-ha-topology.md)  
- [ADR-0110 – VRRP Between Cisco IOS and Arista vEOS](../../adr/ADR-0110-vrrp-between-cisco-ios-arista-veos.md)  

The goal is to:

- Present **one virtual default gateway IP** to the LAN (e.g. `172.16.20.1`).  
- Run **Cisco CSR** as VRRP Master and **Arista vEOS** as Backup.  
- Track WAN/IPsec health so that VRRP fails over when the *real* path to upstream is broken, not just the local interface.  

This is not the incident runbook; use it to understand the pattern. The VRRP runbook will reference this HOWTO for deeper detail.

---

## 2. Demo / Walk-through

??? info "▶ Watch the cross-vendor VRRP failover demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="Cross-Vendor VRRP Gateway Demo – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

Replace `YOUR_VIDEO_ID` with the real ID when the video is published.

---

## 3. Lab Assumptions

Adjust to your real lab, but keep the shapes consistent.

### 3.1 Topology

- **LAN segment:** `172.16.20.0/24` (e.g. “user” or “app” VLAN).  
- **Virtual default gateway (VRRP VIP):** `172.16.20.1/24`.  
- **Cisco CSR (Master):** `172.16.20.2/24`.  
- **Arista vEOS (Backup):** `172.16.20.3/24`.  
- **VRID:** `20` (tie this to VLAN ID for sanity).  
- **Upstream:** both routers have uplinks to pfSense / WAN segments, as per full-mesh ADR-0108.

### 3.2 Devices

- **Cisco:** CSR1000v, IOS-XE with VRRPv3 support enabled.  
- **Arista:** vEOS (4.x+), VRRPv3 support enabled on the image used.  

### 3.3 IP Plan (example)

| Device        | Interface    | IP               | Notes                 |
|---------------|--------------|------------------|-----------------------|
| CSR1000v      | Gi0/1.20     | 172.16.20.2/24   | LAN SVI, VRRP Master  |
| Arista vEOS   | Ethernet2.20 | 172.16.20.3/24   | LAN SVI, VRRP Backup  |
| VRRP virtual  | –            | 172.16.20.1/24   | Default gateway (VIP) |

---

## 4. Step-by-Step Configuration

### 4.1 Prepare Interfaces and SVIs

#### On Cisco CSR (IOS-XE)

```bash
conf t
!
interface GigabitEthernet0/1.20
 description LAN20 – VRRP Master
 encapsulation dot1Q 20
 ip address 172.16.20.2 255.255.255.0
 no shut
!
end
wr mem
```

#### On Arista vEOS

```bash
configure terminal
!
interface Ethernet2.20
   description LAN20 – VRRP Backup
   encapsulation dot1q 20
   ip address 172.16.20.3/24
   no shutdown
!
end
write memory
```

Validate basic reachability:

- From CSR: `ping 172.16.20.3`  
- From vEOS: `ping 172.16.20.2`

Only continue when basic L3 between the routers works.

---

### 4.2 Configure VRRP on Cisco CSR (Master)

```bash
conf t
!
interface GigabitEthernet0/1.20
 ip address 172.16.20.2 255.255.255.0
 standby version 3
 standby 20 ip 172.16.20.1
 standby 20 priority 120
 standby 20 preempt
 standby 20 authentication text HYBRIDOPS20
!
end
wr mem
```

Key points:

- `standby version 3` → VRRPv3 (IPv4 + IPv6 capability, matches vEOS).  
- `priority 120` → CSR is Master (default is 100).  
- `preempt` → reclaim Master role when CSR recovers.  
- Authentication is optional but good for labs that mimic production.

Verify state:

```bash
show standby brief
show standby GigabitEthernet0/1.20
```

Expected on CSR:

- State: `Active`  
- Virtual IP: `172.16.20.1`  
- Priority: `120`

---

### 4.3 Configure VRRP on Arista vEOS (Backup)

```bash
configure terminal
!
interface Ethernet2.20
   ip address 172.16.20.3/24
   vrrp 20 version 3
   vrrp 20 ip 172.16.20.1
   vrrp 20 priority 100
   vrrp 20 preempt
   vrrp 20 authentication text HYBRIDOPS20
!
end
write memory
```

Check status:

```bash
show vrrp
show vrrp interface Ethernet2.20
```

Expected on vEOS:

- State: `Backup`  
- Virtual IP: `172.16.20.1`  
- Priority: `100`  

---

### 4.4 Point a Test Host to the VRRP Gateway

On a test VM in VLAN 20:

- IP: `172.16.20.10/24`  
- Gateway: `172.16.20.1`  

Verify:

```bash
ip route          # or 'ipconfig /all' on Windows
ping 172.16.20.1  # gateway
ping 172.16.20.2  # Cisco SVI
ping 172.16.20.3  # Arista SVI
```

Traffic should flow out via the current VRRP Master (CSR).

---

### 4.5 Add WAN Health Tracking (Conceptual)

In production you would not fail over just because the LAN interface flaps; you also care about **WAN/IPsec reachability**.  
Patterns (high-level, vendor-neutral):

- Track upstream next-hop reachability with SLA probes.  
- Tie VRRP priority to probe state.  
- Lower priority on the router whose WAN path is broken.

Examples (pseudo):

- On CSR: IP SLA to upstream, `track` object → `standby 20 track <id> decrement 30`.  
- On vEOS: `track` with static route reachability, and `vrrp 20 track <object> decrement 30`.

You’ll document the exact command set per vendor in a follow-up HOWTO once your lab syntax is final.

---

## 5. Failover Test

1. Confirm current Master/Backup:

   ```bash
   # On CSR
   show standby brief

   # On vEOS
   show vrrp
   ```

2. From the test VM (`172.16.20.10`):

   ```bash
   ping 172.16.20.1 -t      # or continuous ping
   ```

3. Induce failover:

   On CSR, temporarily shut the SVI:

   ```bash
   conf t
   interface GigabitEthernet0/1.20
    shutdown
   end
   ```

4. Observe:

   - Pings to `172.16.20.1` should drop briefly then recover.  
   - `show vrrp` on Arista should now show **Master**.  

5. Restore CSR and verify it preempts (if desired):

   ```bash
   conf t
   interface GigabitEthernet0/1.20
    no shutdown
   end
   ```

   Watch `show standby` on CSR and `show vrrp` on Arista to confirm roles.

---

## 6. Validation Checklist

From the test host:

- [ ] Default gateway set to `172.16.20.1`.  
- [ ] Continuous ping survives CSR interface flap with only brief loss.  

From CSR:

- [ ] `show standby brief` reports **Active** in normal state.  
- [ ] VRRP version 3 configured.  

From vEOS:

- [ ] `show vrrp` reports **Backup** in normal state, **Master** after CSR outage.  

Optionally capture packet traces around the failover to prove VRRP advertisement behaviour for audits.

---

## 7. Troubleshooting

- **Symptom:** VRRP never transitions to Master on Arista.  
  - Check priority values (Backup < Master).  
  - Check authentication strings match.  
  - Check VLAN tagging and IP addressing.

- **Symptom:** Host cannot ping `172.16.20.1`.  
  - Verify SVI interfaces are `up/up` on both devices.  
  - Confirm VRRP virtual IP is in `show standby` / `show vrrp`.  
  - Confirm no overlapping HSRP/GLBP configs on the same interface.

- **Symptom:** Failover is slow.  
  - Check VRRP timers (defaults may be conservative).  
  - Consider “fast-hello” tuning for the lab to showcase sub-second convergence.

---

## 8. References

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0108 – Full Mesh Topology for High Availability](../../adr/ADR-0108-full-mesh-ha-topology.md)  
- [ADR-0110 – VRRP Between Cisco IOS and Arista vEOS](../../adr/ADR-0110-vrrp-between-cisco-ios-arista-veos.md)  
- Runbook: `docs/runbooks/networking/vrrp-cross-vendor.md` (operational checklist)  
- Evidence path: `docs/proof/networking/vrrp-tests/`  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

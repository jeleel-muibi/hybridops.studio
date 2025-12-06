---
title: "Fortigate Edge Firewall Variant (Optional)"
category: "networking"
summary: "Use Fortigate as an alternative edge firewall while keeping the same HybridOps.Studio edge pattern."
difficulty: "Intermediate–Advanced"

topic: "fortigate-edge-variant"

video: ""
source: ""

draft: false
tags: ["networking", "firewall", "fortigate", "wan", "edge"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Fortigate as Edge Firewall Variant

**Purpose:** Show how to slot a Fortigate VM into the existing HybridOps.Studio edge pattern as a **vendor variant**, without changing the core network design or governance model.  
**Difficulty:** Intermediate–Advanced (you should already be comfortable with Fortigate basics and the baseline pfSense design).

---

## 1. Context

This HOWTO complements:

pfSense is the **primary firewall and flow-control plane** in HybridOps.Studio.  
Fortigate is introduced as a **drop-in variant** to demonstrate:

- Vendor‑agnostic edge **design**, not tool lock‑in.  
- Ability to map the same dual‑ISP, policy‑routing, and IPsec roles onto different platforms.  
- How to keep **governance and runbooks** stable while swapping the underlying appliance.

Use this guide when:

- You want to show a Fortigate‑based edge to an assessor / interview panel.  
- You work with Fortigate in production and want to reuse the same pattern.  
- You need a “vendor alternative” to pfSense without redesigning the entire edge.

---

## 2. Demo / Walk-through

??? info "▶ Watch the Fortigate edge variant walkthrough"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_FORTIGATE_DEMO_ID"
      title="Fortigate Edge Variant – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_FORTIGATE_DEMO_ID){ target=_blank rel="noopener" }

---

## 3. Lab Assumptions

Replace the examples with your actual values.

### 3.1 Baseline Design

- Core network, VLANs, and Proxmox intra‑site routing are already in place (see Evidence 1 + related HOWTOs).  
- pfSense dual‑ISP pattern is **understood** (ADR‑0106), even if not currently active in the lab.  
- You are adding Fortigate as **either**:
  - A replacement for pfSense at a given edge site, or  
  - An additional edge firewall in front of (or alongside) existing routers.

### 3.2 Example Addresses

| Component        | Example value       | Notes                              |
|------------------|---------------------|------------------------------------|
| Fortigate mgmt   | 10.10.0.52          | Management VLAN (10)               |
| Fortigate `wan1` | 192.0.2.10/30       | ISP A (primary)                    |
| Fortigate `wan2` | 198.51.100.10/30    | ISP B (secondary)                  |
| Inside interface | 10.40.0.254/24      | Toward core / Proxmox / routers   |
| Upstream routers | 10.40.0.10 / .11    | CSR / VyOS pair (optional)        |

Adjust for your ranges; these values are illustrative.

---

## 4. Step 1 – Deploy the Fortigate VM

### 4.1 Provisioning

1. Create a new Fortigate VM on Proxmox (or nested in EVE‑NG) using the vendor image.  
2. Attach NICs:
   - `port1` → management VLAN (VLAN 10 or dedicated mgmt segment).  
   - `port2` → `wan1` (ISP A).  
   - `port3` → `wan2` (ISP B).  
   - `port4` → internal / transit VLAN towards core/routers (for example VLAN 40 or a dedicated transit VLAN).

3. Ensure Proxmox ports carry the appropriate VLAN tags and are allowed in the bridge configuration.

> **Screenshot placeholder:**  
> `docs/proof/security/fortigate-variant/fortigate-proxmox-nics.png`

### 4.2 Basic System Setup

From the Fortigate console:

```shell
config system interface
  edit "port1"
    set ip 10.10.0.52/24
    set allowaccess ping https ssh
  next
  edit "port2"
    set ip 192.0.2.10/30
  next
  edit "port3"
    set ip 198.51.100.10/30
  next
  edit "port4"
    set ip 10.40.0.254/24
  next
end
```

Add static routes to ISP gateways:

```shell
config router static
  edit 1
    set device "port2"
    set gateway 192.0.2.1
  next
  edit 2
    set device "port3"
    set gateway 198.51.100.1
  next
end
```

Do **not** set a default route yet if you plan to use SD‑WAN or policy routing in the next step.

---

## 5. Step 2 – Model Dual ISP & Health Checks

You have two main options; choose the one that best matches your production style.

### 5.1 Option A – SD‑WAN / Performance SLA (recommended)

1. Configure performance SLAs:

```shell
config system sdwan
  config health-check
    edit "isp_a_sla"
      set server "8.8.8.8"
      set failtime 5
      set recoverytime 5
    next
    edit "isp_b_sla"
      set server "1.1.1.1"
      set failtime 5
      set recoverytime 5
    next
  end
end
```

2. Add members:

```shell
config system sdwan
  config members
    edit 1
      set interface "port2"
      set gateway 192.0.2.1
      set priority 1
    next
    edit 2
      set interface "port3"
      set gateway 198.51.100.1
      set priority 2
    next
  end
end
```

3. Define SD‑WAN rules so that general internet traffic prefers ISP A, failing over to ISP B when the `isp_a_sla` check fails.

> **Screenshot placeholder:**  
> `docs/proof/security/fortigate-variant/fortigate-sdwan-healthchecks.png`

This mirrors **pfSense gateway groups**: one ISP is tier 1, the other is tier 2.

### 5.2 Option B – Static Routes + Distance / Priority

If you do not want SD‑WAN:

```shell
config router static
  edit 10
    set dst 0.0.0.0/0
    set gateway 192.0.2.1
    set distance 10
  next
  edit 20
    set dst 0.0.0.0/0
    set gateway 198.51.100.1
    set distance 20
  next
end
```

Integrate with link‑health checks or automation (for example, Nornir/Ansible) that adjusts route distance when ISP A is unhealthy.

---

## 6. Step 3 – Internal / Transit Routing

From the core network’s perspective, Fortigate is the **edge firewall + default gateway to the internet**.

Common patterns:

- Core VLAN gateways live on Proxmox (see Evidence 1).  
- Routers (CSR/VyOS) sit behind Fortigate on a **transit VLAN**.  
- Fortigate’s inside interface (`port4`) is the default route for those routers.

Example:

```shell
config firewall policy
  edit 100
    set name "inside-to-internet"
    set srcintf "port4"
    set dstintf "sdwan"        # or "port2"/"port3"
    set srcaddr "all"
    set dstaddr "all"
    set action accept
    set schedule "always"
    set service "ALL"
    set nat enable
  next
end
```

This is the Fortigate equivalent of pfSense’s **LAN → WAN** rule plus outbound NAT.

> **Screenshot placeholder:**  
> `docs/proof/security/fortigate-variant/fortigate-inside-policy.png`

---

## 7. Step 4 – IPsec / VPN to Cloud

The exact configuration will depend on whether you are integrating with:

- Azure VPN Gateway (primary hub; see ADR‑0109).  
- GCP VPN / NCC spokes.  
- CSR/VyOS acting as cloud routers.

The pattern is the same:

1. Define **Phase 1** with correct peer, encryption, and interface (often `sdwan` or a specific `wanX`).  
2. Define **Phase 2** selectors (on‑prem prefixes ↔ cloud prefixes).  
3. Link IPsec interface into routing:

```shell
config router static
  edit 50
    set dst 10.250.0.0/16
    set device "FGT-AZURE-IPSEC"
  next
end
```

4. Create firewall policies to allow traffic from inside/transit VLANs to the IPsec interface.

> **Screenshot placeholder:**  
> `docs/proof/security/fortigate-variant/fortigate-ipsec-tunnel.png`

Cross‑check these flows with Wireshark (on a mirrored port or using Fortigate capture exports) to validate encryption domains and failover behaviour.

---

## 8. Step 5 – Logging, Monitoring & Wireshark

To keep observability aligned with the rest of HybridOps.Studio:

1. **Syslog / Log forwarding**

   - Configure Fortigate to send logs to your central logging stack (for example, Loki or ELK).  
   - Use a dedicated log host in the **observability VLAN (11)**.

2. **SNMP / Metrics**

   - Enable SNMP for interface counters, CPU/memory, and VPN states.  
   - Scrape via a Prometheus exporter compatible with Fortigate (or SNMP bridge).

3. **Packet Captures**

   - Use Fortigate’s `diagnose sniffer packet` for quick CLI‑level checks.  
   - Export `.pcap` files and open them in Wireshark to illustrate:
     - Dual‑ISP failover (flows move from `wan1` to `wan2`).  
     - Cloud VPN establishment and traffic patterns.  

> **Screenshot placeholders:**  
> - `docs/proof/security/fortigate-variant/wireshark-dual-isp-failover.png`  
> - `docs/proof/security/fortigate-variant/wireshark-cloud-vpn.png`

---

## 9. Validation Checklist

Use this as a quick smoke test after changes:

- [ ] Fortigate reachable on management IP from VLAN 10.  
- [ ] Internet access works from a test host behind Fortigate.  
- [ ] Traffic prefers ISP A under normal conditions.  
- [ ] When ISP A is disabled, traffic fails over to ISP B within an acceptable time window.  
- [ ] IPsec tunnel(s) come up and pass traffic to Azure/GCP as expected.  
- [ ] Logs appear in the observability stack; interface metrics are visible in Grafana.  
- [ ] Packet captures match the intended paths (correct source/destination, correct ISP, correct encryption domains).

---

## 10. References

- [ADR‑0106 – Dual ISP Load Balancing for Resiliency](../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR‑0107 – VyOS as Cost-Effective Edge Router](../adr/ADR-0107-vyos-edge-router.md)
- [ADR‑0108 – Full Mesh Topology for High Availability](../adr/ADR-0108-full-mesh-topology-ha.md)
- [ADR‑0109 – NCC Primary Hub with Azure Spoke Connectivity](../adr/ADR-0109-ncc-primary-hub-azure-spoke.md)
- [ADR‑0301 – pfSense as Firewall for Flow Control](../adr/ADR-0301-pfsense-firewall-flow-control.md)
- [ADR‑0301 – pfSense as Firewall for Flow Control](../adr/ADR-0302-Fortigate-Variant-for-Edge-Firewall.md)

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

---
title: "HOWTO: Validate Network Architecture End-to-End"
category: "networking"
summary: "Systematic checklist to validate routing, firewall, NAT and observability across all VLANs and components."
difficulty: "Intermediate"

topic: "validate-end-to-end-architecture"

video: "https://www.youtube.com/watch?v=YOUR_E2E_VALIDATION_VIDEO_ID"
source: ""

draft: false
tags: ["validation", "testing", "network-architecture", "vlan"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Validate Network Architecture End-to-End

**Purpose:** Provide a repeatable end-to-end validation flow for the HybridOps.Studio network architecture — from VLANs and routing to firewall rules, NAT and observability.  
**Difficulty:** Intermediate  
**Prerequisites:**
- VLANs 10/11/20/30/40/50 (and optional 25/QA) configured as per ADRs.
- Proxmox routing and firewall in place.
- Observability stack running in VLAN 11.

---

## Demo / Walk-through

??? info "▶ Watch the end-to-end validation walk-through"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_E2E_VALIDATION_VIDEO_ID"
      title="End-to-End Network Validation – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_E2E_VALIDATION_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Context

This HOWTO validates the end-to-end networking design described in:

- [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)
- [Network Architecture](../prerequisites/network-architecture.md)

It assumes that:

- VLANs and gateways are configured on Proxmox as per ADR-0101/ADR-0102.
- Inter-VLAN firewall policy is applied as per ADR-0103.
- Static IP allocation is managed via Terraform IPAM (ADR-0104).
- Observability (Prometheus/Grafana) is in place as per ADR-0401.

Use this guide:

- After initial build.  
- After major changes (new VLAN, new firewall policy, new uplink).  
- Before capturing formal evidence or recording a demo.

---

## 2. High-Level Validation Flow

1. **Layer 2/3:** Bridges, VLAN interfaces, routing table.  
2. **Per-VLAN:** Gateway reachability and internet access.  
3. **Firewall:** Expected blocks and allows (dev/qa/stg/prod/lab).  
4. **NAT:** Outbound connectivity via vmbr0.  
5. **Observability:** Metrics available across environments.  
6. **Lab Isolation:** EVE-NG and lab VLAN behaviour.  

Treat this as a checklist you can semi-automate later (Ansible/Nornir).

---

## 3. Validate Proxmox Core (Bridges, VLANs, Routes)

On Proxmox host:

```bash
# Bridges and VLAN-awareness
ip -d link show vmbr0

# VLAN subinterfaces
ip addr show | grep 'vmbr0.'

# Routes
ip route show | grep '10.'
```

Confirm that you see:

- `vmbr0.10`, `vmbr0.11`, `vmbr0.20`, `vmbr0.30`, `vmbr0.40`, `vmbr0.50` (and `vmbr0.25` if QA exists).  
- Routes for each `/24` via the correct interface.

---

## 4. Per-VLAN Gateway and Internet Tests

From a management jump host (or directly via SSH into representative VMs):

```bash
# Dev VM
ssh dev-user@10.20.0.10 'ping -c3 10.20.0.1 && ping -c3 8.8.8.8'

# Staging VM
ssh stg-user@10.30.0.10 'ping -c3 10.30.0.1 && ping -c3 8.8.8.8'

# Prod VM
ssh prod-user@10.40.0.10 'ping -c3 10.40.0.1 && ping -c3 8.8.8.8'

# Lab VM (if allowed to reach internet)
ssh lab-user@10.50.0.10 'ping -c3 10.50.0.1 && ping -c3 8.8.8.8'
```

Expected:

- Gateway pings succeed for all VLANs.  
- Internet pings succeed where NAT is expected to be allowed.

---

## 5. Firewall: Expected Blocks and Allows

Using ADR‑0103 policy as reference:

- **Dev → Prod:** should be blocked.  
- **Staging → Prod (read-only ports):** allowed (if configured).  
- **Prod → Dev/Staging/Lab:** blocked.  
- **Lab ↔ Any:** blocked.  

Example tests:

```bash
# From dev VM
ping -c3 10.40.0.10   # should FAIL
curl -m3 http://10.40.0.10:80 || echo "expected fail"

# From prod VM
ping -c3 10.20.0.10   # should FAIL
ping -c3 10.50.0.10   # should FAIL

# From lab VM
ping -c3 10.20.0.10   # should FAIL
```

On Proxmox host, observe counters:

```bash
iptables -L FORWARD -n -v | head -40
```

---

## 6. NAT Behaviour via vmbr0

From each environment that should have internet:

```bash
curl -I https://www.google.com
```

On Proxmox host:

```bash
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
```

Expect to see counters increment for each VLAN’s source subnet.

---

## 7. Observability Cross-Checks

From management workstation or jump host:

```bash
# Prometheus UI
curl -I http://10.11.0.10:9090

# Grafana UI
curl -I http://10.11.0.11:3000
```

In Grafana:

- Confirm you can filter dashboards by `environment` (dev/staging/prod/qa).  
- Check that node_exporter targets from each VLAN are `UP` in Prometheus.  

Quick PromQL checks:

```text
up{environment="dev"}
up{environment="staging"}
up{environment="prod"}
up{environment="qa"}     # if QA exists
```

---

## 8. Lab Isolation (EVE-NG)

Ensure EVE-NG in VLAN 50 behaves as expected:

```bash
# From EVE-NG
ping -c3 10.50.0.1        # gateway
ping -c3 8.8.8.8          # optional internet, if allowed

# From dev VM
ping -c3 10.50.0.10       # should FAIL

# From staging VM
ping -c3 10.50.0.10       # should FAIL
```

This confirms lab is not accidentally exposed to operational VLANs.

---

## 9. Optional: Uplink Failover Smoke Test

If ADR‑0105 dual uplink is configured:

1. Follow the Ethernet→WiFi failover runbook.  
2. Re-run sections 4–8 quickly to confirm behaviour is unchanged.  

This is ideal material for a demo video and DR evidence.

---`

## 10. Validation Checklist

- [ ] All VLAN interfaces and routes exist on Proxmox.  
- [ ] Each environment VM can reach its gateway and (if configured) the internet.  
- [ ] Firewall rules enforce intended isolation (dev/qa/stg/prod/lab).  
- [ ] NAT rules present and counters increase on test traffic.  
- [ ] Observability stack shows metrics across environments.  
- [ ] Lab VLAN remains isolated from operational VLANs.  
- [ ] (Optional) Dual uplink failover does not break connectivity patterns.

---

## References

- [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0103 – Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR-0104 – Static IP Allocation with Terraform IPAM](../adr/ADR-0104-static-ip-allocation-terraform-ipam.md)  
- [ADR-0105 – Dual Uplink Design (Ethernet/WiFi Failover)](../adr/ADR-0105-dual-uplink-ethernet-wifi-failover.md)  
- [ADR-0201 – EVE-NG Network Lab Architecture](../adr/ADR-0201-eve-ng-network-lab-architecture.md)  
- [ADR-0401 – Unified Observability with Prometheus](../adr/ADR-0401-unified-observability-prometheus.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

---
title: "HOWTO: Add a New Environment (QA) to the VLAN Scheme"
category: "networking"
summary: "Extend the existing VLAN scheme with a new QA environment while preserving firewall and IPAM patterns."
difficulty: "Intermediate"

topic: "add-environment-qa-vlan"

video: "https://www.youtube.com/watch?v=YOUR_QA_VLAN_VIDEO_ID"
source: ""

draft: false
tags: ["vlan", "qa", "environment", "ipam", "firewall"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Add a New Environment (QA) to the VLAN Scheme

**Purpose:** Add a **QA** environment to the existing dev/staging/prod VLAN scheme without breaking firewall rules, routing, or Terraform IPAM.  
**Difficulty:** Intermediate  
**Prerequisites:**
- Existing VLAN design in place (10/11/20/30/40/50) as per ADR‑0101.
- Proxmox acting as intra-site core router (ADR‑0102).
- Terraform IPAM and VM modules already in use (ADR‑0104).

---

## Demo / Walk-through

??? info "▶ Watch the QA VLAN extension demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_QA_VLAN_VIDEO_ID"
      title="Add QA Environment to VLAN Scheme – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_QA_VLAN_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Context

This HOWTO complements:

- ADR-0101 – VLAN Allocation Strategy
- ADR-0102 – Proxmox as Intra-Site Core Router
- ADR-0103 – Inter-VLAN Firewall Policy
- ADR-0104 – Static IP Allocation with Terraform IPAM
- Network Architecture

Current environments:

- VLAN 20 – dev  
- VLAN 30 – staging  
- VLAN 40 – prod  

We now introduce **VLAN 25 – QA** as an intermediate environment (close to staging, isolated from dev and prod).

---

## 2. Design for QA VLAN

### 2.1 VLAN and Subnet

| Item        | Value              |
|-------------|--------------------|
| VLAN ID     | 25                 |
| Subnet      | 10.25.0.0/24       |
| Gateway     | 10.25.0.1          |
| Range (VMs) | 10.25.0.10–250     |

Design principles:

- Keep numbering aligned with existing ranges (20s for dev/qa).  
- Reserve `.1` for gateway, `.2–.9` for shared services if needed.  
- Apply firewall policy similar to staging: QA can pull from dev/staging artefact stores if desired, but not prod.

---

## 3. Update Proxmox Network Configuration

On the Proxmox host (`/etc/network/interfaces`):

```bash
auto vmbr0.25
iface vmbr0.25 inet static
    address 10.25.0.1/24
```

Apply:

```bash
ifreload -a
ip addr show | grep vmbr0.25
```

Confirm route:

```bash
ip route | grep 10.25.0.0/24
```

---

## 4. Extend Terraform IPAM for QA

In your IPAM module configuration, add the QA VLAN definition.

Example (inside IPAM module vars or map):

```hcl
variable "subnets" {
  type = map(object({
    cidr    = string
    vlan_id = number
  }))

  default = {
    # existing
    "dev"  = { cidr = "10.20.0.0/24", vlan_id = 20 }
    "qa"   = { cidr = "10.25.0.0/24", vlan_id = 25 }
    "stg"  = { cidr = "10.30.0.0/24", vlan_id = 30 }
    "prod" = { cidr = "10.40.0.0/24", vlan_id = 40 }
  }
}
```

Example allocations for QA:

```hcl
module "ipam_qa" {
  source = "../../modules/proxmox/ipam"

  allocations = {
    k3s-qa-cp-01 = { vlan = 25, offset = 10 } # 10.25.0.10
    k3s-qa-wk-01 = { vlan = 25, offset = 20 } # 10.25.0.20
  }
}
```

---

## 5. Create QA VMs

Use your existing VM module:

```hcl
module "vm_qa" {
  source = "../../modules/proxmox/vm"

  vms = {
    k3s-qa-cp-01 = {
      ipv4_address = module.ipam_qa.ipv4_addresses["k3s-qa-cp-01"]
      ipv4_gateway = module.ipam_qa.gateways[25]
      # CPU, RAM, template, tags...
    }
    k3s-qa-wk-01 = {
      ipv4_address = module.ipam_qa.ipv4_addresses["k3s-qa-wk-01"]
      ipv4_gateway = module.ipam_qa.gateways[25]
    }
  }
}
```}

Apply and validate from Proxmox host:

```bash
ping -c3 10.25.0.10
ping -c3 10.25.0.20
```

---

## 6. Update Inter-VLAN Firewall Policy

Extend ADR‑0103 policy for QA. For example:

- QA cannot access prod.  
- QA may have limited access to dev or staging (pull artefacts only).  

Example iptables rules (conceptual):

```bash
# Block QA → Prod
iptables -A FORWARD -s 10.25.0.0/24 -d 10.40.0.0/24 -j DROP

# Allow QA → Dev on specific ports (optional)
iptables -A FORWARD -s 10.25.0.0/24 -d 10.20.0.0/24 -p tcp --dport 443 -j ACCEPT
```

Re-apply via your Ansible `proxmox-firewall` role and confirm:

```bash
iptables -L FORWARD -n | grep 10.25.0.0
```

---

## 7. Update Observability and DNS (Optional)

- Add QA targets to Prometheus (environment label `qa`).  
- Extend Grafana dashboards to include QA environment.  
- Create DNS records for QA services (e.g. `k3s-qa-cp-01.qa.hybridops.local`).

---

## 8. Validation Checklist

- [ ] VLAN 25 (`vmbr0.25`) present and gateway `10.25.0.1` configured.  
- [ ] QA VMs obtain static IPs via Terraform IPAM.  
- [ ] QA can reach internet via Proxmox NAT if required.  
- [ ] QA firewall rules behave as expected (no access to prod, controlled access to dev/staging).  
- [ ] Observability labels and dashboards updated to include QA.

---

## References

- [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0103 – Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR-0104 – Static IP Allocation with Terraform IPAM](../adr/ADR-0104-static-ip-allocation-terraform-ipam.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

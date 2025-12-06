---
title: "Implement Inter-VLAN Firewall with iptables on Proxmox"
category: "networking"
summary: "Configure a default-deny inter-VLAN firewall on a Proxmox host using iptables."
difficulty: "Intermediate"

topic: "proxmox-inter-vlan-firewall"

video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
source: ""

draft: false
tags: ["proxmox", "iptables", "firewall", "vlan", "security"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Implement Inter-VLAN Firewall with iptables on Proxmox

**Purpose:** Configure a stateful, default-deny inter-VLAN firewall on the Proxmox host that routes between VLANs, aligning with ADR-0103.  
**Difficulty:** Intermediate  
**Target host:** Proxmox VE hypervisor acting as Layer 3 router.

---

## Demo / Walk-through

??? info "▶ Watch the inter-VLAN firewall configuration demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="Inter-VLAN Firewall with iptables – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Prerequisites

- VLAN-aware bridge and subinterfaces configured (see VLAN bridge HOWTO).
- Proxmox host routes between all VLANs.
- Root access to Proxmox.
- `iptables-persistent` or equivalent to persist rules across reboots.

Install persistence (Debian/Proxmox):

```bash
apt update
apt install -y iptables-persistent
```

---

## 2. Enable IP Forwarding

Ensure IPv4 forwarding is enabled:

```bash
sysctl net.ipv4.ip_forward
```

If value is `0`, enable it:

```bash
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ip-forward.conf
sysctl -p /etc/sysctl.d/99-ip-forward.conf
```

---

## 3. Define VLAN Subnets

This HOWTO assumes the following subnets (ADR-0101):

- VLAN 10 (Management): `10.10.0.0/24`
- VLAN 11 (Observability): `10.11.0.0/24`
- VLAN 20 (Dev): `10.20.0.0/24`
- VLAN 30 (Staging): `10.30.0.0/24`
- VLAN 40 (Prod): `10.40.0.0/24`
- VLAN 50 (Lab): `10.50.0.0/24`

Adjust addresses to match the environment if different.

---

## 4. Baseline Firewall Policy

Start from a clean baseline (run with care, preferably from console):

```bash
# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Set default policies
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
```

Add stateful tracking:

```bash
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

---

## 5. Management and Observability Rules

### 5.1 Management VLAN (10) can reach all VLANs

```bash
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT
```

### 5.2 All VLANs can reach management services (22, 443)

```bash
iptables -A FORWARD -d 10.10.0.0/24 -p tcp -m multiport --dports 22,443 -j ACCEPT
```

### 5.3 Observability VLAN (11) can scrape metrics from all environments

```bash
iptables -A FORWARD -s 10.11.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.30.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.40.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
```

---

## 6. Environment Isolation Rules

### 6.1 Lab isolation (VLAN 50)

```bash
iptables -A FORWARD -s 10.50.0.0/24 -j DROP
iptables -A FORWARD -d 10.50.0.0/24 -j DROP
```

### 6.2 Production isolation (VLAN 40)

```bash
iptables -A FORWARD -s 10.40.0.0/24 -d 10.20.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.50.0.0/24 -j DROP
```

### 6.3 Development isolation (VLAN 20)

```bash
iptables -A FORWARD -s 10.20.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.20.0.0/24 -d 10.40.0.0/24 -j DROP
```

Additional rules can be added as required for staging or specific services.

---

## 7. NAT Rules (Internet Access)

Configure NAT for each internal subnet through the uplink bridge (vmbr0):

```bash
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.11.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.20.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.30.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.40.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.50.0.0/24 -o vmbr0 -j MASQUERADE
```

---

## 8. Persist Rules

Save rules so they survive reboot:

```bash
iptables-save > /etc/iptables/rules.v4
```

For systems with `netfilter-persistent`, confirm the service is enabled:

```bash
systemctl enable netfilter-persistent
systemctl status netfilter-persistent
```

---

## 9. Validation

From a VM in each VLAN:

- `ping` its own gateway (`10.X0.0.1`).
- `ping` a VM in another VLAN according to policy (e.g. dev → prod should fail).
- `ping 8.8.8.8` to verify internet access via NAT.

On the Proxmox host, inspect counters:

```bash
iptables -L FORWARD -n -v
iptables -t nat -L POSTROUTING -n -v
```

Confirm packets hit the expected ACCEPT/DROP and MASQUERADE rules.

---

## 10. Troubleshooting

**Symptom:** No inter-VLAN traffic at all.

- Confirm `FORWARD` policy is `DROP` and stateful rule exists:
  ```bash
  iptables -L FORWARD -n -v
  ```
- Check that at least one explicit ACCEPT rule matches the traffic.
- Verify `net.ipv4.ip_forward=1`.

**Symptom:** Lab VLAN can still reach other VLANs.

- Confirm DROP rules are present and ordered after stateful rules but before any broad ACCEPT.
- Use:
  ```bash
  iptables -L FORWARD -n -v --line-numbers
  ```
  to see rule order.

**Symptom:** Internet not reachable from VMs.

- Check NAT rules for correct source subnets.
- Verify uplink interface name (`vmbr0`) is correct.
- Confirm Proxmox host can reach the internet itself.

---

## 11. References

- [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0103 – Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)
- [Network Architecture](../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

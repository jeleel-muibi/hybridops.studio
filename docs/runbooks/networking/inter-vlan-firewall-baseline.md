---
title: "Inter-VLAN Firewall Baseline (Proxmox iptables)"
category: "networking"
summary: "Apply and verify baseline inter-VLAN firewall policy for Proxmox as intra-site core router."
severity: "P1"

topic: "inter-vlan-firewall"

draft: false
tags: ["networking", "firewall", "iptables", "security", "vlan"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Inter-VLAN Firewall Baseline (Proxmox iptables)

**Purpose:** Enforce the inter-VLAN firewall policy defined in ADR‑0103 on the Proxmox host acting as intra-site core router, and verify that environment isolation and exceptions behave as expected.  
**Owner:** Platform / Network Engineering  
**Trigger:** Initial firewall rollout, policy change, Proxmox host rebuild, or security review.  
**Impact:** Misconfiguration can break inter-VLAN traffic and internet access; must be executed in a controlled window with rollback ready.  
**Severity:** P1 (security and connectivity critical for the platform).  

---

## 1. Preconditions and Safety Checks

1. **ADR alignment confirmed:**  
   - ADR‑0101 – VLAN Allocation Strategy.  
   - ADR‑0102 – Proxmox as Intra-Site Core Router.  
   - ADR‑0103 – Inter-VLAN Firewall Policy.

2. **Network state healthy:**  
   - All VLAN interfaces (`vmbr0.10`, `.11`, `.20`, `.30`, `.40`, `.50`) are `UP`.  
   - VMs in each VLAN can reach their gateway (`10.X.0.1`).  
   - Internet access works from dev/staging/prod VMs.

3. **Out-of-band access available:**  
   - Proxmox console via web UI or physical access, in case SSH is locked out.

4. **Backup existing rules:**  

   ```bash
   # On Proxmox host
   mkdir -p /root/firewall-backup
   iptables-save > /root/firewall-backup/iptables-$(date +%Y%m%dT%H%M%SZ).rules
   ip6tables-save > /root/firewall-backup/ip6tables-$(date +%Y%m%dT%H%M%SZ).rules
   ```

5. **Ensure ip_forward is enabled:**  

   ```bash
   sysctl net.ipv4.ip_forward
   # Expected: net.ipv4.ip_forward = 1
   ```

---

## 2. Apply Baseline Policy

> This baseline assumes `iptables-persistent` is installed and used for persistence.

### 2.1 Flush Existing Rules (Controlled)

```bash
# WARNING: Do this only if you are confident about connectivity and have console access.
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
```

### 2.2 Allow Established and Related Traffic

```bash
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

### 2.3 Management VLAN Access (VLAN 10)

Management must reach all environments (restricted ports are refined later per-service).

```bash
# Management (10.10.0.0/24) can reach all VLANs
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT
```

### 2.4 Observability VLAN (VLAN 11)

Allow Prometheus/Grafana scraping into dev/staging/prod:

```bash
iptables -A FORWARD -s 10.11.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.30.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.40.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
```

### 2.5 Access to Management (All → VLAN 10)

Allow SSH/HTTPS from all VLANs back to management:

```bash
iptables -A FORWARD -d 10.10.0.0/24 -p tcp -m multiport --dports 22,443 -j ACCEPT
```

### 2.6 Lab Isolation (VLAN 50)

```bash
# Lab cannot reach others
iptables -A FORWARD -s 10.50.0.0/24 -j DROP
# Others cannot reach lab
iptables -A FORWARD -d 10.50.0.0/24 -j DROP
```

### 2.7 Production Isolation (VLAN 40)

```bash
iptables -A FORWARD -s 10.40.0.0/24 -d 10.20.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.50.0.0/24 -j DROP
```

### 2.8 Dev Isolation (VLAN 20)

```bash
iptables -A FORWARD -s 10.20.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.20.0.0/24 -d 10.40.0.0/24 -j DROP
```

> INTERNET access is handled via NAT on `vmbr0` and is not restricted here; adjust for egress filtering as needed.

### 2.9 Persist Rules

```bash
iptables-save > /etc/iptables/rules.v4
# If using ip6tables, also save v6
ip6tables-save > /etc/iptables/rules.v6
```

---

## 3. Verification

Run these checks from a jump host or directly on Proxmox plus representative VMs.

### 3.1 Check Policy and Counters

```bash
iptables -L FORWARD -n -v | head -20
```

**Expected:**

- Default policy for `FORWARD` is `DROP`.  
- Rules for management, observability, lab, dev, prod appear in order.

### 3.2 Environment Isolation Tests

From a **dev VM** (10.20.0.0/24):

```bash
ping -c3 10.20.0.1       # Gateway (should succeed)
ping -c3 8.8.8.8         # Internet (should succeed, if NAT ok)
ping -c3 10.30.0.10      # Staging (should FAIL)
ping -c3 10.40.0.10      # Production (should FAIL)
```

From a **staging VM** (10.30.0.0/24):

```bash
ping -c3 10.10.0.10      # Management (should succeed)
ping -c3 10.40.0.10      # Production (allowed if this path is permitted elsewhere)
```

From a **lab VM** (10.50.0.0/24):

```bash
ping -c3 10.20.0.10      # Dev (should FAIL)
ping -c3 10.40.0.10      # Prod (should FAIL)
```

From a **management host** (10.10.0.0/24):

```bash
ping -c3 10.20.0.10      # Dev (should succeed)
ping -c3 10.30.0.10      # Staging (should succeed)
ping -c3 10.40.0.10      # Prod (should succeed)
ping -c3 10.50.0.10      # Lab (should succeed unless further restricted)
```

### 3.3 Observability Access

From Prometheus/Grafana VM in VLAN 11:

```bash
curl -s http://10.20.0.10:9100/metrics | head -5
curl -s http://10.30.0.10:9100/metrics | head -5
curl -s http://10.40.0.10:9100/metrics | head -5
```

**Expected:** Metric output returned from all environments.  
If blocked, inspect iptables counters for observability rules.

### 3.4 Evidence Capture

```bash
ts=$(date +%Y%m%dT%H%M%SZ)
base="output/artifacts/networking/inter-vlan-fw-${ts}"
mkdir -p "${base}"

iptables-save > "${base}/iptables-rules.v4"
ip route show > "${base}/ip-route.txt"
```

Later, sync these into `docs/proof/networking/inter-vlan-firewall/` as part of your evidence pipeline.

---

## 4. Rollback

If connectivity is severely impacted:

1. **Restore previous ruleset:**

   ```bash
   iptables-restore < /root/firewall-backup/iptables-<timestamp>.rules
   ip6tables-restore < /root/firewall-backup/ip6tables-<timestamp>.rules 2>/dev/null || true
   ```

2. **Re-allow forwarding broadly (temporary emergency):**

   ```bash
   iptables -P FORWARD ACCEPT
   ```

3. Re-test basic reachability between VLANs and to the internet.  
4. Re-plan and test firewall changes in a staging environment before reapplying to the main Proxmox core.

---

## References

- [ADR-0101 – VLAN Allocation Strategy](docs/adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](docs/adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0103 – Inter-VLAN Firewall Policy](docs/adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [Network Architecture Overview](docs/prerequisites/network-architecture.md)  
- [Evidence](docs/proof/networking/inter-vlan-firewall/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

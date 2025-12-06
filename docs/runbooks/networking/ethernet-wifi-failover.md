title: "Ethernet/WiFi Uplink Failover"
category: "networking"
summary: "Switch Proxmox uplink between Ethernet and WiFi with minimal downtime and no VM reconfiguration."
severity: "P2"

topic: "ethernet-wifi-failover"

draft: false
is_template_doc: false
tags: ["networking", "proxmox", "uplink", "wifi", "ethernet"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Ethernet/WiFi Uplink Failover

**Purpose:** Execute a controlled failover between Ethernet and WiFi uplinks on the Proxmox host.  
**Owner:** Platform / Infrastructure operations.  
**Trigger:** Uplink failure, upstream switch maintenance, host relocation, or WiFi performance testing.  
**Impact:** Management IP for Proxmox changes; short loss of connectivity (target < 30 seconds). VMs remain running.  
**Severity:** P2.  
**Pre-reqs:**
- SSH or console access to Proxmox.
- WiFi interface configured with valid WPA credentials.
- /etc/network/interfaces contains both Ethernet and WiFi vmbr0 stanzas as per ADR-0105.
**Rollback strategy:** Re-apply the previous vmbr0 stanza from backup and reload networking.

---

## Context

Proxmox uses a VLAN-aware bridge (vmbr0) with subinterfaces for management, observability, and workload VLANs (ADR-0101, ADR-0102).  
Only one uplink is active at a time:
- Ethernet (enp87s0) as primary.
- WiFi (wlp89s0) as standby.

This runbook covers switching between the two uplinks. It does not cover initial WiFi configuration or ADR changes.

---

## Preconditions and safety checks

1. Confirm correct host and environment:
   ```bash
   hostnamectl
   ip addr show vmbr0
   ```

2. Confirm WiFi interface is present and associated (for failover *to* WiFi):
   ```bash
   iwconfig wlp89s0
   wpa_cli -i wlp89s0 status | grep wpa_state
   ```
   Expected: `wpa_state=COMPLETED`.

3. Backup current network configuration:
   ```bash
   cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
   ```

4. Ensure console access is available in case SSH is lost (physical, IPMI, or similar).

5. Confirm a suitable window:
   - No critical maintenance in progress.
   - Stakeholders informed of brief connectivity interruption.

---

## Steps

1) **Record current state**
   - Action: Capture current routing and vmbr0 configuration.
   - Command:
     ```bash
     ip route show default
     ip addr show vmbr0
     ```
   - Expected result: Default route via vmbr0 and current management IP (for example 192.168.0.27 on Ethernet).

2) **Edit vmbr0 stanza**
   - Action: Switch vmbr0 from current uplink to alternate uplink.
   - Command:
     ```bash
     vi /etc/network/interfaces
     ```
   - Procedure:
     - If failing over **from Ethernet to WiFi**:
       - Comment the Ethernet vmbr0 block.
       - Uncomment the WiFi vmbr0 block with address 192.168.0.30/24 and bridge-ports wlp89s0.
     - If failing over **from WiFi to Ethernet**:
       - Comment the WiFi vmbr0 block.
       - Uncomment the Ethernet vmbr0 block with address 192.168.0.27/24 and bridge-ports enp87s0.
   - Expected result: Exactly one vmbr0 stanza is active; VLAN subinterfaces remain unchanged.

3) **Reload network configuration**
   - Action: Apply the updated network configuration.
   - Command:
     ```bash
     ifreload -a
     ```
   - Expected result:
     - Command completes without errors.
     - Existing SSH session may drop for a few seconds.

4) **Reconnect to new management IP**
   - Action: Re-establish SSH session via new uplink address.
   - Command examples:
     ```bash
     # After failover to WiFi
     ssh root@192.168.0.30

     # After failback to Ethernet
     ssh root@192.168.0.27
     ```
   - Expected result: SSH access restored via correct IP.

5) **Verify bridge and VLAN interfaces**
   - Action: Confirm vmbr0 and VLAN subinterfaces are up.
   - Command:
     ```bash
     ip addr show vmbr0
     ip addr show | grep 'vmbr0.'
     ```
   - Expected result:
     - vmbr0 has the expected management IP.
     - vmbr0.10, vmbr0.11, vmbr0.20, vmbr0.30, vmbr0.40, vmbr0.50 are UP with their gateway IPs.

6) **Verify upstream and internet connectivity**
   - Action: Confirm routing and internet reachability from Proxmox.
   - Command:
     ```bash
     ping -c3 192.168.0.1
     ping -c3 8.8.8.8
     ```
   - Expected result: Low packet loss; both commands succeed.

7) **Verify VM connectivity**
   - Action: Confirm workloads still reach gateway and internet.
   - Examples:
     ```bash
     # From operator workstation
     ping -c3 10.20.0.10

     # From a VM in VLAN 20
     ping -c3 10.20.0.1
     ping -c3 8.8.8.8
     ```
   - Expected result: VMs retain connectivity; minor transient packet loss is acceptable.

8) **Confirm NAT and firewall state**
   - Action: Sanity-check NAT and FORWARD rules.
   - Command:
     ```bash
     iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE || true
     iptables -L FORWARD -n -v | head -20
     ```
   - Expected result: Expected MASQUERADE rules present; FORWARD policy and key rules match ADR-0103 baseline.

---

## Verification

Runbook is considered successful when:

- Proxmox management is reachable on the intended IP address.  
- All VLAN subinterfaces on vmbr0 are UP with correct addresses.  
- VMs in management, observability, and workload VLANs can reach their gateways and the internet.  
- Monitoring and automation systems can reach the host again (or DNS updated where applicable).  

---

## Post-actions and clean-up

- Update `docs/prerequisites/network-architecture.md` with active uplink and timestamp if this is a long-lived change.  
- Adjust Prometheus or other monitoring targets if static IPs are used instead of DNS.  
- If this was a temporary failover, schedule and execute failback using the same procedure in reverse.  

---

## References

- [ADR-0101 – VLAN Allocation Strategy](../../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0105 – Dual Uplink Design (Ethernet/WiFi Failover)](../../adr/ADR-0105-dual-uplink-ethernet-wifi-failover.md)
- [Network Architecture](../../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

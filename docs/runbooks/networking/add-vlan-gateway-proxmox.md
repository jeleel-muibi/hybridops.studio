title: "Add VLAN Gateway on Proxmox"
category: "networking"
summary: "Add a new VLAN interface and gateway on Proxmox vmbr0 for an additional subnet."
severity: "P3"

topic: "add-vlan-gateway-proxmox"

draft: false
is_template_doc: false
tags: ["networking", "proxmox", "vlan"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Add VLAN Gateway on Proxmox

**Purpose:** Introduce a new VLAN and routed subnet on the Proxmox host by adding a vmbr0.<vlan> gateway interface.  
**Owner:** Platform / Infrastructure operations.  
**Trigger:** New environment or network segment required (for example new lab, observability, or service VLAN).  
**Impact:** New routed subnet becomes available to VMs; firewall and NAT rules must be aligned with ADR-0103.  
**Severity:** P3 (planned change).  
**Pre-reqs:**
- VLAN ID and subnet approved according to ADR-0101.  
- Change window approved and documented.  
- Proxmox host running with vmbr0 configured as VLAN-aware bridge.  
**Rollback strategy:** Restore previous `/etc/network/interfaces` from backup and reload networking.

---

## Context

Proxmox acts as Layer 3 router for multiple VLANs (ADR-0102). New VLANs are introduced by:

- Adding `vmbr0.<vlan_id>` as a routed interface with gateway IP.  
- Ensuring NAT and firewall rules are updated to match the security model (ADR-0103).  

This runbook covers the Proxmox-side configuration only. Switch trunking and downstream devices are out of scope.

---

## Preconditions and safety checks

1. Confirm VLAN ID and subnet match the allocation strategy (ADR-0101).  
   - Example: VLAN 60, subnet 10.60.0.0/24, gateway 10.60.0.1.

2. Confirm vmbr0 is VLAN-aware and used as the primary bridge:
   ```bash
   ip -d link show vmbr0 | grep vlan_filtering
   ```

3. Backup current network configuration:
   ```bash
   cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
   ```

4. Confirm IP forwarding is enabled:
   ```bash
   sysctl net.ipv4.ip_forward
   ```
   Expected: `net.ipv4.ip_forward = 1`.

---

## Steps

1) **Define VLAN parameters**
   - Action: Decide VLAN ID, subnet, and gateway IP according to ADR-0101 and ADR-0104.
   - Example:
     - `VLAN_ID=60`
     - `SUBNET=10.60.0.0/24`
     - `GATEWAY=10.60.0.1`

2) **Edit network interfaces**
   - Action: Add vmbr0.<vlan_id> stanza.
   - Command:
     ```bash
     vi /etc/network/interfaces
     ```
   - Example configuration to add:
     ```bash
     auto vmbr0.60
     iface vmbr0.60 inet static
         address 10.60.0.1/24
     ```
   - Expected result: New stanza present; no syntax errors.

3) **Apply configuration**
   - Action: Reload networking.
   - Command:
     ```bash
     ifreload -a
     ```
   - Expected result: Command succeeds; existing connectivity preserved.

4) **Verify new interface**
   - Action: Confirm vmbr0.<vlan_id> is up with correct address.
   - Command:
     ```bash
     ip addr show vmbr0.60
     ```
   - Expected result: Interface UP, address 10.60.0.1/24 assigned.

5) **Add or update NAT rule (if internet access required)**
   - Action: Ensure outbound NAT for the new subnet.
   - Command example:
     ```bash
     iptables -t nat -A POSTROUTING -s '10.60.0.0/24' -o vmbr0 -j MASQUERADE
     ```
   - Expected result: Packets from 10.60.0.0/24 are NATed via vmbr0.
   - Note: Persist via iptables-persistent or Ansible role (see ADR-0103).

6) **Align firewall policy**
   - Action: Ensure inter-VLAN policy is updated.
   - Guidance:
     - Apply same pattern as existing VLANs in `FORWARD` chain.
     - Respect default-deny model from ADR-0103.
   - Command examples (inspection only):
     ```bash
     iptables -L FORWARD -n -v | head -40
     ```

7) **Connectivity test from Proxmox**
   - Action: Confirm routing from host.
   - Command:
     ```bash
     ping -c3 10.60.0.1
     # Optional: if a VM exists in this VLAN, ping its IP as well.
     ```
   - Expected result: Gateway responds; routing table includes 10.60.0.0/24 via vmbr0.60.

---

## Verification

- `vmbr0.<vlan_id>` exists and is UP with the configured gateway address.  
- `ip route` shows the subnet routed via vmbr0.<vlan_id>.  
- NAT and firewall rules align with ADR-0103 (no unexpected reachability to or from new VLAN).  
- Test VM attached to VLAN <vlan_id> can reach its gateway and, if intended, the internet.  

---

## Post-actions and clean-up

- Update `docs/prerequisites/network-architecture.md` with the new VLAN and subnet.  
- Ensure Terraform IPAM definitions (ADR-0104) include the new subnet when used.  
- Add monitoring and inventory entries (NetBox, Prometheus targets) for workloads attached to the new VLAN.  

---

## References

- [ADR-0101 – VLAN Allocation Strategy](../../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0103 – Inter-VLAN Firewall Policy](../../adr/ADR-0103-inter-vlan-firewall-policy.md)
- [ADR-0104 – Static IP Allocation with Terraform IPAM](../../adr/ADR-0104-static-ip-allocation-terraform-ipam.md)
- [Network Architecture](../../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

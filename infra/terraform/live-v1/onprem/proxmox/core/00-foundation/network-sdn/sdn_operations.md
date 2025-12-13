# Network SDN Operations

Operational procedures for managing the Proxmox SDN and DHCP configuration used by the  
`network-sdn` Terragrunt stack:

`platform/infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn`

This stack wraps the external Terraform module:

- [`terraform-proxmox-sdn`](https://github.com/hybridops-studio/terraform-proxmox-sdn)
- Terraform Registry: `hybridops-studio/proxmox-sdn/proxmox`

For end-to-end design, see:

- [How-to: Proxmox SDN with Terraform](https://docs.hybridops.studio/howtos/network/proxmox-sdn-terraform/)
- [Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/)

Conventions:

- `<PROXMOX_HOST>` is the Proxmox management endpoint (IP or DNS name).
- All Terraform commands are run via `terragrunt` from the stack directory.

---

## Deployment

### Initial deployment

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Review changes
terragrunt plan

# Apply configuration
terragrunt apply
```

### Update configuration

Modify `terragrunt.hcl` (for example, add VLANs or adjust DHCP ranges), then:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt plan
terragrunt apply
```

### Destroy (lab only)

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt destroy
```

> **Warning:** This removes SDN VNets and DHCP configuration.  
> Only use for lab tear-down or controlled rebuilds.

---

## Validation

### Quick health check

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Check Terraform state
terragrunt state list

# Check DHCP service
ssh root@<PROXMOX_HOST> 'systemctl status dnsmasq'

# Check VNet bridges
ssh root@<PROXMOX_HOST> 'ip addr show | grep vnet -A 2'
```

### Detailed validation

```bash
# 1. Verify VNet bridges exist
ssh root@<PROXMOX_HOST> 'ip link show | grep vnet'
# Expected: vnetmgmt, vnetobs, vnetdev, vnetstag, vnetprod, vnetlab

# 2. Verify gateway IPs are assigned
ssh root@<PROXMOX_HOST> 'ip addr show | grep "inet 10\."'
# Expected: 10.10.0.1, 10.11.0.1, 10.20.0.1, 10.30.0.1, 10.40.0.1, 10.50.0.1

# 3. Verify DHCP configuration
ssh root@<PROXMOX_HOST> 'cat /etc/dnsmasq.d/sdn-dhcp.conf'
# Should show interface blocks and dhcp-range lines for each VNet

# 4. Test DHCP config syntax
ssh root@<PROXMOX_HOST> 'dnsmasq --test'
# Expected: "dnsmasq: syntax check OK."

# 5. Check routes
ssh root@<PROXMOX_HOST> 'ip route | grep 10\.'
```

### Test from a VM

On a VM attached to one of the VNets (for example `vnetmgmt`):

```bash
# 1. Gateway reachable
ping 10.10.0.1

# 2. Internet reachable (NAT working)
ping 8.8.8.8

# 3. DNS resolution
nslookup google.com

# 4. DHCP lease obtained
ip addr show | grep "inet 10.10."
```

---

## DHCP management

### Service control

```bash
# Status
ssh root@<PROXMOX_HOST> 'systemctl status dnsmasq'

# Stop
ssh root@<PROXMOX_HOST> 'systemctl stop dnsmasq'

# Restart
ssh root@<PROXMOX_HOST> 'systemctl restart dnsmasq'

# Enable on boot
ssh root@<PROXMOX_HOST> 'systemctl enable dnsmasq'
```

### Monitoring

```bash
# Watch DHCP requests in real-time
ssh root@<PROXMOX_HOST> 'journalctl -u dnsmasq -f'

# View recent DHCP activity
ssh root@<PROXMOX_HOST> 'journalctl -u dnsmasq --since "10 minutes ago"'

# View active leases
ssh root@<PROXMOX_HOST> 'cat /var/lib/misc/dnsmasq.leases'
```

### Configuration

```bash
# View current config
ssh root@<PROXMOX_HOST> 'cat /etc/dnsmasq.d/sdn-dhcp.conf'

# After any manual edits (discouraged), restart service
ssh root@<PROXMOX_HOST> 'systemctl restart dnsmasq'
```

---

## Troubleshooting

### DHCP service will not start

**Symptoms**

- `systemctl status dnsmasq` shows `failed` or `inactive`.
- `dnsmasq --test` reports errors.

**Diagnosis**

```bash
ssh root@<PROXMOX_HOST> 'systemctl status dnsmasq'
ssh root@<PROXMOX_HOST> 'journalctl -u dnsmasq -n 50'
ssh root@<PROXMOX_HOST> 'dnsmasq --test'
```

**Common causes**

- Unknown interface → VNet bridge does not exist or has wrong name.
- Port already in use → another DHCP/DNS service running.
- Invalid argument → syntax error in config file.

**Fix**

```bash
# Find processes using DHCP/DNS ports
ssh root@<PROXMOX_HOST> 'ss -tulpn | grep -E ":(53|67)"'

# Stop conflicting DHCP servers
ssh root@<PROXMOX_HOST> 'systemctl stop isc-dhcp-server || true'
ssh root@<PROXMOX_HOST> 'systemctl disable isc-dhcp-server || true'

# Re-apply Terraform
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply
```

---

### VNet bridges missing

**Symptoms**

- `ip link show` does not list expected `vnet*` interfaces.
- Proxmox SDN UI does not show VNets in the zone as active.

**Fix**

```bash
# Check SDN zones
ssh root@<PROXMOX_HOST> 'pvesh get /cluster/sdn/zones'

# Reapply SDN config
ssh root@<PROXMOX_HOST> 'pvesh set /cluster/sdn'
```

If this persists, re-run the stack:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply
```

---

### VNet interfaces have no IPs

**Symptoms**

- `ip addr show vnet*` shows no `inet` address.
- VMs can reach each other at L2 but not the gateway.

**Diagnosis**

```bash
ssh root@<PROXMOX_HOST> 'ip addr show | grep vnet -A 2'
```

**Temporary fix (homelab)**

```bash
ssh root@<PROXMOX_HOST> << 'SSHEOF'
ip addr add 10.10.0.1/24 dev vnetmgmt 2>/dev/null || true
ip addr add 10.11.0.1/24 dev vnetobs 2>/dev/null || true
ip addr add 10.20.0.1/24 dev vnetdev 2>/dev/null || true
ip addr add 10.30.0.1/24 dev vnetstag 2>/dev/null || true
ip addr add 10.40.0.1/24 dev vnetprod 2>/dev/null || true
ip addr add 10.50.0.1/24 dev vnetlab 2>/dev/null || true
SSHEOF
```

**Permanent fix**

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply
```

---

### VMs not getting DHCP

**Symptoms**

- VM boots but does not obtain an IP address.
- No new entries in `dnsmasq` leases.

**Diagnosis**

```bash
# 1. Confirm VM is attached to a VNet bridge (not vmbr0.<vlan-id>)
#    In Proxmox UI: VM → Hardware → Network Device → Bridge should be "vnetmgmt", not "vmbr0.10"

# 2. Monitor DHCP while VM boots
ssh root@<PROXMOX_HOST> 'journalctl -u dnsmasq -f'

# 3. Inside VM: check interface state
ip link show
# Interface should show "state UP"
```

**Fix**

```bash
# If VM attached to wrong bridge, fix in Proxmox UI or via CLI.

# If interface is down (inside VM):
ip link set eth0 up

# Request DHCP manually (inside VM):
dhclient -v eth0

# If cloud-init is used, inspect logs:
cat /var/log/cloud-init.log
```

---

### DHCP config has `interface=null`

**Symptoms**

- `/etc/dnsmasq.d/sdn-dhcp.conf` contains `interface=null`.
- `dnsmasq --test` fails due to invalid interface.

**Cause**

`setup-dhcp.sh` failed to parse the JSON payload from Terraform and wrote a bad config.

**Fix**

```bash
# Remove bad config
ssh root@<PROXMOX_HOST> 'rm /etc/dnsmasq.d/sdn-dhcp.conf'

# Re-apply Terraform to regenerate config
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply

# Verify interfaces are correct
ssh root@<PROXMOX_HOST> 'grep interface /etc/dnsmasq.d/sdn-dhcp.conf'
# Expected: interface=vnetmgmt, interface=vnetobs, etc.
```

---

### Port conflicts

**Symptoms**

- `dnsmasq` fails with "address already in use".
- Another DHCP/DNS service is bound to port 53 or 67.

**Diagnosis**

```bash
ssh root@<PROXMOX_HOST> 'ss -tulpn | grep -E ":(53|67)"'
```

**Fix**

```bash
# Stop conflicting services
ssh root@<PROXMOX_HOST> 'systemctl stop isc-dhcp-server || true'
ssh root@<PROXMOX_HOST> 'systemctl disable isc-dhcp-server || true'

# Kill any rogue dnsmasq processes
ssh root@<PROXMOX_HOST> 'pkill -9 dnsmasq || true'

# Restart dnsmasq
ssh root@<PROXMOX_HOST> 'systemctl restart dnsmasq'
```

---

### Inter-VLAN routing not working

**Symptoms**

- VMs can reach their gateway but not other VLANs or the internet.

**Diagnosis**

```bash
# Check IP forwarding
ssh root@<PROXMOX_HOST> 'sysctl net.ipv4.ip_forward'

# Check routes
ssh root@<PROXMOX_HOST> 'ip route | grep 10\.'

# Check NAT rules
ssh root@<PROXMOX_HOST> 'iptables -t nat -L POSTROUTING -n -v'

# Check firewall rules
ssh root@<PROXMOX_HOST> 'iptables -L FORWARD -n -v'
```

**Fix (homelab baseline)**

```bash
# Enable IP forwarding (if disabled)
ssh root@<PROXMOX_HOST> 'sysctl -w net.ipv4.ip_forward=1'
ssh root@<PROXMOX_HOST> 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

# Add NAT rules (if missing) – adjust outbound interface as needed
ssh root@<PROXMOX_HOST> << 'SSHEOF'
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.11.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.20.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.30.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.40.0.0/24 -o vmbr0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.50.0.0/24 -o vmbr0 -j MASQUERADE
SSHEOF
```

> In production, firewall and NAT rules should be managed via Ansible and defined in the firewall ADRs.

---

### VNet interfaces persist after destroy

After `terragrunt destroy`, SDN configuration may be removed but VNet bridge
interfaces can persist in the kernel until networking is reloaded.

**Symptoms**

- Terraform/Terragrunt reports resources destroyed.
- `/etc/pve/sdn/*.cfg` files are empty or no longer reference the VNets.
- VNet interfaces are still visible in `ip link show`.
- Proxmox UI shows VNets in `deleted` or `error` state.

**Workaround (homelab pattern)**

```bash
# On Proxmox host
ssh root@<PROXMOX_HOST>

for vnet in vnetdev vnetlab vnetmgmt vnetobs vnetprod vnetstag; do
  ip link set "$vnet" down 2>/dev/null || true
  ip link delete "$vnet" 2>/dev/null || true
done

ifreload -a
pvesh set /cluster/sdn
```

Use with care if the node runs other SDN zones or VNets with different names.

**Root cause**

On Proxmox VE 8.x, SDN does not always remove kernel interfaces when SDN
objects are deleted via the API. Interfaces can persist until networking is
reloaded or the node is rebooted.

**Recommendation**

For ongoing changes, prefer `apply`-driven updates over destroy/recreate
workflows. Reserve full destroy for lab tear-down or controlled rebuilds.

---

## Maintenance

### View Terraform state and outputs

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# List all resources
terragrunt state list

# Show a specific resource
terragrunt state show 'proxmox_virtual_environment_sdn_vnet.vnet["vnetmgmt"]'

# View all module outputs
terragrunt output

# Or inspect specific outputs from terraform-proxmox-sdn:
terragrunt output zone_name
terragrunt output vnets
terragrunt output subnets
```

Typical usage:

- `zone_name` → confirm the active SDN zone ID in Proxmox.
- `vnets` → see VNet IDs and VLAN tags for wiring VM NICs.
- `subnets` → confirm CIDRs, gateways, and DHCP configuration per VNet.

### Update DHCP ranges

Edit `terragrunt.hcl`:

```hcl
vnets = {
  vnetmgmt = {
    subnets = {
      submgmt = {
        dhcp_range_start = "10.10.0.150"
        dhcp_range_end   = "10.10.0.250"
        # ...
      }
    }
  }
}
```

Then apply:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply
```

### Add new VLAN

Edit `terragrunt.hcl`:

```hcl
vnets = {
  # ... existing vnets ...

  vnetnew = {
    vlan_id     = 60
    description = "New network"
    subnets = {
      subnew = {
        cidr             = "10.60.0.0/24"
        gateway          = "10.60.0.1"
        vnet             = "vnetnew"
        dhcp_enabled     = true
        dhcp_range_start = "10.60.0.100"
        dhcp_range_end   = "10.60.0.200"
        dhcp_dns_server  = "8.8.8.8"
      }
    }
  }
}
```

Then apply:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply
```

---

## Emergency procedures

### Complete DHCP failure

If DHCP is completely broken and VMs need connectivity:

```bash
# 1. Stop dnsmasq
ssh root@<PROXMOX_HOST> 'systemctl stop dnsmasq'

# 2. Remove SDN DHCP configs
ssh root@<PROXMOX_HOST> 'rm /etc/dnsmasq.d/sdn-dhcp.conf'

# 3. Re-apply from scratch
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt destroy -auto-approve
terragrunt apply -auto-approve

# 4. If still broken, assign static IPs to critical VMs temporarily.
```

### SDN corruption

If SDN state is corrupted in Proxmox:

```bash
# 1. Backup current config
ssh root@<PROXMOX_HOST> 'tar czf /root/sdn-backup-$(date +%Y%m%d).tar.gz /etc/pve/sdn /etc/dnsmasq.d'

# 2. Clean SDN config via UI:
#    Datacenter → SDN → Zones/VNets/Subnets → Delete all

# 3. Re-apply from Terraform
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn
terragrunt apply -auto-approve
```

### Rollback to previous state

If a change causes issues:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Revert to previous git commit for this stack
git log --oneline terragrunt.hcl
git checkout <previous-commit> terragrunt.hcl

# Re-apply
terragrunt apply
```

---

## Monitoring

### Key health indicators

```bash
# Check active DHCP config
ssh root@<PROXMOX_HOST> 'cat /etc/dnsmasq.d/sdn-dhcp.conf'

# Service status
ssh root@<PROXMOX_HOST> 'systemctl is-active dnsmasq'

# VNet bridge count (expected: 6 for homelab design)
ssh root@<PROXMOX_HOST> 'ip link show | grep -c vnet'

# Gateway IPs assigned (expected: 6)
ssh root@<PROXMOX_HOST> 'ip addr show | grep -c "inet 10\."'

# Active DHCP leases
ssh root@<PROXMOX_HOST> 'wc -l < /var/lib/misc/dnsmasq.leases'
```

### Recommended alerts

Monitor and alert on:

- `dnsmasq` service is not active.
- VNet bridge count ≠ expected baseline.
- Any VNet bridge has no IP address.
- DHCP lease pool > 80% utilised per VLAN.

Integration with Prometheus/Alertmanager is aligned with:

- [ADR-0401 – Unified Observability with Prometheus](https://docs.hybridops.studio/adr/ADR-0401-unified-observability-with-prometheus/)

---

## References

- [Network SDN stack README](./README.md)
- [How-to: Proxmox SDN with Terraform](https://docs.hybridops.studio/howtos/network/proxmox-sdn-terraform/)
- [Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/)
- [ADR-0101 – VLAN Allocation Strategy](https://docs.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)
- [ADR-0102 – Proxmox as Core Router](https://docs.hybridops.studio/adr/ADR-0102-proxmox-intra-site-core-router/)
- [ADR-0103 – Inter-VLAN Firewall Policy](https://docs.hybridops.studio/adr/ADR-0103-inter-vlan-firewall-policy/)
- [ADR-0104 – Static IP Allocation (Terraform IPAM)](https://docs.hybridops.studio/adr/ADR-0104-static-ip-allocation-terraform-ipam/)

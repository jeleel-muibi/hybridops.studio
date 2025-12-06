---
title: "HOWTO: Configure Dual ISP on pfSense/CSR"
category: "networking"
summary: "Step-by-step guide to configuring dual ISP failover and testing it end-to-end."
difficulty: "Advanced"

topic: "dual-isp-setup"
video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"

draft: false
tags: ["networking", "isp", "pfsense", "csr1000v", "resiliency"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Configure Dual ISP on pfSense and CSR1000v

**Purpose:** Configure and understand dual-ISP connectivity using pfSense as the firewall/policy engine and Cisco CSR1000v as the routed edge, in line with ADR-0106.  
**Difficulty:** Advanced  
**Prerequisites:** Working single-ISP path via pfSense, deployed CSR1000v, admin access to pfSense WebGUI/SSH and CSR console/SSH.

---

## 1. Context

This HOWTO is a teaching guide that complements:

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)  
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../../adr/ADR-0107-vyos-edge-router.md)  

The goal is to:

- Terminate **two ISPs** on pfSense (`WAN_A`, `WAN_B`).  
- Use **gateway groups** and **health checks** for automatic failover.  
- Keep CSR1000v configuration simple (default route via pfSense) while still exercising dual-ISP behaviour.  

This is not an incident runbook; use it to build and understand the pattern. Runbooks will reference this HOWTO for deeper background.

---

## Demo / Walk-through

??? info "▶ Watch the dual ISP failover demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="Dual ISP Failover Demo – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

## 2. Lab Assumptions

Replace the examples with your real values.

### 2.1 Addresses

| Component          | Example value      |
|--------------------|-------------------|
| pfSense LAN IP     | 10.10.0.10        |
| CSR inside IP      | 10.10.0.20        |
| ISP A gateway      | 203.0.113.1       |
| ISP B gateway      | 198.51.100.1      |
| Test VM (behind FW)| 10.20.0.10        |

### 2.2 Starting State

You should already have:

- Proxmox and VLANs wired as per *Network Architecture* and ADR-0101.  
- pfSense acting as firewall with **one working ISP**.  
- CSR1000v reachable from management and able to reach the internet through pfSense via a single default route.  

---

## 3. High-Level Design

### 3.1 Roles

- **pfSense**  
  - Terminates both ISP links.  
  - Performs health checks and failover via **gateway groups**.  
  - Applies policy routing and outbound NAT.

- **CSR1000v**  
  - Uses pfSense as default gateway.  
  - Terminates IPsec/BGP towards cloud or remote sites.  
  - Does not need to know which ISP is active; pfSense hides that complexity.

### 3.2 Behaviour Targets

- Under normal conditions: all egress traffic uses **ISP A**.  
- On ISP A failure or severe degradation: traffic automatically switches to **ISP B**.  
- When ISP A recovers: optional preemption back to ISP A after a stabilisation period (configured in pfSense).  

---

## 4. Configure pfSense – Dual WAN

All steps use the pfSense WebGUI unless stated otherwise.

### 4.1 Verify WAN Interfaces

1. **Interfaces → Assignments**  
   - Confirm one interface is `WAN_A` (e.g. `vmx0`) and another is `WAN_B` (e.g. `vmx1` or a VLAN).  
2. Under **Interfaces → WAN_A / WAN_B**:  
   - Set IPv4 configuration to **Static** or **DHCP** as required.  
   - Ensure each has a working gateway (either via ISP or manually set).  

**Validation:** `Status → Interfaces` shows both WANs with expected IPs and “up” status.

### 4.2 Define Gateways and Monitors

1. Go to **System → Routing → Gateways**.  
2. For each WAN entry:  
   - Give a clear **Name**: `WAN_A_GW`, `WAN_B_GW`.  
   - Set **Monitor IP** to a stable public target (e.g. `8.8.8.8` for WAN_A, `1.1.1.1` for WAN_B).  
3. Save and apply.

**Validation:** `Status → Gateways` shows RTT and loss metrics for both gateways.

### 4.3 Create a Gateway Group

1. Navigate to **System → Routing → Gateway Groups** → **Add**.  
2. Create group `WAN_A_PRIMARY` with:  
   - `WAN_A_GW` at **Tier 1**.  
   - `WAN_B_GW` at **Tier 2**.  
3. Set **Trigger Level** to:  
   - `Member Down` for simple failover; or  
   - `Packet Loss or High Latency` if you want brownout detection.  
4. Save and **Apply Changes**.

This group will be referenced by firewall rules for policy routing.

### 4.4 Update LAN Rule to Use Gateway Group

1. Go to **Firewall → Rules → LAN**.  
2. Locate the rule that allows outbound traffic from LAN (for example `LAN net → any`).  
3. Edit the rule and open **Advanced options → Gateway**.  
4. Select `WAN_A_PRIMARY` (the gateway group).  
5. Save and **Apply Changes**.

**Result:** all LAN traffic now follows the gateway group behaviour instead of a single WAN.

### 4.5 Outbound NAT for Both ISPs

1. Open **Firewall → NAT → Outbound**.  
2. Switch to **Hybrid** or **Manual** mode (if not already).  
3. Ensure there are outbound NAT rules covering LAN net to **both** WAN_A and WAN_B.  
   - Example (manual mode):
     - Rule 1: Source `LAN net`, Translation `WAN_A address`.  
     - Rule 2: Source `LAN net`, Translation `WAN_B address`.  
4. Save and apply.

**Validation:** From a test VM, outbound traffic works over ISP A initially; NAT is visible in pfSense logs for both WANs when you later force failover.

---

## 5. Configure CSR1000v – Edge Integration

### 5.1 Default Route via pfSense

On CSR1000v, configure a single default route to pfSense on the inside/LAN network.

```shell
conf t
 ip route 0.0.0.0 0.0.0.0 10.10.0.10
end
write memory
```

**Notes:**

- `10.10.0.10` is the pfSense LAN IP in this example.  
- CSR does not need to know ISP-specific gateways; pfSense abstracts that choice.  

**Validation:**

```shell
show ip route 0.0.0.0
show ip cef 0.0.0.0 0.0.0.0
```

You should see a single default route via pfSense.

### 5.2 (Optional) IPsec / BGP

If CSR terminates IPsec/BGP to cloud:

- Keep tunnel configuration unchanged; pfSense will move traffic between ISP A and B.  
- In advanced scenarios, you may add tracking or SLA logic on CSR side to confirm that tunnels stay up during failover. That belongs in a dedicated HOWTO (for example “HOWTO: CSR IPsec DR with Dual ISP”).

---

## 6. Validation Exercises

The aim here is to **prove** that failover is automatic and observable.

> Suggested evidence location: `docs/proof/networking/dual-isp-tests/`

### 6.1 Baseline – ISP A Active

From a **test VM** behind pfSense:

```bash
curl https://ifconfig.me
traceroute 8.8.8.8 || mtr 8.8.8.8
```

- Confirm that the public IP belongs to ISP A.  
- Save the output as `baseline-isp-a.txt`.

From **CSR**:

```shell
ping 8.8.8.8 source 10.10.0.20
traceroute 8.8.8.8
```

- Confirm successful reachability.

In pfSense UI:

- `Status → Gateways` shows WAN_A as **Online**, WAN_B as **Online (standby)**.  
- Capture a screenshot or export as evidence.

### 6.2 Simulate ISP A Failure

Pick one method:

- Disable the `WAN_A` interface in pfSense.  
- Or disconnect / disable the upstream switch port feeding WAN_A (lab only).  

Observe:

1. `Status → Gateways` should mark `WAN_A_GW` as **Offline/Down**.  
2. Gateway group selects `WAN_B_GW`.  

Repeat the same tests from the VM:

```bash
curl https://ifconfig.me
traceroute 8.8.8.8 || mtr 8.8.8.8
```

- Public IP should now belong to **ISP B**.  
- Latency profile may change, but connectivity should be intact.

From CSR:

```shell
ping 8.8.8.8 source 10.10.0.20
traceroute 8.8.8.8
```

- CSR config is unchanged; default route still via pfSense; traffic now exits via ISP B transparently.

Record timing:

- Measure time from simulated failure to restored reachability (`ping` stop → start).  
- For blueprint purposes, target **failover < 30 seconds**.

### 6.3 Recovery and (Optional) Preemption

Re-enable `WAN_A`:

- Reconnect link or re-enable interface.  
- Watch `Status → Gateways` until WAN_A returns to **Online**.  

Depending on pfSense group settings:

- If **preemption** is enabled, traffic will return automatically to ISP A.  
- If not, gateway group may stay on ISP B until manual intervention.

Repeat connectivity tests and confirm that:

- Public IP switches back to ISP A when preemption occurs.  
- No configuration change is required on CSR.

---

## 7. Troubleshooting

### 7.1 Both ISPs Up but No Failover

**Symptom:** Breaking ISP A does not move traffic to ISP B.

- Check `System → Routing → Gateway Groups` – confirm tiers are set correctly.  
- Verify the LAN firewall rule actually references the **gateway group**, not a single gateway.  
- Confirm monitor IPs are reachable from each WAN when links are healthy.

### 7.2 Failover Occurs, but Traffic Still Fails

**Symptom:** pfSense shows WAN_B active, but VMs cannot reach the internet.

- Verify outbound NAT rules cover **LAN → WAN_B**.  
- Check pfSense firewall logs for blocked outbound packets.  
- From pfSense shell:
  ```bash
  ping -c3 8.8.8.8 -S <wan_b_ip>
  ```
- If that fails, investigate ISP B connectivity (modem / upstream).

### 7.3 CSR Loses Connectivity During Failover

**Symptom:** CSR cannot reach internet during gateway switch.

- Confirm `ip route` on CSR still shows default via pfSense.  
- Check that pfSense LAN interface remained stable (no address change).  
- Make sure there is no overlapping static route on CSR that overrides default during tests.

### 7.4 Flapping Between ISPs

**Symptom:** Frequent failover / failback even without clear outages.

- Relax monitoring thresholds: longer probe intervals, higher loss tolerance.  
- Disable preemption if not needed; keep traffic on ISP B until manual switch back.  
- Ensure monitor IPs are stable and not rate-limiting ICMP.

---

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](../../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../../adr/ADR-0107-vyos-edge-router.md)
- [Runbook: Dual ISP Load Balancing](../../runbooks/networking/dual-isp-loadbalancing.md)
- [Evidence: Dual ISP Tests](../../proof/networking/dual-isp-tests/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

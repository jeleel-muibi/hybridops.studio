---
title: "Configure Dual Uplink (Ethernet/WiFi) on Proxmox"
category: "networking"
summary: "Enable a Proxmox host to switch between Ethernet and WiFi uplinks without VM reconfiguration."
difficulty: "Intermediate"

topic: "proxmox-dual-uplink"

video: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
source: ""

draft: false
tags: ["proxmox", "networking", "wifi", "failover", "uplink"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Configure Dual Uplink (Ethernet/WiFi) on Proxmox

**Purpose:** Configure a Proxmox host so the primary uplink is Ethernet and a secondary WiFi uplink can be activated on demand with minimal downtime.  
**Difficulty:** Intermediate  
**Target host:** Proxmox VE hypervisor with one Ethernet NIC and one WiFi NIC.

This HOWTO prepares the configuration used by the *Ethernet/WiFi Uplink Failover* runbook.

---

## Demo / Walk-through

??? info "▶ Watch the dual uplink configuration demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="Dual Uplink (Ethernet/WiFi) on Proxmox – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Prerequisites

- Proxmox VE installed and reachable via Ethernet.
- One wired NIC (e.g. `enp87s0`) and one WiFi NIC (e.g. `wlp89s0`).
- WiFi network credentials (SSID and pre-shared key).
- SSH or console access as root.
- Current network config based on `/etc/network/interfaces` (no NetworkManager).

Backup current configuration:

```bash
cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
```

---

## 2. Verify Interfaces

List network interfaces:

```bash
ip link show
```

Identify the wired NIC (e.g. `enp87s0`) and wireless NIC (e.g. `wlp89s0`).

Check WiFi capabilities:

```bash
iwconfig wlp89s0
```

Expected: output shows `IEEE 802.11` rather than "no wireless extensions".

---

## 3. Configure WiFi Credentials

Install WiFi tools if required:

```bash
apt update
apt install -y wpasupplicant wireless-tools
```

Create WPA supplicant configuration:

```bash
wpa_passphrase "SSID_HERE" "PASSPHRASE_HERE" > /etc/wpa_supplicant/wpa_supplicant.conf
```

Validate:

```bash
cat /etc/wpa_supplicant/wpa_supplicant.conf
```

The file should contain a `network { ... }` block with encrypted `psk`.

---

## 4. Define Dual-Uplink Network Configuration

Edit `/etc/network/interfaces`:

```bash
vi /etc/network/interfaces
```

Example configuration:

```bash
# Loopback
auto lo
iface lo inet loopback

# WiFi management
auto wlp89s0
iface wlp89s0 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

# Ethernet uplink (ACTIVE by default)
auto vmbr0
iface vmbr0 inet static
    address 192.168.0.27/24
    gateway 192.168.0.1
    bridge-ports enp87s0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 10 11 20 30 40 50

# WiFi uplink (STANDBY - commented by default)
#auto vmbr0
#iface vmbr0 inet static
#    address 192.168.0.30/24
#    gateway 192.168.0.1
#    bridge-ports wlp89s0
#    bridge-stp off
#    bridge-fd 0
#    bridge-vlan-aware yes
#    bridge-vids 10 11 20 30 40 50

# VLAN subinterfaces (gateways for internal VLANs)
auto vmbr0.10
iface vmbr0.10 inet static
    address 10.10.0.1/24

auto vmbr0.11
iface vmbr0.11 inet static
    address 10.11.0.1/24

auto vmbr0.20
iface vmbr0.20 inet static
    address 10.20.0.1/24

auto vmbr0.30
iface vmbr0.30 inet static
    address 10.30.0.1/24

auto vmbr0.40
iface vmbr0.40 inet static
    address 10.40.0.1/24

auto vmbr0.50
iface vmbr0.50 inet static
    address 10.50.0.1/24
```

Key points:

- Only one `vmbr0` stanza is active at a time.
- VLAN subinterfaces are shared across both uplink modes.
- WiFi uplink uses a different management IP (192.168.0.30) to avoid conflicts.

---

## 5. Apply and Validate Ethernet Mode

Reload the network configuration:

```bash
ifreload -a
```

Confirm Ethernet-based `vmbr0` is active:

```bash
ip addr show vmbr0
```

Expected: `inet 192.168.0.27/24` present.

Verify VLAN gateways:

```bash
ip addr show | grep vmbr0.
```

Expected: gateway IPs 10.10.0.1, 10.11.0.1, 10.20.0.1, 10.30.0.1, 10.40.0.1, 10.50.0.1.

Check external connectivity:

```bash
ping -c3 8.8.8.8
```

---

## 6. Test Failover to WiFi

### 6.1 Switch Configuration

Edit `/etc/network/interfaces` again:

- Comment the Ethernet `vmbr0` stanza.
- Uncomment the WiFi `vmbr0` stanza.

Apply changes:

```bash
ifreload -a
```

Expect a brief connectivity interruption while the bridge reconfigures.

### 6.2 Reconnect and Verify

Reconnect using the WiFi-backed management IP:

```bash
ssh root@192.168.0.30
```

Verify bridge IP:

```bash
ip addr show vmbr0 | grep inet
```

Expected: `inet 192.168.0.30/24`

Confirm WiFi association:

```bash
iwconfig wlp89s0
```

Expected: `ESSID` populated and signal quality present.

Check internet connectivity:

```bash
ping -c3 8.8.8.8
curl -I https://download.proxmox.com
```

Validate VLAN gateways again (they should be unchanged).

---

## 7. Switch Back to Ethernet

To return to Ethernet as primary uplink:

- Uncomment the Ethernet `vmbr0` stanza.
- Comment the WiFi `vmbr0` stanza.
- Run `ifreload -a`.
- Reconnect to 192.168.0.27.

---

## 8. Troubleshooting

**Symptom:** WiFi never associates.

- Validate `/etc/wpa_supplicant/wpa_supplicant.conf` SSID and PSK.
- Check status:
  ```bash
  wpa_cli -i wlp89s0 status
  ```
- Ensure WiFi NIC is up:
  ```bash
  ip link set wlp89s0 up
  ```

**Symptom:** VLAN interfaces disappear after switching uplink.

- Confirm VLAN subinterfaces are not commented in `/etc/network/interfaces`.
- Check link status:
  ```bash
  ip addr show | grep vmbr0.
  ```

**Symptom:** VMs cannot reach the internet after failover.

- Verify default route on Proxmox:
  ```bash
  ip route show default
  ```
- Confirm NAT rules (see ADR-0102 / ADR-0103):
  ```bash
  iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
  ```

---

## 9. References

- [ADR-0101: VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0102: Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0105: Dual Uplink Design (Ethernet/WiFi Failover)](../adr/ADR-0105-dual-uplink-ethernet-wifi-failover.md)
- [Runbook: Ethernet/WiFi Uplink Failover](../runbooks/networking/ethernet-wifi-failover.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

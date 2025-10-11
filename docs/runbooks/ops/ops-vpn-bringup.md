---
title: "Ops: Site-to-Site VPN Bring-Up"
category: ops
summary: "Bring up IPsec tunnels and BGP routing between on-prem and cloud hub/spokes; verify routes."
last_updated: 2025-10-08
severity: P1
---

# Ops: Site‑to‑Site VPN Bring‑Up

**Purpose:** Establish IPsec between on‑prem and cloud hub/spoke; verify routes.
**Owner:** NetOps

## Pre‑requisites
- Pre‑shared keys/certs, peer IPs, subnets, IKE/ESP params agreed.
- NCC/Hub configured to accept the tunnel (cloud side).

## Rollback
- Disable tunnel; remove routes; revert device changes.

## Steps

1) **Apply device configuration**
- Push Ansible role or vendor CLI for IPsec/IKE + BGP (if used).

2) **Verify tunnel + routing**
```bash
# On-prem
show crypto isakmp sa    # or vendor equivalent
# Cloud (example)
az network vpn-connection show ... | jq '.connectionStatus'
# Routes
traceroute <cloud-service-ip> || mtr <fqdn>
```

## Evidence
- Tunnel up/route tables screenshots → `docs/proof/vpn/images/`.
- CLI outputs → `output/artifacts/decision/` or `output/logs/network/`.

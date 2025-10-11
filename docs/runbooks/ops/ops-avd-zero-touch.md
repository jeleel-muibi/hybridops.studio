---
title: "Ops: AVD Zero-Touch"
category: ops
summary: "Stand up Azure Virtual Desktop session hosts and core infra via IaC."
last_updated: 2025-10-08
severity: P3
---

# Ops: AVD Zero‑Touch

**Purpose:** Stand up AVD session hosts and core infra via IaC.
**Owner:** EUC/Platform SRE

## Pre‑requisites
- Azure creds; VNet/subnets defined (hub‑and‑spoke recommended).
- Domain join path available (on‑prem AD or Azure AD DS).

## Steps

1) **Networking & identity**
- Ensure hub/spoke and private DNS are in place (see AVD networking notes).

2) **Deploy AVD infra (Make/TF)**
```bash
make showcase.avd-zerotouch-deployment.demo   | tee "output/logs/avd/$(date -Iseconds)_demo.log"
```

3) **Validate session hosts**
- Session hosts report `Available`; test login, profile, app access.

## Evidence
- Host pool/sessions screenshots → `docs/proof/others/assets/`.
- TF/Make logs under `output/logs/avd/`.

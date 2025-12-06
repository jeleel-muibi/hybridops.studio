---
title: "pfSense Firewall Flow Control"
category: "security"
summary: "Operate pfSense as the primary firewall and flow-control layer for on-prem and hybrid traffic."
severity: "P2"

topic: "security-pfsense-flow-control"

draft: false
tags: ["pfsense", "firewall", "flow-control", "security", "ha"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# pfSense Firewall Flow Control

**Purpose:** Safely operate pfSense as the primary firewall and flow-control plane, including HA, NAT, and policy routing adjustments.  
**Owner:** Security / Network Engineering  
**Trigger:** Firewall policy change, DR test, HA failover drill, or new hybrid path rollout.  
**Impact:** Directly affects inbound/outbound connectivity; misconfiguration can break edge access.  
**Severity:** P2  
**Pre-reqs:** pfSense HA pair deployed (`fw-01`, `fw-02`), CARP VIPs configured, admin access to GUI/SSH, change request approved.  
**Rollback strategy:** Restore previous pfSense configuration snapshot or XML backup and trigger CARP failover if required.

---

## Quick Checklist

- [ ] Confirm pfSense HA status and CARP VIP ownership.  
- [ ] Take a configuration backup before any change.  
- [ ] Apply NAT, firewall, and policy routing updates on the primary node only.  
- [ ] Sync to secondary and validate flows from key segments.  
- [ ] Capture minimal evidence for flows and HA behaviour.  

---

## Preconditions and Safety Checks

Before changing any rules:

1. **Verify HA status**

   From the primary pfSense GUI:

   - Go to **Status ▸ CARP (Failover)**.
   - Confirm expected node owns each VIP (typically `MASTER` on `fw-01`, `BACKUP` on `fw-02`).
   - Ensure **no CARP demotion** values are present.

   From the shell (optional):

   ```sh
   ifconfig | grep -A3 carp
   ```

2. **Verify config sync health**

   - Go to **Status ▸ System Logs ▸ System ▸ Gateways / Sync**.
   - Check that XMLRPC sync is succeeding and there are no recent sync errors.

3. **Confirm monitoring**

   - Ensure you have dashboards/alerts for:
     - WAN A/B gateway status.
     - VPN/IPsec tunnels (if in scope).
     - Key LAN services (HTTP, SSH, DNS).

4. **Schedule/announce change**

   - Notify affected users or mark a maintenance window if the change is high impact.
   - Have console/IPMI access available in case network access is lost.

---

## 1. Baseline and Backup

**Goal:** Ensure a known-good rollback point exists before any change.

### 1.1 Capture running configuration

From the primary pfSense GUI:

1. Navigate to **Diagnostics ▸ Backup & Restore**.
2. In the **Backup** tab, export the full configuration XML.
3. Save it with a timestamped name, for example:

   ```text
   pfsense-fw-01-config-YYYYMMDD-HHMM.xml
   ```

Store it under your repo’s evidence directory:

```text
docs/proof/security/pfsense-ha-tests/backups/
```

### 1.2 Snapshot HA status

Optional but recommended:

- From **Status ▸ CARP (Failover)**, capture a screenshot or export:

  ```sh
  ifconfig | grep -A3 carp > /tmp/pfsense-carp-status-pre.txt
  ```

Archive this alongside the backup.

---

## 2. Confirm Existing Flows

**Goal:** Know what “good” looks like before you change anything.

From a jump host or bastion, test at least:

```sh
# Example tests from a management host
ping -c3 8.8.8.8
curl -I https://www.google.com

# From a key VLAN (replace with real subnets)
ping -c3 10.20.0.1     # dev gateway
ping -c3 10.40.0.1     # prod gateway (if allowed)
```

If any of these fail, stop and investigate before applying changes.

---

## 3. Apply Flow-Control Changes (Primary Node)

**Goal:** Apply and stage firewall/NAT/policy routing changes on the primary pfSense node.

1. Log in to the **primary** pfSense GUI (`fw-01`).  
2. Implement changes from your approved change plan, typically in this order:
   - **Firewall ▸ Aliases** – update address/port groups if used.
   - **Firewall ▸ NAT** – update outbound NAT / port forwards as required.
   - **System ▸ Routing** – adjust gateway groups or policy routing where needed.
   - **Firewall ▸ Rules** – adjust LAN/WAN rules referencing new aliases/NAT objects.

3. After saving and applying each page:
   - Verify there are no validation errors.
   - Keep notes of which sections were modified.

For CLI verification (optional):

```sh
# Show active ruleset
pfctl -sr

# Show NAT rules
pfctl -sn
```

Do not make policy changes directly on the secondary node.

---

## 4. Sync to Secondary and Validate

**Goal:** Ensure the secondary node is in sync and ready to take over if needed.

1. In the **primary** pfSense GUI:
   - Go to **Status ▸ System Logs ▸ System ▸ Gateways / Sync**.
   - Confirm successful XMLRPC sync events after your change.

2. On the **secondary** node (`fw-02`):
   - Log in and spot-check the same areas you changed (aliases, NAT, rules).
   - Confirm the configuration matches the primary.

3. Re-run the basic flow tests from Section 2:
   - LAN → internet.
   - LAN → VPN/DR paths where relevant.
   - Any critical application-specific flows.

Record test results in a simple checklist or short note in `docs/proof/security/pfsense-ha-tests/`.

---

## 5. HA Failover Test (Optional but Recommended)

**Goal:** Validate that flows survive a planned failover.

> Only perform this if you are in a maintenance window and stakeholders agree.

1. On the **primary** pfSense:

   - Navigate to **Status ▸ CARP (Failover)**.
   - Temporarily disable CARP or demote the primary, so the secondary takes over:

     - Option A: toggle **Maintenance Mode**.
     - Option B: run from shell:

       ```sh
       # Example: demote fw-01
       ifconfig carp0 advskew 100
       ```

2. Confirm in the GUI and/or shell that:

   ```sh
   ifconfig | grep -A3 carp
   ```

   shows VIPs moving to `MASTER` on `fw-02`.

3. Repeat the same connectivity tests from Section 2 during and after failover.

4. Once validated, restore normal state:

   - Re-enable CARP on `fw-01` or reset `advskew` to its original value.
   - Confirm VIPs move back if that is the desired steady state.

---

## Verification

Success criteria:

- Primary and secondary pfSense nodes show healthy HA status and synchronized configs.
- All documented critical flows:
  - succeed where allowed by policy; and
  - are blocked where intentionally denied.
- Optional failover test:
  - CARP VIP ownership transfers cleanly between nodes;
  - traffic interruption is minimal and within expectations.

Where possible, capture short evidence (command outputs or screenshots) under:

```text
docs/proof/security/pfsense-ha-tests/
```

---

## Troubleshooting

**Symptom:** Loss of internet access from one or more VLANs  
- Check gateway and gateway-group status under **Status ▸ Gateways**.  
- Verify outbound NAT rules on **Firewall ▸ NAT ▸ Outbound**.  
- Use **Diagnostics ▸ States** to see if sessions are pinned to an unexpected gateway.

**Symptom:** Secondary node not syncing configuration  
- Check **System ▸ High Availability Sync** settings.  
- Verify firewall rules allow XMLRPC between nodes on the sync interface.  
- Review logs under **Status ▸ System Logs ▸ System ▸ Gateways / Sync**.

**Symptom:** CARP VIP flapping  
- Confirm both HA nodes have synchronized time (NTP).  
- Check for interface errors or flapping on the CARP interfaces.  
- Review `advskew` and `vhid` settings for conflicting configurations.

If changes cannot be stabilised quickly, execute the rollback procedure.

---

## Rollback

1. **Restore previous configuration**

   - On the primary pfSense node, go to **Diagnostics ▸ Backup & Restore**.
   - Upload the previously saved XML configuration.
   - Confirm and apply the restore.

2. **Reboot or re-sync as required**

   - Allow the node to reboot if prompted.
   - Confirm HA status returns to normal (CARP `MASTER/BACKUP` as expected).

3. **Re-validate flows**

   - Repeat baseline tests from Section 2.
   - Confirm behaviour matches pre-change state.

Document the rollback and reasons in your change tracking system.

---

## References

- [ADR-0301 – pfSense as Firewall for Flow Control](../../adr/ADR-0301-pfsense-firewall-flow-control.md)  
- [Evidence](../../proof/security/pfsense-ha-tests/)

---

**maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

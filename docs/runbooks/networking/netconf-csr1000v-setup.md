---
title: "NETCONF Setup on CSR1000v"
category: "networking"
summary: "Enable and validate NETCONF over SSH on Cisco CSR1000v for use with Nornir-based automation."
severity: "P3"

topic: "netconf-csr1000v-setup"

draft: false
tags: ["networking", "netconf", "csr1000v", "automation"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# NETCONF Setup on CSR1000v

**Purpose:** Enable NETCONF over SSH on Cisco CSR1000v and verify it is reachable from the automation host (Nornir / Jenkins / Ansible controller).  
**Owner:** Network / Platform team  
**Trigger:** New CSR1000v deployed, image upgraded, or NETCONF connectivity tests failing.  
**Impact:** Low. Changes are limited to management plane, but misconfiguration can impact SSH access.  
**Severity:** P3 (important platform prerequisite, not a live outage).  

---

## When to use this runbook

Use this runbook when:

- Bringing a new CSR1000v under automated management for the first time.
- Re-enabling NETCONF after an image upgrade or configuration reset.
- Validating that automation hosts can reach NETCONF before running pipeline jobs.
- Investigating NETCONF job failures where SSH access still works.

If you are designing automation patterns or learning NETCONF/Nornir concepts, see the HOWTO instead:

- HOWTO: Use Nornir to Collect NETCONF Evidence (planned).

---

## Preconditions and safety checks

Before making changes:

1. **Access requirements**
   - CSR1000v reachable via SSH (management IP or console access available).
   - Admin-level credentials for CSR1000v (privilege 15).
   - Automation host (Nornir/Jenkins controller) can reach the CSR over the management network.

2. **Configuration safety**
   - Take a configuration backup:
     ```bash
     # On CSR
     show run | redirect bootflash:pre-netconf-config.txt
     ```
   - Confirm free CPU/memory (high load can make NETCONF slow or unstable):
     ```bash
     show processes cpu sorted | exclude 0.00%
     show platform resources
     ```

3. **Network and security**
   - Decide which hosts/subnets are allowed to use NETCONF (for ACLs).
   - Ensure firewall rules allow TCP/830 from the automation host(s) to the CSR management IP.

If any of these fail, fix them first or escalate before proceeding.

---

## Steps

### 1. Confirm current NETCONF and SSH state

**Action:** Check if NETCONF and SSH are already enabled and functioning.

On CSR1000v:

```bash
show running-config | include netconf
show ip ssh
show platform software yang-management process
```

**Expected (baseline):**

- No `netconf-yang` configuration (for new routers), or NETCONF is enabled but untested.
- SSH v2 enabled on the device.

Capture this as pre-change evidence:

```bash
show running-config | redirect bootflash:pre-netconf-show-run.txt
```

---

### 2. Enable NETCONF over SSH

**Action:** Turn on NETCONF with YANG support and ensure SSH is correctly configured.

On CSR1000v:

```bash
configure terminal
  netconf-yang
  ssh server v2
  ssh server netconf port 830
  line vty 0 4
    transport input ssh
  end
write memory
```

**Notes:**

- `netconf-yang` starts the NETCONF server and YANG subsystem.
- `ssh server netconf port 830` exposes NETCONF over SSH (standard port).
- `transport input ssh` ensures VTY lines only allow SSH (no telnet).

Verification:

```bash
show running-config | section netconf
show ip ssh
```

---

### 3. Restrict NETCONF access with an ACL (optional but recommended)

**Action:** Limit which IPs can reach NETCONF over SSH.

Example (replace addresses with your automation host subnet):

```bash
configure terminal
  ip access-list standard NETCONF-MGMT
    permit 10.10.0.11      ! Ansible / Nornir controller
    permit 10.10.0.12      ! Jenkins controller
    deny   any log
  !
  ip ssh source-interface GigabitEthernet1
  ip ssh access-group NETCONF-MGMT
end
write memory
```

**Checks:**

```bash
show access-lists NETCONF-MGMT
show ip ssh
```

Update perimeter firewall rules so that **only** approved hosts can reach TCP/830 on the CSR management IP.

---

### 4. Test NETCONF connectivity from automation host

**Action:** Confirm NETCONF answers correctly from the controller host.

From the automation host (Nornir/Jenkins controller):

1. Basic TCP connectivity test:
   ```bash
   nc -vz <CSR_MGMT_IP> 830
   ```

   Expected: `succeeded` (or equivalent).

2. NETCONF hello test using OpenSSH:
   ```bash
   ssh -s -p 830 <username>@<CSR_MGMT_IP> netconf
   ```

   Expected:

   - Prompt for password or key-based auth.
   - Device prints a `<hello>` XML capability banner.
   - Session can be closed with `]]>]]>` or CTRL+C.

Capture output for evidence:

```bash
ssh -s -p 830 <username>@<CSR_MGMT_IP> netconf > netconf-hello.txt
```

---

### 5. Validate Nornir integration

**Action:** Run a small Nornir job to confirm end-to-end automation path works.

Example Nornir inventory entry (`inventory/hosts.yaml`):

```yaml
csr1:
  hostname: <CSR_MGMT_IP>
  platform: cisco_xe
  username: netops
  password: "{{ vault_csr1_password }}"
  connection_options:
    netconf:
      port: 830
```

On the automation host, run a simple play:

```bash
python -m hybridops.tools.nornir.netconf_discover --target csr1
```

(Expected script name will match your repo; adjust as required.)

**Expected:**

- Nornir connects via NETCONF and retrieves capabilities or running config.
- Output is saved under `docs/proof/networking/netconf-csr1000v/` with a timestamp and correlation ID (if implemented).

If this step fails but SSH tests succeed, the issue is likely in Nornir configuration rather than NETCONF itself.

---

### 6. Capture and store evidence

**Action:** Store proof that NETCONF was enabled and tested.

Minimum evidence set:

```bash
show running-config | section netconf
show ip ssh
show platform software yang-management process
```

Save these into your evidence path, for example:

```bash
# On CSR
show running-config | section netconf > bootflash:netconf-section.txt

# On automation host
mkdir -p docs/proof/networking/netconf-csr1000v/$(date +%Y%m%dT%H%M%SZ)
mv netconf-hello.txt docs/proof/networking/netconf-csr1000v/$(date +%Y%m%dT%H%M%SZ)/
```

Update any internal tracking (ticket, ADR evidence note) if required.

---

## Verification

Runbook is successful when:

- `netconf-yang` is present in the CSR configuration.
- TCP port 830 is reachable **only** from approved automation hosts.
- `ssh -s -p 830 <user>@<CSR_MGMT_IP> netconf` returns a valid NETCONF `<hello>` banner.
- A simple Nornir NETCONF task against the CSR completes without error.
- Evidence files are stored under `docs/proof/networking/netconf-csr1000v/`.

Quick verification commands:

```bash
# On CSR
show running-config | include netconf
show platform software yang-management process

# From automation host
nc -vz <CSR_MGMT_IP> 830
ssh -s -p 830 <user>@<CSR_MGMT_IP> netconf
```

---

## Rollback

If NETCONF must be disabled or configuration caused issues:

1. **Remove NETCONF and SSH constraints on CSR**

   ```bash
   configure terminal
     no netconf-yang
     no ssh server netconf port 830
     no ip ssh access-group NETCONF-MGMT
     no ip access-list standard NETCONF-MGMT
   end
   write memory
   ```

2. **Restore configuration from backup (if needed)**

   ```bash
   configure replace bootflash:pre-netconf-config.txt force
   ```

3. **Re-verify SSH access**

   ```bash
   show ip ssh
   ```

4. **Update records**

   - Mark NETCONF as disabled in any internal inventories.
   - Attach rollback notes to the relevant ticket/change record.

---

## References

- [ADR-0602 – NETCONF and Nornir Automation for CSR1000v](../../adr/ADR-0602-netconf-nornir-csr1000v.md)
- [HOWTO – Use Nornir to Collect NETCONF Evidence](../../howtos/HOWTO_nornir-netconf-evidence.md)
- [Evidence: NETCONF State & Config Snapshots](../../proof/networking/netconf-csr1000v/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

---
title: "NCC Hub Setup (Azure Primary, GCP Peer)"
category: "networking"
summary: "Bring up Azure as the primary hybrid hub with NCC connectivity to on‑prem and GCP, with repeatable checks and rollback."
severity: "P2"

topic: "ncc-hub-setup"

draft: false
is_template_doc: false
tags: ["networking", "ncc", "azure", "gcp", "hybrid"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# NCC Hub Setup (Azure Primary, GCP Peer)

**Purpose:** Establish Azure as the primary hybrid hub, integrated with Google NCC, without breaking existing on‑prem connectivity.  
**Owner:** Platform / Networking  
**Trigger:** New hub deployment, major hub refresh, or NCC topology refactor.  
**Impact:** Control‑plane changes to cloud VPN and routing; brief dataplane interruption is possible during cutover.  
**Severity:** P2 (high priority, but planned and controlled).  
**Pre‑reqs:** Azure subscription, GCP project with NCC enabled, on‑prem edge (pfSense/CSR/VyOS) reachable and configurable, non‑overlapping CIDRs.  
**Rollback strategy:** Revert default routes and BGP/next‑hop back to the previous hub configuration; disable new tunnels and NCC attachments.

---

## 1. Context

This runbook executes the design captured in:

- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../adr/ADR-0107-vyos-edge-router.md)
- [ADR-0109 – NCC Primary Hub with Azure Spoke Connectivity](../adr/ADR-0109-ncc-primary-hub-azure-spoke.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](../adr/ADR-0201-eve-ng-network-lab-architecture.md)

High‑level goals:

- Azure VNet hub acts as **primary WAN/cloud hub**.  
- On‑prem pfSense / CSR / VyOS connect to Azure via VPN with BGP.  
- GCP NCC peers with Azure hub to provide **cross‑cloud reachability and visibility**.  

Use this runbook when you need to **build or rebuild** the hub. For deep design rationale or lab‑level experimentation, refer to the ADRs and HOWTOs.

---

## 2. Preconditions and Safety Checks

Before you touch anything:

1. **Confirm change window and blast radius**  
   - Change approved and scheduled.  
   - No critical DR test or production cutover in progress that depends on the existing hub.

2. **Validate addressing and CIDRs**  
   - Azure hub VNet CIDR does *not* overlap with:  
     - On‑prem VLAN ranges (ADR-0101), and  
     - GCP VPC CIDRs.  
   - Document the chosen Azure hub VNet CIDR in `docs/proof/networking/ncc/addressing.md`.

3. **Check cloud and on‑prem access**  
   - Azure: `az account show` succeeds with the right subscription.  
   - GCP: `gcloud config list` shows correct project and region.  
   - On‑prem: SSH/console access to pfSense / CSR / VyOS edge devices.

4. **Snapshot current state**  
   - Export current VPN and routing config (both clouds and on‑prem).  
   - Store under `docs/proof/networking/ncc/pre-change/<timestamp>/`.

If any of these checks fail, **stop** and resolve before proceeding.

---

## 3. Steps

### Step 1 – Prepare / Validate Azure Hub VNet and VPN Gateway

**Action:** Ensure an Azure hub VNet and VPN Gateway exist and match the ADR design.

- Create or validate:  
  - Hub VNet (name: `hub-vnet-<region>`).  
  - Gateway subnet (e.g. `GatewaySubnet` /27).  
  - VPN Gateway (route‑based, BGP enabled).  
- Confirm:  
  - ASN matches design (e.g. `65010`).  
  - Public IPs allocated and documented.  

**Expected result:**  
Azure hub VNet and VPN gateway are provisioned, healthy, and aligned to ADR‑0109.

**Evidence:**  
Export `az network vnet show` and `az network vnet-gateway show` into  
`docs/proof/networking/ncc/azure-hub/<timestamp>/`.

---

### Step 2 – Create or Validate Azure Local Network Gateways for On‑Prem

**Action:** Model on‑prem edges in Azure via Local Network Gateways (LNGs).

- For each on‑prem edge (pfSense / CSR / VyOS):  
  - Create or update an LNG with:  
    - On‑prem public IP (per ISP if dual uplink).  
    - On‑prem internal CIDRs (VLAN ranges, DR ranges).  
- Ensure LNG names clearly encode site and device (e.g. `lng-onprem-primary-csr`).

**Expected result:**  
All on‑prem edges are represented as LNGs with accurate public IPs and prefixes.

**Evidence:**  
Save `az network local-gateway show` output per LNG under  
`docs/proof/networking/ncc/azure-hub/local-gateways/`.

---

### Step 3 – Build Azure Site-to-Site VPN Connections

**Action:** Establish S2S VPN connections between the Azure hub gateway and each LNG.

- For each on‑prem site:  
  - Create or validate a `connection` object:  
    - `connectionType = IPsec`.  
    - Shared key documented securely (AKV / secrets management).  
    - BGP enabled, with correct peer ASN and BGP IPs.  
- Apply / update via Terraform where possible; avoid ad‑hoc portal edits.

**Expected result:**  
All VPN connections show **Connected** in Azure and pass basic tunnel health checks.

**Evidence:**  
Capture:  
- Azure Portal connection health screenshot, and  
- `az network vpn-connection show` JSON  
into `docs/proof/networking/ncc/azure-hub/vpn-connections/`.

---

### Step 4 – Configure On‑Prem Edge Devices (pfSense/CSR/VyOS)

**Action:** Align on‑prem edge config with the new Azure hub.

- pfSense:  
  - Define IPsec tunnels towards Azure hub’s public IP(s).  
  - Bind tunnels to correct WAN interfaces (per ADR-0106).  
  - Configure phase 1/2 params to match Azure.  

- CSR / VyOS:  
  - Configure IPsec profiles/interfaces and crypto maps (CSR) or VTI interfaces (VyOS).  
  - Enable BGP peering with Azure (hub ASN vs on‑prem ASN).  

**Expected result:**  
Tunnels come up from the on‑prem side; BGP sessions with Azure are **Established**.

**Evidence:**  
- pfSense: IPsec status and BGP route table screenshots.  
- CSR / VyOS: `show crypto ikev2 sa`, `show ip bgp summary`, `show vpn ipsec sa`.  
Save under `docs/proof/networking/ncc/onprem/<device>/<timestamp>/`.

---

### Step 5 – Integrate Azure Hub with GCP NCC

**Action:** Attach Azure hub into the NCC mesh and validate topology.

- In GCP:  
  - Confirm NCC hub is created in the target project.  
  - Create NCC spoke or attachment representing the Azure hub.  
  - Ensure connectivity via existing VPN / interconnect between Azure and GCP.  
- Tie the Azure hub VNet, on‑prem ranges, and GCP VPCs into the NCC policy routing domain per ADR‑0109.

**Expected result:**  
NCC topology view shows Azure hub, on‑prem, and GCP spokes in a consistent, healthy state.

**Evidence:**  
- NCC topology screenshots.  
- `gcloud network-connectivity` CLI outputs.  
Store under `docs/proof/networking/ncc/topology/<timestamp>/`.

---

### Step 6 – Validate End-to-End Connectivity and Routing

**Action:** Confirm the full path works from on‑prem → Azure → GCP and back.

Minimum checks:

- From on‑prem host:  
  - Ping an Azure VM IP and a GCP VM IP.  
  - `traceroute` shows expected path via Azure hub.  

- From Azure VM:  
  - Ping on‑prem and GCP VM addresses.  
  - Confirm routes via hub’s UDR / BGP tables.  

- From GCP VM:  
  - Ping Azure and on‑prem addresses.  

**Expected result:**  
End‑to‑end connectivity succeeds for allowed prefixes; disallowed prefixes remain blocked per security policy.

**Evidence:**  
Save ping/traceroute output into `docs/proof/networking/ncc/validation/<timestamp>/`.

---

### Step 7 – Update Monitoring and Alerts

**Action:** Ensure observability reflects the new hub design.

- Confirm Prometheus targets for:  
  - Azure VPN gateway,  
  - On‑prem pfSense / CSR / VyOS,  
  - GCP NCC metrics (if exported).  
- Ensure Alertmanager rules cover:  
  - Tunnel down,  
  - BGP session down,  
  - SLA threshold breaches (latency / loss).  

**Expected result:**  
Monitoring dashboards and alerts reflect the current topology; no references to legacy hub components remain.

**Evidence:**  
- Screenshot of updated Grafana panel.  
- Exported alert ruleset diff in `docs/proof/networking/ncc/monitoring/`.

---

### Step 8 – Document, Close, and (If Needed) Roll Back

**Action:** Finalise documentation and be ready to roll back if issues emerge later.

- Update:  
  - `docs/prerequisites/network-architecture.md` hub section.  
  - ADR‑0109 status if anything materially changed.  
- Log the change in your change‑log / evidence map.  

If serious issues appear after deployment:

- Reset default routes / BGP preferences to send traffic back to the previous hub (or single‑ISP path).  
- Disable NCC attachments pointing at the Azure hub until configuration is corrected.  
- Re‑run validation once fixed.

**Expected result:**  
Change is fully documented; clear path exists to roll back if required.

---

## 4. Verification Checklist (Quick View)

Use this as a fast end‑of‑change sanity list:

- [ ] Azure hub VNet + VPN Gateway deployed and healthy.  
- [ ] LNGs correctly represent all on‑prem edges and prefixes.  
- [ ] S2S VPN connections **Connected** in Azure.  
- [ ] On‑prem tunnels up; BGP **Established** with Azure.  
- [ ] NCC topology displays Azure hub and all spokes.  
- [ ] On‑prem ↔ Azure ↔ GCP connectivity validated.  
- [ ] Monitoring targets and alerts updated.  
- [ ] Evidence stored under `docs/proof/networking/ncc/`.  

---

## 5. References

- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../adr/ADR-0107-vyos-edge-router.md)
- [ADR-0109 – NCC Primary Hub with Azure Spoke Connectivity](../adr/ADR-0109-ncc-primary-hub-azure-spoke.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](../adr/ADR-0201-eve-ng-network-lab-architecture.md)
- [Evidence](docs/proof/networking/ncc/)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

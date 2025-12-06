---
title: "Migrate NetBox from Docker on ctrl-01 to RKE2 Using PostgreSQL LXC"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Move NetBox from a Docker deployment on the control node (ctrl-01) to an RKE2-based deployment while keeping PostgreSQL in the db-01 LXC as the shared system of record."
difficulty: "Intermediate"

topic: "netbox-migration-docker-to-rke2"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["netbox", "rke2", "postgresql", "migration", "source-of-truth"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Migrate NetBox from Docker on ctrl-01 to RKE2 Using PostgreSQL LXC

This HOWTO describes how to **migrate NetBox** from a **Docker deployment on ctrl-01** to an **RKE2-based deployment**, while keeping PostgreSQL in the **db-01 LXC** as the shared system of record.

It builds on:

- [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](./HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)  
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  

The goal is to:

- Move NetBox’s **compute** from Docker on ctrl-01 → RKE2.
- Keep the **database** on db-01 (PostgreSQL LXC) with continuity.
- Perform a controlled **cutover window** with clear rollback.

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Prepare an RKE2-based NetBox deployment that reuses the existing PostgreSQL database on db-01.
- Plan and execute a short migration window from Docker → RKE2.
- Validate NetBox behaviour after cutover.
- Capture migration evidence under [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/).

---

## 2. Prerequisites

### 2.1 Platform state

You should have:

1. **Existing NetBox on ctrl-01 (Docker)**

   - Running NetBox container on `ctrl-01` with:
     - `NETBOX_DB_*` pointing at db-01.
   - Access to logs and configuration for this instance.

2. **RKE2 cluster running**

   - RKE2 cluster available and reachable with `kubectl`.
   - Namespace plan ready (for example, `network-platform`).

3. **PostgreSQL LXC (db-01)**

   - PostgreSQL LXC (`db-01`) running on Proxmox, as per ADR-0013.
   - NetBox database (`netbox`) and user (`netbox_user`) already in place.
   - Regular backups configured.

4. **RKE2 NetBox deployment defined**

   - You have followed or are ready to follow:  
     [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](./HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)  
   - RKE2 manifests/Helm values prepared to point at the same db-01 instance.

### 2.2 Access and tooling

- SSH access to `ctrl-01` and Proxmox hosts.
- `kubectl` access to RKE2.
- Ability to reach NetBox UI endpoints from a browser.

### 2.3 Evidence location

Use:

```bash
mkdir -p docs/proof/apps/netbox/migration-docker-to-rke2-<date>/
```

Replace `<date>` with a timestamp (for example, `2025-12-02T200000Z`).

---

## 3. Migration strategy

The migration strategy is:

1. Prepare RKE2 NetBox deployment pointing to db-01.  
2. Choose a short migration window and notify stakeholders.  
3. Put Docker NetBox in maintenance / drain mode.  
4. Deploy NetBox on RKE2 and validate.  
5. Switch users/DNS from Docker → RKE2.  
6. Monitor, then optionally decommission Docker instance.

Because **PostgreSQL stays on db-01**, the migration focuses on the **application layer**, not data movement.

---

## 4. Phase 1 – Prepare RKE2 NetBox deployment

1. **Ensure db-01 state and connectivity**

   - From `ctrl-01` or an RKE2 node:

     ```bash
     psql -h <db01-hostname> -U netbox_user -d netbox -c "SELECT now();"
     ```

   - Save the output to:

     ```bash
     psql -h <db01-hostname> -U netbox_user -d netbox -c "SELECT now();"        > docs/proof/apps/netbox/migration-docker-to-rke2-<date>/db-connectivity-pre.txt
     ```

2. **Prepare RKE2 manifests/Helm values**

   - Follow the deployment HOWTO:  
     [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](./HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)  
   - Ensure:
     - `DB_HOST` points to db-01.
     - Credentials match the existing NetBox DB user.
     - Namespace is chosen (for example, `network-platform`).
     - Ingress/service is configured for the target URL.

3. **Dry-run manifests (if supported)**

   - For Helm:

     ```bash
     helm template netbox ./charts/netbox -f values-netbox-rke2.yaml > /tmp/netbox-rendered.yaml
     ```

   - For raw manifests, run `kubectl apply --dry-run=server`.

   - Check for obvious errors.

---

## 5. Phase 2 – Plan and announce migration window

1. **Confirm usage pattern**

   - Identify if NetBox is:
     - Primarily used by you (lab/portfolio) or
     - Shared with others (wider team).

2. **Choose a migration window**

   - Select a low-usage period.
   - Decide whether to enforce read-only/maintenance mode or accept a brief full outage.

3. **Announce the change**

   - For shared environments:
     - Announce that NetBox will be briefly unavailable or degraded while migrating to RKE2.
   - For solo/lab use:
     - Log the window in a short text file under the migration proof folder.

---

## 6. Phase 3 – Put Docker NetBox into maintenance mode

1. **Identify the running container on ctrl-01**

   ```bash
   ssh <user>@ctrl-01
   docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'
   ```

2. **Optional: enable maintenance banner in NetBox**

   - If configured, toggle a maintenance banner or message in NetBox (config or UI) to signal impending downtime.

3. **Capture baseline**

   - Take a quick screenshot of the current NetBox UI and store under:

     - `docs/proof/apps/netbox/migration-docker-to-rke2-<date>/before-ui.png`

4. **Stop Docker NetBox**

   At the start of the migration window:

   ```bash
   docker stop <netbox-container-name>
   ```

   - Optionally also stop any associated worker containers (if used).
   - Record the exact time in the migration notes.

> After this step, NetBox will be unavailable until the RKE2 instance is up.

---

## 7. Phase 4 – Deploy NetBox on RKE2

1. **Deploy on RKE2**

   - Using Helm example:

     ```bash
     kubectl create ns network-platform || true

     helm upgrade --install netbox ./charts/netbox        -n network-platform        -f values-netbox-rke2.yaml
     ```

   - Or apply K8s manifests.

2. **Wait for pods to become Ready**

   ```bash
   kubectl get pods -n network-platform
   ```

   - Save output:

     ```bash
     kubectl get pods -n network-platform        > docs/proof/apps/netbox/migration-docker-to-rke2-<date>/kubectl-get-pods-netbox.txt
     ```

3. **Check logs for DB connectivity**

   ```bash
   kubectl logs deploy/netbox -n network-platform | tail -n 50
   ```

   - Confirm:
     - No DB authentication/connection errors.
     - NetBox startup completes successfully.

4. **Port-forward for validation (optional)**

   ```bash
   kubectl port-forward -n network-platform deploy/netbox 8001:8001
   ```

   - Open `http://localhost:8001/` and check UI loads.

---

## 8. Phase 5 – Cut over access to RKE2 NetBox

1. **Confirm application health**

   - Log in to the RKE2 NetBox instance.
   - Verify:
     - You can see existing sites/devices.
     - Data matches what you expect from the Docker-based instance.

2. **Update DNS or access URL**

   Depending on how users access NetBox today:

   - If they use a hostname (for example, `netbox.internal.local`) pointing at ctrl-01:
     - Update DNS to point at the RKE2 ingress/entry point.
   - If there is no DNS and you use a direct URL:
     - Update documentation and bookmarks to use the RKE2 address.

3. **Re-test from user perspective**

   - From a normal client machine:
     - Open the NetBox URL.
     - Confirm login and basic navigation work.

4. **Record cutover time**

   - Note the exact time you updated DNS/URL in your migration notes.
   - Save a screenshot of the RKE2 NetBox UI to the proof folder.

---

## 9. Phase 6 – Post-migration checks and rollback plan

1. **Run basic functional tests**

   - Create and delete a **test object** (for example, a dummy site or device) to confirm write operations.
   - Check that data appears consistent and there are no obvious performance issues.

2. **Monitor logs**

   - Watch NetBox logs and PostgreSQL logs on db-01 for any errors.

3. **Rollback option (if needed)**

   If serious issues appear:

   - Stop or scale down the RKE2 NetBox deployment.
   - Restart the Docker container on ctrl-01:

     ```bash
     docker start <netbox-container-name>
     ```

   - Revert DNS/URL to ctrl-01 NetBox.
   - Document the reason for rollback in the migration notes.

4. **Decommission Docker NetBox (once stable)**

   After a stabilisation period:

   - Remove the Docker NetBox container and, if appropriate, related images.
   - Keep configuration backups for historical reference.
   - Ensure all future operations/automation target the RKE2 NetBox instance.

---

## 10. Evidence and documentation

Before closing the migration:

1. Ensure `docs/proof/apps/netbox/migration-docker-to-rke2-<date>/` contains:

   - Pre- and post- `kubectl get pods` output.
   - DB connectivity checks.
   - Screenshots of old (Docker) and new (RKE2) UIs.
   - Notes on cutover times and any issues encountered.

2. Update:

   - Evidence 3 (if needed) with a brief mention of the migration.
   - Any internal documentation pointing at the old Docker deployment.

3. If this migration will be shown in a portfolio or video:

   - Capture short terminal and UI clips showing:
     - Docker NetBox running.
     - Stopping Docker & deploying to RKE2.
     - NetBox running successfully on RKE2.

---

## 11. Validation checklist

- [ ] RKE2 deployment of NetBox is configured to use PostgreSQL on db-01.  
- [ ] Docker-based NetBox on ctrl-01 was cleanly stopped at the start of the window.  
- [ ] NetBox pods on RKE2 are `Running` and logs show successful startup.  
- [ ] Users can reach NetBox via the new (RKE2) endpoint/DNS entry.  
- [ ] Basic operations (viewing/creating objects) work as expected.  
- [ ] Evidence artefacts stored under [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/).  
- [ ] Rollback plan was documented, and either not needed or executed successfully.  

---

## References

- [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](./HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)  
- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

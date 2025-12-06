---
title: "Deploy NetBox on RKE2 Using PostgreSQL LXC"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Deploy NetBox into the RKE2 cluster while using PostgreSQL running in an on-prem LXC as the system of record, with proof artefacts."
difficulty: "Intermediate"

topic: "netbox-on-rke2-with-postgresql-lxc"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["netbox", "rke2", "postgresql", "source-of-truth", "kubernetes"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Deploy NetBox on RKE2 Using PostgreSQL LXC

This HOWTO shows how to deploy **NetBox** as a workload on the **RKE2 cluster** while keeping its database on the **PostgreSQL LXC (db-01)**, in line with the principle that Kubernetes is **stateless compute** and databases live outside the cluster.

It aligns with:

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- Evidence 3, which covers NetBox as Source of Truth and its automation story.

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Deploy NetBox into an RKE2 namespace using Kubernetes manifests or Helm.
- Configure NetBox to use the existing PostgreSQL LXC as its database.
- Validate NetBox health and basic functionality.
- Capture proof artefacts under [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/).

---

## 2. Prerequisites

### 2.1 Platform dependencies

You should have:

- A running RKE2 cluster (see [HOWTO – Bootstrap an RKE2 Cluster from Proxmox Templates](../howtos/HOWTO_rke2_bootstrap_from_proxmox_templates.md)).
- The PostgreSQL LXC (`db-01`) provisioned and accessible from the RKE2 worker nodes, with:
  - NetBox database and user created.
  - Network connectivity and firewall rules allowing connections from RKE2 nodes.

### 2.2 NetBox artefacts

- NetBox container image reference (registry and tag).
- Kubernetes manifests or a Helm chart for NetBox that support:
  - External database configuration.
  - Configuration via environment variables or config files.

### 2.3 Access and tools

- `kubectl` configured for the RKE2 cluster.
- Access to the Git repo containing NetBox manifests/chart definitions.
- Ability to reach the PostgreSQL LXC from the control node for connectivity tests.

### 2.4 Related docs

- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  
- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)  

---

## 3. Prepare NetBox database on PostgreSQL LXC

1. SSH into the PostgreSQL LXC (`db-01`) or use your preferred admin method.
2. Connect to PostgreSQL:

   ```bash
   psql -U postgres
   ```

3. Create the NetBox database and user (if not already created):

   ```sql
   CREATE DATABASE netbox;
   CREATE USER netbox_user WITH PASSWORD 'CHANGE_ME_STRONG_PASSWORD';
   GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox_user;
   ```

4. Confirm connectivity from an RKE2 node (for example, using `psql` or `nc` from a worker node) to ensure network and firewall are correctly configured.

Record any commands or screenshots in:

- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)

---

## 4. Configure NetBox manifests or Helm values

You may be using:

- A Helm chart for NetBox, or
- Raw Kubernetes manifests.

In both cases, the core settings include:

- Database hostname/IP = address of PostgreSQL LXC (`db-01`).
- Database name, username and password.
- Any TLS or connection parameters appropriate for your environment.

Example Helm values snippet (illustrative):

```yaml
netbox:
  config:
    database:
      host: "db-01.internal.local"
      name: "netbox"
      user: "netbox_user"
      passwordSecretName: "netbox-db-credentials"
```

Create the secret for the database password:

```bash
kubectl create secret generic netbox-db-credentials   -n network-platform   --from-literal=DB_PASSWORD='CHANGE_ME_STRONG_PASSWORD'
```

Adjust namespace, secret name and key names according to your chart/manifests.

---

## 5. Deploy NetBox to RKE2

1. Choose or create a namespace (for example, `network-platform`):

   ```bash
   kubectl create ns network-platform
   ```

   (Skip if it already exists.)

2. Apply Helm chart or manifests:

   - Helm example:

     ```bash
     helm upgrade --install netbox ./charts/netbox        -n network-platform        -f values-netbox-rke2.yaml
     ```

   - Manifest example:

     ```bash
     kubectl apply -n network-platform -f k8s/netbox/
     ```

3. Wait for pods to become `Running`:

   ```bash
   kubectl get pods -n network-platform
   ```

4. If using an ingress, confirm the associated service and ingress objects exist:

   ```bash
   kubectl get svc -n network-platform
   kubectl get ingress -n network-platform
   ```

---

## 6. Validate NetBox functionality

1. **Check pod logs**

   ```bash
   kubectl logs deploy/netbox -n network-platform
   ```

   - Confirm that NetBox started without database connection errors.

2. **Port-forward for local testing**

   ```bash
   kubectl port-forward -n network-platform deploy/netbox 8001:8001
   ```

   Then open `http://localhost:8001/` in your browser.

3. **Application-level checks**

   - Log in to the NetBox UI.
   - Confirm you can:
     - View existing objects (for example, sites, devices) if seed data exists.
     - Create a small test object (then delete it if this is a shared environment).

4. **Record evidence**

   - Copy relevant logs and screenshots to:

     - [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)

   - For example:
     - `kubectl-get-pods-netbox-<date>.txt`
     - `netbox-ui-screenshot-<date>.png`

---

## 7. Wire NetBox into the wider platform story

To make NetBox part of the full Evidence 3 and 4 narrative:

1. **Ensure automation integrations are enabled**

   - For example, Nornir/Ansible jobs that:
     - Read from NetBox as Source of Truth.
     - Operate on lab or virtual devices.

2. **Ensure observability**

   - If NetBox exposes metrics or logs, ensure they feed into your Prometheus/Grafana stack.
   - Confirm that outages in NetBox would be visible during DR or platform incidents.

3. **Tag NetBox for DR and cost**

   - Label the namespace and deployments to reflect:
     - Environment (`env=onprem`).
     - Role (`role=source-of-truth`).
   - This helps tie NetBox into DR workloads and cost modelling (ADR-0701, ADR-0801).

---

## 8. Validation checklist

- [ ] PostgreSQL LXC (`db-01`) hosts the `netbox` database and user with appropriate privileges.  
- [ ] RKE2 cluster is running and reachable with `kubectl`.  
- [ ] NetBox pods in the chosen namespace are `Running` and healthy.  
- [ ] NetBox can connect to the PostgreSQL LXC without authentication or connectivity errors.  
- [ ] Basic NetBox workflows (viewing/creating objects) succeed.  
- [ ] Evidence artefacts exist under [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/).  

---

## References

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

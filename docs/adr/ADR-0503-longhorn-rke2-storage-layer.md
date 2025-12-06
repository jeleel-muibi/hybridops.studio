---
id: ADR-0503
title: "Use Longhorn as RKE2 Storage Layer for Stateful Kubernetes Workloads"
status: Accepted
date: 2025-12-02
category: "05-data-storage"    # One of:
                              # "00-governance"
                              # "01-networking"
                              # "02-platform"
                              # "03-security"
                              # "04-observability"
                              # "05-data-storage"
                              # "06-cicd-automation"
                              # "07-disaster-recovery"
                              # "08-cost-optimisation"
                              # "09-compliance"

domains: ["platform", "data"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []
  related_docs:
    - "./ADR-0013_postgresql-as-lxc.md"
    - "./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md"
---

_Status: Accepted (2025-12-02)_

---

# Use Longhorn as RKE2 Storage Layer for Stateful Kubernetes Workloads

## 1. Context

HybridOps.Studio separates **compute** and **state**:

- Compute:
  - RKE2 clusters running on Proxmox.  
- State:
  - Critical relational data (for example, NetBox) on PostgreSQL in LXC (db-01) as per ADR-0013.  

For Kubernetes-native workloads that require persistent volumes:

- Local hostPath volumes are brittle and tied to single nodes.  
- NFS is simple but introduces a separate SPOF and operational overhead.  
- Ceph and similar systems are powerful but heavier than needed for a homelab-scale environment.

We need:

- A **simple, K8s-native, replicated block storage** solution for RKE2.  
- Good observability and straightforward recovery procedures.  
- A pattern that can be explained in consulting and Academy material as a pragmatic choice for labs and small clusters.

## 2. Decision

HybridOps.Studio adopts **Longhorn** as the primary **RKE2 storage layer** for stateful Kubernetes workloads that do not require a dedicated external database.

- RKE2 clusters are configured with Longhorn as the default StorageClass for PVCs where appropriate.  
- Critical system-of-record data (for example, NetBox DB) remains on PostgreSQL LXC (db-01).  
- Non-critical or self-contained workloads (for example, demo apps, ephemeral services) may use Longhorn-backed PVCs.

## 3. Rationale

### 3.1 Why Longhorn?

- Purpose-built for Kubernetes as a distributed block storage system.  
- Easy to operate in small clusters:
  - UI and metrics built in.  
  - Does not require a separate Ceph cluster.  
- Supports:
  - Volume replication across nodes.  
  - Snapshots and backup to external endpoints (for example, object storage).

This makes it a good balance between:

- Functional robustness, and  
- Operational simplicity in a homelab / small-cluster scenario.

### 3.2 Why not “everything in Longhorn”?

HybridOps.Studio keeps **relational state** (for example, NetBox) on PostgreSQL in LXC because:

- It simplifies backup and DR procedures for system-of-record data (ADR-0013).  
- It allows RKE2 and Jenkins to remain largely stateless for DR and bursting stories.  
- It demonstrates a realistic split between:
  - Cluster-local storage for workloads, and  
  - Externally managed databases for critical state.

## 4. Consequences

### 4.1 Positive

- **Better storage for stateful workloads on RKE2**  
  - Replicated volumes, simple snapshot/backup options.

- **Clear separation of storage strategies**  
  - PostgreSQL LXC for system-of-record data.  
  - Longhorn for Kubernetes-native state that can be recreated or restored independently.

- **Teaching value**  
  - Shows how labs and small teams can adopt a more robust storage layer without implementing Ceph.

### 4.2 Negative / trade-offs

- **Additional component to operate**  
  - Longhorn must be upgraded and monitored.  
  - Node disk usage and replication factors must be managed.

- **Not a substitute for full-scale enterprise storage**  
  - For very large clusters or mission-critical workloads, clients may still need more advanced or managed storage solutions.

## 5. Implementation

### 5.1 Cluster configuration

- Longhorn is installed into the RKE2 cluster using the recommended method for the distribution.  
- A Longhorn-backed StorageClass (for example, `longhorn`) is created and may be set as default where appropriate.

### 5.2 Workload guidance

- Sample/demo apps use Longhorn-backed PVCs for any persistent data they require.  
- Documentation clearly indicates:
  - Which workloads rely on Longhorn.  
  - Which rely on external databases or other storage.

### 5.3 Backup and DR

- Longhorn’s snapshot and backup features are configured for:
  - Regular backups of key workloads.  
  - Optional backup to an external endpoint (for example, S3-compatible storage).

- These backups are **complementary** to:
  - PostgreSQL backups (for db-01).  
  - Infrastructure-as-code rebuilds.

## 6. Operational considerations

- Longhorn metrics should be scraped by Prometheus and included in platform dashboards.  
- Alerts for:
  - Disk pressure,  
  - Replica failures, and  
  - Volume health
  should be defined.

- Academy content should show:
  - Creating a PVC that uses Longhorn.  
  - Inspecting Longhorn volumes.  
  - Performing a basic restore from a snapshot.

## 7. References

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](./ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

# Evidence Map — HybridOps.Studio

This page maps key claims about HybridOps.Studio to the proof folders that back them.  
Use it as a routing layer between high-level statements and concrete artefacts under `docs/proof/` and `output/`.

For each area, start from the listed proof entry point, then follow links to specific runs, screenshots, and logs.

---

## 1. KPI-level guarantees

These are the headline operational targets. The table shows where to start when you want to see how they are supported.

| Claim                             | Primary proof entry point                               | Supporting locations                                      |
|-----------------------------------|---------------------------------------------------------|-----------------------------------------------------------|
| Recovery Time Objective (RTO)     | [DR and failover views](./proof/observability/README.md) | DR run dashboards and timing notes under observability.  |
| Recovery Point Objective (RPO)    | [SQL read-only behaviour](./proof/sql-ro/README.md)       | WAL / promotion evidence and related DR runs.            |
| Image build performance           | [Platform — Packer builds](./proof/platform/README.md)    | Per-image folders under `platform/packer-builds/builds/` and `images-runtime/`. |
| Autoscale and burst behaviour     | [Burst and autoscaling](./proof/burst-k8s/README.md)      | Federated metrics and decision outputs under `observability/` and `decision-service/`. |
| Network resilience and failover   | [NCC and VPN evidence](./proof/ncc/README.md) and [VPN](./proof/vpn/README.md) | Connectivity screenshots, config extracts, and path tests. |
| Cost envelope and constraints     | [Cost summary](./proof/cost/summary.md)                  | Supporting estimate folders under `proof/cost/`.         |

---

## 2. Architecture assertions

The platform README and architecture diagrams describe a set of behaviours and design choices. This section points to the proof areas that support them.

| Architecture claim                                        | Where to start                                             | Notes                                                   |
|-----------------------------------------------------------|------------------------------------------------------------|---------------------------------------------------------|
| Hybrid DR with on-prem and cloud failover/failback        | [DR-related observability](./proof/observability/README.md) and [SQL read-only](./proof/sql-ro/README.md) | RTO/RPO, promotion behaviour, and DR drill traces.     |
| Kubernetes burst to cloud (autoscaling into AKS/GKE)      | [Burst and autoscaling](./proof/burst-k8s/README.md)       | Before/after node views and workload impact.           |
| Prometheus federation across on-prem and cloud            | [Observability](./proof/observability/README.md)           | Federation topology, scrape configuration, and panels. |
| Decision service driving autoscale, burst, and DR flows   | [Decision service](./proof/decision-service/README.md)     | Policy files, decision logs, and integration notes.    |
| NCC-based multi-cloud connectivity                        | [NCC evidence](./proof/ncc/README.md)                      | Hub-and-spoke views and connectivity checks.           |
| VPN and secure site-to-site tunnels                       | [VPN evidence](./proof/vpn/README.md)                      | Tunnel status, failover tests, and related artefacts.  |
| Multivendor routing (BGP/OSPF, VRRP/CARP)                 | [Multivendor routing evidence](./proof/others/multivendor-routing.md) | Config extracts and path validation runs.              |
| Governance and policy enforcement                         | [Governance evidence](./proof/others/governance.md)        | Governance packs, policy examples, and audit artefacts.|
| Image lifecycle across Proxmox, Azure, and GCP            | [Platform — Packer builds](./proof/platform/README.md) and [Runtime images](./proof/images-runtime/README.md) | Build logs, manifests, and runtime validation. |

---

## 3. How this relates to runbooks and showcases

The proof tree is not standalone. It is designed to be read alongside runbooks and scenario showcases:

- **Runbooks** describe *how* an operation is executed (for example DR cutover, VPN bring-up, or platform bootstrap).  
  - Index: [Runbooks Index](./runbooks/000-INDEX.md)  
  - Per-category views are available under `docs/runbooks/by-category/`.

- **Showcases** group code, diagrams, and scripts for complete scenarios (for example DR failover, network automation, autoscaling, or AVD).  
  - Overview: [Showcases Overview](./docs-public/showcase/README.md)  
  - Each showcase links to the specific proof folders and runs that support it.

When you are reviewing a particular behaviour, a typical path is:

1. Start from the relevant **showcase** or **runbook**.  
2. Follow links into the corresponding folder in `docs/proof/`.  
3. If needed, drill further into `output/` for raw logs and artefacts.

This keeps the relationship between documentation, code, and operational evidence explicit and auditable.

---

## 4. Navigation

- Proof archive overview: [Proof Archive](./proof/README.md)  
- Runbooks index: [Runbooks Index](./runbooks/000-INDEX.md)  
- Documentation portal home: [Docs home](./docs-public/README.md)

# Evidence Map — HybridOps.Studio

This page maps key claims about HybridOps.Studio to the proof folders that back them.  
Use it as a routing layer between high-level statements and concrete artefacts under `docs/proof/` and `output/`.

For each area, start from the listed proof entry point, then follow links to specific runs, screenshots, and logs.

---

## 1. KPI-level guarantees

These are the headline operational targets. The table shows where to start when you want to see how they are supported.

| Claim                             | Primary proof entry point                                            | Supporting locations                                                                                   |
|-----------------------------------|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Recovery Time Objective (RTO)     | [DR proof archive](proof/dr/)                                       | DR run dashboards and timing notes under [observability proof](proof/observability/)                  |
| Recovery Point Objective (RPO)    | [SQL read-only & promotion proof](proof/sql-readonly/)              | WAL / promotion evidence and related DR runs under [DR proof archive](proof/dr/)                      |
| Image build performance           | [Packer image builds](proof/infra/packer/)                          | Detailed Packer logs under `output/logs/packer/` and runtime checks under [images & runtime](proof/images-runtime/) |
| Autoscale and burst behaviour     | [Burst & autoscaling proof](proof/infra/burst/)                     | Decision outputs under [decision service proof](proof/decision-service/) and [observability proof](proof/observability/) |
| Network resilience and failover   | [Hybrid networking & VPN proof](proof/networking/)                  | Connectivity screenshots, config extracts, and path tests referenced from networking runbooks         |
| Cost envelope and constraints     | [Cost proof archive](proof/cost/)                                   | Cost model notes under [Platform cost model](guides/cost-model.md) and detailed estimates in `proof/cost/` |

---

## 2. Evidence themes & corresponding proof areas

This section maps the high‑level themes from the GTV evidence to solid technical packs and proof areas.

| Theme / question                            | Solid / briefing documents                                                                                              | Primary proof areas                                      |
|--------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| Hybrid network & WAN edge                  | `docs/briefings/gtv/OC1/03_hybrid-network-wan-edge.md` and `docs/evidence/solids/evidence-01-hybrid-network-connectivity.md` | [Networking proof](proof/networking/)                    |
| WAN edge, VPN, hybrid cloud connectivity   | `docs/evidence/solids/evidence-02-wan-edge-hybrid-connectivity.md`                                                     | [Networking proof](proof/networking/), [DR proof](proof/dr/) |
| Source of truth & NetBox automation        | `docs/briefings/gtv/OC1/04_source-of-truth-automation.md` and `docs/evidence/solids/evidence-03-source-of-truth-netbox-automation.md` | [SoT proof](proof/sot/), [Networking proof](proof/networking/) |
| Delivery platform, CI/CD & GitOps          | `docs/evidence/solids/evidence-04-delivery-platform-gitops-cluster-operations.md`                                      | [Packer & images proof](proof/infra/packer/), [GitOps proof](proof/infra/gitops/) |
| DR & cost-aware automation                 | `docs/briefings/gtv/OC1/05_hybrid-dr-cost.md`                                                                          | [DR proof](proof/dr/), [Cost proof](proof/cost/), [Decision service proof](proof/decision-service/) |
| Documentation engine & Academy             | `docs/briefings/gtv/OC2/07_docs-engine-academy.md` and `docs/evidence/solids/evidence-05-documentation-teaching-community.md` | [Docs site](index.md), [Runbooks index](runbooks/000-INDEX.md), [How-to index](howto/000-INDEX.md) |

These are **not** extra evidence beyond what is submitted to Tech Nation; they are internal pointers that help you navigate from the PDFs to the underlying technical material.

---

## 3. Proof archives by theme

The `docs/proof/` tree is organised so that each major claim has an obvious “home”. Start here for each theme:

- **Networking & hybrid connectivity**  
  - Proof archive: [proof/networking/](proof/networking/)  
  - Typical contents: traceroute and ping captures, pfSense and router screenshots, tunnel state, failover tests.  

- **Disaster recovery (DR)**  
  - Proof archive: [proof/dr/](proof/dr/)  
  - Typical contents: DR drill run logs, GitHub Actions screenshots, timing notes, before/after topology views.  

- **Cost & decision service**  
  - Proof archive: [proof/cost/](proof/cost/)  
  - Decision service: [proof/decision-service/](proof/decision-service/)  
  - Typical contents: cost JSON artefacts, decision logs, guardrail breaches, and commentary from DR drills.  

- **Images, Packer & runtime checks**  
  - Packer image builds: [proof/infra/packer/](proof/infra/packer/)  
  - Images & runtime: [proof/images-runtime/](proof/images-runtime/)  
  - Typical contents: build logs, template metadata, cloud-init outputs, and “first boot” runtime checks.

- **GitOps, clusters & platform operations**  
  - GitOps proof: [proof/infra/gitops/](proof/infra/gitops/)  
  - Cluster operations: [proof/infra/cluster-ops/](proof/infra/cluster-ops/)  
  - Typical contents: Argo CD / Flux screenshots, sync histories, upgrade and rollback logs.

- **Source of truth & automation**  
  - SoT proof: [proof/sot/](proof/sot/)  
  - Typical contents: NetBox exports, annotated screenshots, and Ansible/Nornir runs driven from SoT data.

Where relevant, proof folders will cross‑link to specific **runbooks** and **HOWTOs** that describe how a human would repeat the same operation.

---

## 4. Runbooks, HOWTOs and “how to repeat this”

For each theme there is at least one runbook or HOWTO that explains how to repeat the operation that produced the proof.

- **Runbooks**  
  - Index: [Runbooks index](runbooks/000-INDEX.md)  
  - Examples:  
    - DR cutover and failback.  
    - VPN tunnel bring‑up and troubleshooting.  
    - Image pipeline recovery and rebuild.  

- **HOWTOs**  
  - Index: [How‑To index](howto/000-INDEX.md)  
  - Examples:  
    - Bringing up the hybrid network baseline.  
    - Onboarding a new environment into NetBox.  
    - Running a cost‑aware DR drill end to end.

When in doubt, start from the relevant **index page**, pick the runbook or HOWTO that matches the flow you care about, and follow links into the proof archive and raw logs.

---

## 5. Relationship to Tech Nation evidence

The Tech Nation PDFs for the Global Talent application are distilled snapshots of the same work described here.  

For convenience:

- The **personal statement** and each evidence slot (MC / OC1 / OC2) has a corresponding Markdown source under `docs/briefings/gtv/`.  
- This evidence map, the proof archives, and the runbook/HOWTO indexes **do not add new claims** beyond those PDFs; they simply make it easier to verify them.

If you are reviewing HybridOps.Studio for Tech Nation or as a hiring manager, you can:

1. Read the PDF (or its exact Markdown source in `docs/briefings/gtv/`).  
2. Use this evidence map to jump to the relevant proof archive for the area in question.  
3. Follow links into specific runs, logs, screenshots and diagrams as needed.

The goal is that **every major claim** can be traced from a one‑line statement in a PDF to a documented procedure and one or more concrete pieces of evidence.

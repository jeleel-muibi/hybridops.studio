# Evidence Slot 5 – Hybrid DR & Cost-Aware Automation (OC1)

> **Criteria:** Optional Criteria 1 (OC1) – innovation / significant technical contributions.  
> **Scope:** Hybrid disaster recovery loop using Prometheus, GitHub Actions and a Cost Decision Service, treating cost as a first-class operational signal.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final diagrams and screenshots before submission.

---

## 1. Summary – Hybrid DR with Cost Guardrails

This evidence shows how I designed and implemented a **hybrid disaster recovery (DR) loop** for HybridOps.Studio where:

- **Prometheus federation** and Alertmanager detect critical failures.  
- **GitHub Actions** runs a **stateless DR workflow** that can promote cloud capacity and reroute traffic.  
- A **Cost Decision Service**, based on cost artefacts emitted from CI pipelines, decides whether DR or bursting is financially acceptable before changes are applied.  

The innovation is not just doing failover, but treating **cost as a first-class operational signal** alongside availability, so DR actions are:

- **Automated**,  
- **Observable**, and  
- **Cost-aware**, rather than blindly “failing over at any price”.

[IMG-01 – DR architecture diagram: Prometheus → Alertmanager → GitHub Actions → DR infra + Cost Decision Service – ~8 lines]

---

## 2. DR Control Loop – From Metrics to Actions

### 2.1 Detection – Prometheus federation and SLOs

HybridOps.Studio uses **Prometheus federation** and Alertmanager as the DR signal plane:

- Individual Prometheus instances scrape:
  - Jenkins controller health (HTTP, job success rates, queue depth).  
  - RKE2 API health and node status.  
  - Application SLOs (for example, NetBox availability).  
- A federated Prometheus instance aggregates key DR-related metrics into a central view.  

Alertmanager is configured with DR-focused alert rules, for example:

- `jenkins_critical_down` when the on-prem Jenkins controller is unavailable beyond an SLO.  
- `control_plane_unhealthy` when the RKE2 control plane fails readiness checks.  

These alerts form the **entry point** to the DR loop.

### 2.2 Trigger – Alertmanager webhook → GitHub Actions

When a DR-relevant alert fires:

- Alertmanager routes notifications to:
  - Human channels (e.g. email, chat) for awareness.  
  - A dedicated **webhook endpoint** that triggers a GitHub Actions workflow via `repository_dispatch`.

GitHub Actions is intentionally used as a **stateless orchestrator**:

- It does not hold long-term state itself.  
- It reads desired state and configuration from:
  - The Git repository (Terraform/Ansible manifests).  
  - Cost artefacts from previous pipeline runs.  
  - External parameters (e.g. which DR region to target).

This separation means DR behaviour is **versioned and auditable** via Git, rather than hidden in a single server.

[IMG-02 – Screenshot of GitHub Actions DR workflow run (success + summary) – ~6 lines]

---

## 3. Infrastructure Design – Stateless Where Possible, Stateful Where It Matters

### 3.1 RKE2 cluster and PostgreSQL LXC

HybridOps.Studio separates **compute** from **state** so that DR is easier:

- Workloads run on an **RKE2 Kubernetes cluster** on Proxmox.  
- Application and platform state (for example, NetBox data) lives in a dedicated **PostgreSQL LXC (`db-01`)** with host-mounted storage and backup tooling (WAL-based backups, cloud replica planning).

This design means that in DR scenarios:

- The RKE2 cluster and Jenkins agents are treated as **re-creatable** (stateless) capacity.  
- The PostgreSQL LXC and its replica(s) are treated as **stateful anchors**, with clear promotion and failover procedures.

### 3.2 Jenkins vs GitHub Actions – roles in DR

Jenkins is used as the **day-to-day orchestrator** for:

- Packer image pipeline runs.  
- Terraform/Ansible env provisioning.  
- Regular infrastructure changes in on-prem environments.

GitHub Actions is used as the **DR execution surface**, because:

- It is **external** to the on-prem environment and so remains available even if on-prem is down.  
- It scales on demand and can execute DR workflows without relying on the on-prem controller.  

This division of responsibility ensures that DR automation is robust even if the primary CI system is part of the failure.

---

## 4. Cost Decision Service – Cost as a First-Class Signal

### 4.1 Cost artefacts from CI pipelines

CI pipelines that perform significant infrastructure operations emit **cost artefacts** in a standard format, documented in `docs/ci/CI_cost_artefacts_from_pipelines.md`:

- Cost estimates are generated for:
  - Baseline on-prem capacity.  
  - Prospective cloud DR or burst capacity.  
- Artefacts are written as JSON under:
  - `docs/proof/cost/<component>/cost-run-<run_id>.json`

[ART-01 – small JSON snippet from a cost artefact (redacted) – ~6 lines]

This gives the Cost Decision Service **structured data** about the financial impact of DR options, versioned alongside the code.

### 4.2 Decision logic

When a DR workflow starts in GitHub Actions:

1. It fetches the latest relevant cost artefact(s).  
2. It evaluates whether executing DR or bursting:
   - Stays within defined budget guardrails, or  
   - Would exceed them.  
3. It returns one of:
   - `allow` – DR actions may proceed.  
   - `warn` – borderline; require human approval or degraded mode.  
   - `block` – DR actions are blocked on cost grounds.

If the decision is `block`, the workflow:

- Notifies human channels with a detailed message.  
- Records the blocked event under `docs/proof/cost/...` for audit.  

This dual focus on **technical correctness and financial discipline** is unusual for self-directed platform projects and demonstrates a **mature, FinOps-influenced mindset**.

### 4.3 Security considerations

The design of the DR and cost workflows is influenced by my training in:

- IBM **Cybersecurity**.  
- IBM **Enterprise Security in Practice**.  

As a result:

- Credentials and secrets are not embedded directly in workflows; they are stored in secure backends and projected at runtime (for example, using External Secrets Operator with Azure Key Vault for Kubernetes workloads).  
- DR workflows avoid exposing sensitive configuration in logs.  
- Access to trigger DR workflows is controlled and audited via GitHub and repository permissions.

---

## 5. DR Drills, Runbooks and Proof Artefacts

### 5.1 DR drill HOWTO and runbooks

To make the DR design executable and teachable, I created:

- **HOWTO: Run a cost-aware DR drill** (`HOWTO_dr_cost_drill.md`), which guides a user through:
  - Firing a test alert (e.g. simulated Jenkins outage).  
  - Watching the Alertmanager → GitHub Actions flow.  
  - Inspecting cost decisions and DR actions.  

- **Runbooks** for:
  - DR cutover: on-prem → cloud.  
  - DR failback: cloud → on-prem.  
  - Cost guardrail breach (DR/burst blocked).  
  - Jenkins controller outage.  
  - db-01 LXC failover and promotion.

These documents ensure the DR system is **operationally usable**, not just theoretically designed.

[IMG-03 – Screenshot of HOWTO_dr_cost_drill.md in the docs site – ~6 lines]  
[IMG-04 – Screenshot of DR cutover runbook – ~6 lines]

### 5.2 Proof artefacts

DR drills and cost decisions produce artefacts under:

- `docs/proof/dr/...` – DR drill records, logs, and screenshots.  
- `docs/proof/cost/...` – cost artefacts and decision logs.

For a given drill, an assessor or engineer can:

1. See the **inputs** (alert, environment).  
2. Inspect the **actions** taken by GitHub Actions.  
3. Review the **cost decisions** and final outcome.

[IMG-05 – Directory listing screenshot of docs/proof/dr and docs/proof/cost – ~6 lines]

This level of evidence is normally expected in regulated or highly controlled environments; including it in a self-directed **hybrid platform blueprint** shows a deliberate focus on **reliability, auditability and financial accountability**.

---

## 6. Innovation & Reusability

The DR and cost-aware automation work in HybridOps.Studio is innovative in several ways:

- It treats **Prometheus/Alertmanager signals**, **GitHub Actions workflows** and **cost artefacts** as parts of a single control loop, rather than separate tools.  
- It separates **stateful** components (PostgreSQL LXC and replicas) from **stateless** capacity (RKE2 cluster, Jenkins agents, cloud workloads), making DR more predictable.  
- It integrates **FinOps thinking** (“can we afford this DR action?”) into the same pipeline that handles technical failover.  
- It packages the entire design with **ADRs, HOWTOs, runbooks and proof folders**, so another engineer could both understand and replay the design.

[IMG-06 – Optional collage: DR diagram + GitHub Actions run + cost artefact + docs screenshots – ~6 lines]

This work is reusable as a **pattern** for:

- Startups and engineering teams that want robust DR without uncontrolled cloud spend.  
- Hybrid environments where on-prem and cloud both play a role.  
- Teaching scenarios in the HybridOps Academy, where learners can walk through DR drills that include both technical and financial decision points.

---

## 7. How This Meets Optional Criteria 1 (Innovation)

This evidence supports Optional Criteria 1 by showing that I have:

- Designed and implemented a **non-trivial, hybrid DR system** that combines metrics, automation, and cost guardrails.  
- Applied knowledge from networking, Kubernetes, CI/CD, observability and security training to a coherent, production-style design.  
- Built the **operational scaffolding** (runbooks, HOWTOs, proof artefacts) that turns the design into a repeatable practice.  
- Created a pattern that can be reused by others through the docs engine and future HybridOps Academy content.

It demonstrates the level of **technical innovation, systems thinking and operational maturity** that I can bring to a platform/SRE role in a product-led technology organisation.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.

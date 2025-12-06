# Evidence Slot 8 – Teaching & Public Content Around HybridOps (OC2)

> **Criteria:** Optional Criteria 2 (OC2) – contributions outside employment (public teaching and content).  
> **Scope:** Videos, posts, webinars and the HybridOps Academy funnel built on the HybridOps.Studio platform blueprint.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final screenshots before submission.

---

## 1. Summary – Sharing the Blueprint in Public

HybridOps.Studio is not only a private platform blueprint; it is also the **engine behind my public teaching and content**. This evidence shows how I:

- Use **videos, posts and talks** to explain HybridOps patterns (hybrid network, NetBox, DR, cost) in a way that other engineers can reuse.  
- Tie every piece of content back to **real infrastructure work**, not toy examples.  
- Build a **sustainable teaching funnel** from free content into HybridOps Academy.

[IMG-01 – Screenshot collage of public channels: YouTube channel header, LinkedIn profile, docs.hybridops.studio/showcase – ~6 lines]

---

## 2. Context – From Platform Blueprint to Learning Surface

HybridOps.Studio is a hybrid platform blueprint that combines:

- A dual-ISP pfSense-based network and WAN edge.  
- NetBox and PostgreSQL as a **source of truth** for automation.  
- RKE2, Jenkins and GitHub Actions for delivery.  
- Prometheus-driven DR and cost-aware automation.  
- A documentation engine at `docs.hybridops.studio`.

From the beginning, I designed this platform so that it could be **taught and reused**, not just run privately. The public content around HybridOps is built on three principles:

1. **Real artefacts, not mock-ups** – every demo comes from an actual repo, ADR, or runbook.  
2. **Narrated systems thinking** – I explain *why* decisions were made, not just *how* to click or type commands.  
3. **Pathways into deeper learning** – free content introduces patterns, while HybridOps Academy provides structured, hands-on progression.

[IMG-02 – Screenshot of docs.hybridops.studio landing page highlighting “Start here” / Showcase / Academy links – ~6 lines]

---

## 3. Video Content – Teaching HybridOps Patterns Visually

I use short, focused videos to make HybridOps patterns concrete. Typical flagship pieces include:

### 3.1 HybridOps.Studio Platform Overview

- **Format:** 10–15 minute narrated walkthrough.  
- **Content:**  
  - High-level architecture: Proxmox, pfSense, NetBox, RKE2, Jenkins, Prometheus, GitHub Actions.  
  - How the pieces combine into a **hybrid platform blueprint**.  
  - Pointers to ADRs and evidence packs for deeper dives.  
- **Impact:**  
  - Serves as the entry point for engineers discovering HybridOps for the first time.  
  - Used as pre-reading material for Academy and 1:1 mentoring.

[IMG-03 – Screenshot of YouTube video page for “HybridOps.Studio Overview” showing title, thumbnail, description and view count – ~6 lines]

### 3.2 DR Drill & Cost Guardrails Walkthrough

- **Format:** 15–20 minute scenario-based video.  
- **Content:**  
  - Simulated on-prem Jenkins failure and Prometheus alert.  
  - GitHub Actions workflow triggering a **cost-aware DR path**.  
  - Explanation of the **Cost Decision Service** concept and budget guardrails.  
  - How evidence artefacts (logs, dashboards, decision outputs) are captured under `docs/proof/`.  
- **Impact:**  
  - Demonstrates that DR is not just “failover at any price”; cost is a first-class signal.  
  - Offers a reusable pattern for teams considering cost-aware DR in their own environments.

[IMG-04 – Screenshot of DR video showing timeline, Prometheus alert, and GitHub Actions job – ~6 lines]

### 3.3 NetBox → Automation Demo

- **Format:** 10–15 minute hands-on demo.  
- **Content:**  
  - Populating NetBox with devices, VLANs, prefixes using real HybridOps data.  
  - Using Terraform/Ansible/Nornir to consume NetBox as **source of truth**.  
  - Showing how changes in NetBox drive consistent configuration.  
- **Impact:**  
  - Provides a concrete starting pattern for engineers wanting to move away from spreadsheets and ad-hoc inventories.  
  - Links back to Evidence 3 (NetBox) and related ADRs.

[IMG-05 – Screenshot of NetBox automation video: NetBox UI + terminal running automation – ~6 lines]

For each video, I track:

- Views and watch time over time.  
- Comments and questions that reveal what engineers find most useful.  
- Click-throughs to docs.hybridops.studio and GitHub.

[IMG-06 – Screenshot from YouTube Studio analytics with redacted numbers showing growth over time – ~6 lines]

---

## 4. Written Posts and Documentation-Linked Content

In addition to video, I publish **written content** that distils lessons from HybridOps into standalone pieces.

### 4.1 LinkedIn / Blog Posts

Examples of posts include:

- **“Treating a Homelab Like a Platform Product”** – explaining ADRs, runbooks and evidence-driven DR drills.  
- **“Source of Truth First: Why NetBox Matters Before Terraform”** – arguing for data modelling before automation.  
- **“Cost-Aware DR: Resilience Without Blank Cheques”** – outlining the cost decision and guardrail concepts.

Each post:

- Links back to specific ADRs, HOWTOs or runbooks in the HybridOps.Studio repo.  
- Uses diagrams or screenshots from the real platform.  
- Invites feedback or questions from practitioners.

[IMG-07 – Screenshot of a LinkedIn post, with visible headline and a few opening lines, plus engagement metrics (likes/comments) – ~6 lines]

### 4.2 Deep Links into Docs

Where possible, written posts act as **entry points** into deeper documentation:

- A post on NetBox links to `docs.hybridops.studio/showcase/netbox-automation`.  
- A DR article links to `docs.hybridops.studio/showcase/dr-cost-drill`.  
- Posts on teaching link to Academy and bootcamp landing pages.

This creates a loop where:

1. Public posts introduce a concept.  
2. Docs provide **step-by-step patterns**.  
3. HybridOps Academy offers structured practice and mentoring.

[IMG-08 – Screenshot of a docs.hybridops.studio showcase page, with “linked from LinkedIn/blog” annotation – ~6 lines]

---

## 5. Talks, Webinars and the Academy Funnel

### 5.1 Mini-Webinars and Live Sessions

I design slide decks and live sessions that reuse the same artefacts:

- **Introductory sessions** – HybridOps.Studio architecture and what “treat it like a platform product” means.  
- **Deep dives** – NetBox SoT flows, DR drills, cost guardrails.  
- **Q&A sessions** – talking through trade-offs, constraints, and how to adapt patterns to different sizes of organisation.

Materials from these sessions (slides, demo scripts) are then:

- Turned into short videos or written summaries.  
- Added to docs.hybridops.studio or linked from Academy pages.

[IMG-09 – Screenshot of a slide from a mini-webinar (e.g. “HybridOps.Studio – DR & Cost Guardrails”) – ~6 lines]

### 5.2 HybridOps Academy as Structured Teaching

HybridOps Academy turns the blueprint into a **repeatable teaching product**:

- Public **showcases** at `docs.hybridops.studio/showcase` act as free labs and walkthroughs.  
- A flagship **“HybridOps Architect”** cohort-based course provides:
  - Guided use of the same repos and Kubernetes / NetBox / DR patterns.  
  - Assignments based on real HybridOps tasks.  
  - Office hours and code/doc reviews.  
- Specialist labs (e.g. DR & cost, NetBox source of truth, Env Guard) build on the same evidence tree used in the GTV pack.

The free public content (videos, posts, showcases) and the paid Academy tiers reinforce each other:

- Free content broadens reach and proves value.  
- Academy deepens skills and provides a sustainable way to maintain and grow the material over time.

[IMG-10 – Screenshot of Academy page (Moodle or landing page) showing “HybridOps Architect” and lab examples – ~6 lines]

---

## 6. How This Meets Optional Criteria 2

This evidence supports **OC2 (recognition and contributions outside employment)** by showing that:

- I am not only building HybridOps.Studio but **actively teaching and explaining it** through videos, posts, talks and an Academy structure.  
- All content is grounded in **real, working infrastructure** – the same repos, ADRs and evidence used elsewhere in the application.  
- I am building a **reusable educational asset** that can help engineers and startups adopt better hybrid platform patterns: source-of-truth automation, DR drills, cost guardrails and documentation.

It also complements:

- **Evidence 6–7** (docs engine and Academy) by providing the **public surface** (videos, posts, webinars).  
- **Slot 10** (public adoption) by seeding awareness of Ansible collections and other artefacts that can be reused directly.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.

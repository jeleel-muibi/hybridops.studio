# HybridOps.Studio – GTV Evidence Cover Sheet (Draft)

> **Working draft – not for submission.**  
> This page summarises the planned evidence slots for a future Tech Nation Global Talent application and how they map to the criteria.

---

## Slot Index (Quick Reference)

| Slot | Criteria | Title                                             | File path                                                       |
|------|----------|---------------------------------------------------|-----------------------------------------------------------------|
| 1    | MC       | Platform Overview & Trajectory                    | `docs/evidence/gtv/MC/01_platform-overview.md`                  |
| 2    | MC       | Academic Excellence & Early Innovation            | `docs/evidence/gtv/MC/02_academic-early-innovation.md`          |
| 3    | OC1      | Hybrid Network & WAN Edge                         | `docs/evidence/gtv/OC1/03_hybrid-network-wan-edge.md`           |
| 4    | OC1      | Source of Truth & Automation (NetBox)             | `docs/evidence/gtv/OC1/04_source-of-truth-automation.md`        |
| 5    | OC1      | Hybrid DR & Cost-Aware Automation                 | `docs/evidence/gtv/OC1/05_hybrid-dr-cost.md`                    |
| 6    | OC2      | Public Impact: Open Source & Learning Surface     | `docs/evidence/gtv/OC2/06_public-impact.md`                     |
| 7    | OC2      | Docs Engine & HybridOps Academy                   | `docs/evidence/gtv/OC2/07_docs-engine-academy.md`               |
| 8    | OC2      | Teaching & Public Content Around HybridOps        | `docs/evidence/gtv/OC2/08_teaching-public-content.md`           |
| 9    | MC / OC3 | Real-World Contributions in Employed Roles        | `docs/evidence/gtv/MC/03_real-world-contributions-latymer.md`   |
| 10   | OC2      | Public Adoption & External Recognition            | `docs/evidence/gtv/OC2/10_public-adoption-external-recognition.md` |

---

## Personal Statement

**File:** `docs/evidence/gtv/personal_statement.md`  
**Status:** Complete (~1,000 words, under Tech Nation limit)

**Summary**

The personal statement ties together:

- **HybridOps.Studio** as a hybrid platform blueprint and reference implementation.  
- **Academic foundation** – first-class BSc Computer Science at the University of East London, departmental award, final-year project in the top 15 of 120.  
- **Real-world impact** – Latymer School profile-cleanup automation and early platform thinking in a live environment.  
- **Documentation and teaching** – docs.hybridops.studio, ADRs, HOWTOs, runbooks, and the emerging HybridOps Academy.  
- **Future plans in the UK** – platform/SRE roles, Academy, and open community contribution.

**Criteria linkage**

- **MC:** Sections 1, 2, 3 and 5 (academic excellence, HybridOps.Studio, Latymer, UK plans).  
- **OC1:** Section 2 (hybrid platform, DR & cost-aware automation).  
- **OC2:** Section 4 (docs engine, Academy, public surface).

---

## 1. Criteria Overview

- **Mandatory Criteria (MC):**  
  Demonstrate recognition as (or potential to be) a leader in the digital technology sector.

- **Optional Criteria 1 (OC1):**  
  Demonstrate innovation and significant technical contributions.

- **Optional Criteria 2 (OC2):**  
  Demonstrate contributions to the tech sector outside of immediate employment (teaching, open source, community, content).

---

## 2. Evidence Slots at a Glance

### Mandatory Criteria – Core Narrative

**Slot 1 – Platform Overview & Trajectory (MC)**  
**File:** `docs/evidence/gtv/MC/01_platform-overview.md`  
**One-line impact:**  
HybridOps.Studio is a **hybrid platform blueprint and reference implementation** that I design and operate to production standards as a platform/SRE product, showing the level of ownership and systems thinking I can bring to a modern engineering team.

**Slot 2 – Academic Excellence & Early Innovation (MC)**  
**File:** `docs/evidence/gtv/MC/02_academic-early-innovation.md`  
**One-line impact:**  
A **first-class BSc in Computer Science**, departmental award for outstanding engagement, top-15 final-year project in network automation, BCS membership and structured training (Azure, networking, IBM security) show a strong foundation and early leadership trajectory.

**Slot 9 – Real-World Contributions in Employed Roles (Latymer) (MC / OC3 support)**  
**File:** `docs/evidence/gtv/MC/03_real-world-contributions-latymer.md`  
**One-line impact:**  
Shows how I brought a platform mindset into a real school environment by analysing a recurring storage/profile issue, proposing and implementing a PowerShell cleanup script that the Network Manager approved and rolled out across labs and laptops, and beginning to automate device de-boarding – demonstrating practical impact, collaboration and lifecycle thinking in an employed role.

---

### Optional Criteria 1 – Innovation & Technical Contributions

**Slot 3 – Hybrid Network & WAN Edge (OC1)**  
**File:** `docs/evidence/gtv/OC1/03_hybrid-network-wan-edge.md`  
**One-line impact:**  
Designed and implemented an **enterprise-style hybrid network baseline** – dual-ISP pfSense WAN edge, VLAN segmentation and IPsec tunnels – captured as a reusable blueprint and integrated with NetBox and automation.

**Slot 4 – Source of Truth & Automation (NetBox) (OC1)**  
**File:** `docs/evidence/gtv/OC1/04_source-of-truth-automation.md`  
**One-line impact:**  
Built a **NetBox-driven source of truth and automation layer** where Terraform, Ansible and Nornir all consume the same data model, turning HybridOps.Studio into a reusable SoT + automation blueprint rather than a collection of scripts.

**Slot 5 – Hybrid DR & Cost-Aware Automation (OC1)**  
**File:** `docs/evidence/gtv/OC1/05_hybrid-dr-cost.md`  
**One-line impact:**  
Implemented a **hybrid DR control loop** (Prometheus → Alertmanager → GitHub Actions) combined with a **Cost Decision Service** and cost artefacts, so failover and bursting decisions are automated, observable and FinOps-aware.

---

### Optional Criteria 2 – Contributions Outside Occupation

**Slot 6 – Public Impact: Open Source & Learning Surface (OC2)**  
**File:** `docs/evidence/gtv/OC2/06_public-impact.md`  
**One-line impact:**  
Exposed the HybridOps.Studio blueprint via public GitHub repositories, a structured docs portal and public showcases, and started turning it into talks, courses and collections so others can learn from and reuse the patterns.

**Slot 7 – Docs Engine & HybridOps Academy (OC2)**  
**File:** `docs/evidence/gtv/OC2/07_docs-engine-academy.md`  
**One-line impact:**  
Designed a **documentation engine and Academy structure** (MkDocs site, ADR/HOWTO/runbook/CI/CASE templates, showcases and labs) that turns HybridOps.Studio into a repeatable teaching and consulting platform, not just a private environment.

**Slot 8 – Teaching & Public Content Around HybridOps (OC2)**  
**File:** `docs/evidence/gtv/OC2/08_teaching-public-content.md`  
**One-line impact:**  
Shows how I turn HybridOps.Studio and the Academy into public learning material – short videos, posts and talks that explain key flows (DR, cost, NetBox automation) based on real platform work, reinforcing my contribution to the wider community beyond code alone.

**Slot 10 – Public Adoption & External Recognition (OC2, also supports MC/OC1)**  
**File:** `docs/evidence/gtv/OC2/10_public-adoption-external-recognition.md`  
**One-line impact:**  
Packages key HybridOps roles into **Ansible Galaxy collections** with Molecule-tested pipelines and tracks downloads, feedback and external references, demonstrating that other engineers adopt and extend this work in their own environments.

---

## 3. How to Use This Cover Sheet

- Use this page as a **quick map** when drafting the personal statement and checking coverage against MC, OC1 and OC2.  
- Keep one clear **headline** per slot so assessors can quickly understand what each PDF is trying to prove.  
- As the drafts evolve, update the one-line impact statements rather than rewriting this page from scratch.

When it’s time to apply, this cover sheet can also serve as your own **sanity checklist**: if a slot’s PDF doesn’t clearly deliver the headline impact written here, tighten the PDF rather than changing the headline.

---

## 4. Referees (planned)

I plan to provide three referee letters that align with the evidence slots:

- **Referee 1 – Senior platform / engineering leader**  
  Focus: HybridOps.Studio as a hybrid platform blueprint, DR and cost guardrails, and my systems thinking across networking, SoT, delivery and observability (MC Slot 1, OC1 Slots 3–5, OC2 Slots 6–8, 10).

- **Referee 2 – Christopher Okonkwo, IT Technician / line manager at The Latymer School**  
  Focus: Real-world impact in my IT Technician role, including the user profile cleanup control and wider system administration responsibilities in a live school environment (MC Slot 9).

- **Referee 3 – Academic referee at the University of East London**  
  Focus: Academic excellence, departmental award and the final-year project in network automation and abstraction, and how that work links to the later HybridOps.Studio blueprint (MC Slot 2, OC2 Slot 6).

I keep a short **referees brief** that summarises these themes and links to the relevant repositories and documentation, so referees can give specific, evidence-backed examples rather than general praise.

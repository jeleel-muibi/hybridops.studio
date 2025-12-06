# Evidence Slot 6 – Public Impact: Open Source & Learning Surface (OC2)

> **Criteria:** Optional Criteria 2 (OC2) – contributions outside of immediate occupation (open source, learning resources, community).  
> **Scope:** Open HybridOps.Studio and FYP repositories, documentation written for others, and the early HybridOps Academy learning surface.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final screenshots before submission.

---

## 1. Summary – Making the Blueprint Public

This evidence shows how I take the HybridOps.Studio blueprint and expose it as a **public learning and reference surface**, not just a private environment.

The focus here is on:

- **Open repositories** (for example, HybridOps.Studio and my final-year project).  
- **Documentation that is written for others**, not only for future me.  
- The **early stages of HybridOps Academy** as a public-facing learning track.  

Together, these show that I am already operating with a mindset of **sharing patterns and teaching others**, which is core to Optional Criteria 2.

[IMG-01 – Screenshot of main HybridOps.Studio GitHub repository landing page – ~6 lines]

---

## 2. Open Source Repositories & Code Exposure

### 2.1 HybridOps.Studio repository

The **HybridOps.Studio repository** is intended as a **reference implementation** of the platform blueprint:

- It contains:
  - Infrastructure as Code (Terraform, Packer, Ansible, Nornir).  
  - Documentation scaffolding (MkDocs config, templates, ADRs, HOWTOs, runbooks).  
  - CI documentation and scripts (Jenkins/GitHub Actions briefs).  
  - Evidence and proof folders for DR drills, cost artefacts and platform behaviours.

- It is structured to be understandable to new readers:
  - Clear top-level `README` explaining the vision and layout.  
  - Per-area READMEs under `infra/`, `core/`, `deployment/`, `docs/`.  
  - Consistent naming and template usage so patterns are easy to follow.

[IMG-02 – Screenshot of repo tree and README section highlighting structure and purpose – ~8 lines]

The repo is not just a place where I push random configs; it is curated so that **other engineers and learners can navigate and reuse** ideas.

### 2.2 Final-year project repository – Network Automation & Abstraction

I also maintain a GitHub repository for my **final-year project**, `Network_automation_and_Abstraction`:

- This project was ranked in the **top 15 of 120** in my cohort.  
- It explores **network automation and abstraction**, the same themes that now power HybridOps.Studio.  
- The repository includes:
  - Project report and artefacts.  
  - Code for abstraction and automation logic.  
  - Documentation aimed at explaining the design to assessors and peers.

[IMG-03 – Screenshot of the FYP GitHub repository showing description and code layout – ~6 lines]

By keeping this project public, I provide a **visible lineage** from early academic work to the more advanced platform blueprint.

---

## 3. Documentation Written for External Readers

Across both repositories, I invest heavily in documentation that is clearly meant for **other people** to use:

- **ADR documents** that explain why certain choices were made (for example, RKE2, NetBox as SoT, Packer + Cloud-Init, DR signal design).  
- **HOWTO guides** that explain step-by-step tasks, such as:
  - Running the Packer image pipeline via Jenkins.  
  - Bootstrapping an RKE2 cluster from templates.  
  - Migrating NetBox from Docker to RKE2.  
  - Running a cost-aware DR drill.

- **Runbooks** that treat the platform as if it were in production, with triggers, severities, safety checks and evidence locations.

[IMG-04 – Screenshot of rendered docs (MkDocs) showing ADR/HOWTO/runbook indexes – ~8 lines]

The style and structure (templates, indexes, evidence folders) show that the documentation is built to be **consumed and trusted** by others, not just as personal notes.

---

## 4. Early HybridOps Academy Surface

The **HybridOps Academy** concept is being built around the existing documentation engine:

- Under `deployment/academy/showcases/`, I define **showcases and labs** that can be used for:
  - Workshops.  
  - Bootcamps.  
  - Self-paced learning.

Each showcase uses `show_README_template.md` and includes:

- Learning objectives.  
- Prerequisites and environment setup.  
- Step-by-step tasks.  
- Validation steps and links to deeper ADRs/evidence.

Examples of designed or planned showcases:

- **CI/CD Pipeline Showcase** – walking through a platform pipeline from code to RKE2.  
- **DR Drill & Cost Guardrails Showcase** – simulating a Jenkins outage and following the DR loop end-to-end.  
- **Hybrid Network & SoT Showcase** – demonstrating how NetBox drives configuration for pfSense, Proxmox and RKE2.

[IMG-05 – Screenshot of an academy showcase README highlighting objectives and steps – ~6 lines]

Even before full public courses launch, these artefacts show clear intent to **teach and share** the HybridOps.Studio patterns with others.

---

## 5. Future-Facing: Collections, Talks and Courses

HybridOps.Studio and the surrounding documentation provide a strong foundation for future public impact, including:

- **Ansible Galaxy collection(s)**:
  - Roles and collections extracted from HybridOps.Studio (for example, RKE2 bootstrap, connectivity tests, DR drills).  
  - CI pipelines that run Molecule tests and track download metrics.

- **Talks or webinars**:
  - Sessions using the academy showcases as live demos (for example, “Cost-Aware DR for Hybrid Platforms on a Budget”).  

- **Bootcamps and online courses**:
  - Structured learning experiences that reuse:
    - The platform blueprint.  
    - The documentation engine.  
    - The academy showcases and labs as modules.

[IMG-06 – Placeholder for future screenshot: Ansible Galaxy role page, webinar slide, or course outline – ~6 lines]

These plans are grounded in artefacts that already exist in the repositories; the evidence here shows that I am deliberately building towards **teaching and community-facing work**, not treating it as an afterthought.

---

## 6. How This Meets Optional Criteria 2 (Contributions Outside Occupation)

This evidence supports Optional Criteria 2 by showing that I have:

- Published **non-trivial technical work** in open repositories (HybridOps.Studio and my FYP) that document how I approach networks, platforms and automation, not just final screenshots.  
- Structured those repositories with **documentation written for others** – ADRs, HOWTOs, runbooks, CI briefs – so that assessors, hiring managers and engineers can follow and reuse the patterns.  
- Exposed a genuinely **public learning surface** through the docs portal and showcases, while designing deeper, premium Academy bootcamps on top of the same blueprint for learners who want structured, paid programmes.  
- Laid a concrete foundation for future **talks, courses and Ansible Galaxy collections**, turning the platform into an ongoing source of community and educational impact rather than a one-off project.

Taken together, this demonstrates that my contribution is not limited to doing the work privately: I am deliberately **open-sourcing my thinking, packaging it for others, and building sustainable teaching products around it**, in line with Tech Nation’s expectations for OC2.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.

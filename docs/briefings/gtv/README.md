# HybridOps.Studio – GTV Evidence Workspace

> **Working notes – not for submission.**  
> This folder organises the draft evidence slots for a future Tech Nation Global Talent (GTV) application.

Each evidence slot lives as a single Markdown file under `docs/briefings/gtv/<CRITERIA>/`:

- `MC/01_platform-overview.md`  
- `MC/02_academic-early-innovation.md`  
- `MC/03_real-world-contributions-latymer.md`  
- `OC1/03_hybrid-network-wan-edge.md`  
- `OC1/04_source-of-truth-automation.md`  
- `OC1/05_hybrid-dr-cost.md`  
- `OC2/06_public-impact.md`  
- `OC2/07_docs-engine-academy.md`  
- `OC2/08_teaching-public-content.md`  
- `OC2/10_public-adoption-external-recognition.md`

Each file is a **working narrative** with `[IMG-XX]` / `[ART-XX]` placeholders that will later be turned into a 2–3 page PDF with diagrams, screenshots and artefacts dropped in.

## Personal Statement

The personal statement for this application is in:

- `docs/briefings/gtv/personal_statement.md`

It should be read alongside the MC / OC1 / OC2 evidence slots defined in this folder and the solid evidence packs under:

- `docs/briefings/gtv/solids/evidence-01-hybrid-network-connectivity.md`  
- `docs/briefings/gtv/solids/evidence-02-wan-edge-hybrid-connectivity.md`  
- `docs/briefings/gtv/solids/evidence-03-source-of-truth-netbox-automation.md`  
- `docs/briefings/gtv/solids/evidence-04-delivery-platform-gitops-cluster-operations.md`  
- `docs/briefings/gtv/solids/evidence-05-documentation-teaching-community.md`  
- `docs/briefings/gtv/solids/evidence-06-teaching-public-content.md` *(future)*  
- `docs/briefings/gtv/solids/evidence-10-public-adoption-external-recognition.md` *(future)*

---

## 1. Evidence Slots and Criteria Mapping

### Mandatory Criteria (MC) – Potential Leader

- **Slot 1 – Platform Overview & Trajectory**  
  - Path: `docs/briefings/gtv/MC/01_platform-overview.md`  
  - Role: Core narrative of HybridOps.Studio as a **hybrid platform blueprint and reference implementation**, plus personal trajectory and leadership potential.  
  - Criteria: **MC** (primary), supports OC1/OC2.

- **Slot 2 – Academic Excellence & Early Innovation**  
  - Path: `docs/briefings/gtv/MC/02_academic-early-innovation.md`  
  - Role: First-class BSc, departmental award, top-15 FYP in network automation, BCS membership, structured training (Azure, networking, IBM security).  
  - Criteria: **MC** (primary), supports OC2.

- **Slot 9 – Real-World Contributions in Employed Roles (Latymer)**  
  - Path: `docs/briefings/gtv/MC/03_real-world-contributions-latymer.md`  
  - Role: Concrete impact as an IT Technician with system administration responsibilities – user profile cleanup control across labs and laptops, device lifecycle thinking, collaboration with the Network Manager.  
  - Criteria: **MC** (primary), can also support OC3 if needed.

### Optional Criteria 1 (OC1) – Innovation / Technical Contributions

- **Slot 3 – Hybrid Network & WAN Edge**  
  - Path: `docs/briefings/gtv/OC1/03_hybrid-network-wan-edge.md`  
  - Role: Dual-ISP pfSense WAN edge, VLAN segmentation, IPsec hybrid connectivity, networking evidence packs and ADRs as a reusable hybrid baseline.  
  - Criteria: **OC1** (primary).

- **Slot 4 – Source of Truth & Automation (NetBox)**  
  - Path: `docs/briefings/gtv/OC1/04_source-of-truth-automation.md`  
  - Role: NetBox as source of truth for network + infra, consumed by Terraform/Ansible/Nornir as a reusable SoT + automation blueprint.  
  - Criteria: **OC1** (primary).

- **Slot 5 – Hybrid DR & Cost-Aware Automation**  
  - Path: `docs/briefings/gtv/OC1/05_hybrid-dr-cost.md`  
  - Role: Prometheus → Alertmanager → GitHub Actions DR loop, Cost Decision Service, cost artefacts, DR drills + runbooks.  
  - Criteria: **OC1** (primary), supports OC2.

### Optional Criteria 2 (OC2) – Contributions Outside Occupation

- **Slot 6 – Public Impact: Open Source & Learning Surface**  
  - Path: `docs/briefings/gtv/OC2/06_public-impact.md`  
  - Role: Public GitHub repos (HybridOps.Studio, FYP), documentation written for others, public docs surface, early Academy footprint.  
  - Criteria: **OC2** (primary).

- **Slot 7 – Docs Engine & HybridOps Academy**  
  - Path: `docs/briefings/gtv/OC2/07_docs-engine-academy.md`  
  - Role: MkDocs-based docs engine, ADR/HOWTO/runbook/CI/CASE templates, academy showcases and labs as reusable teaching assets.  
  - Criteria: **OC2** (primary), supports MC/OC1.

- **Slot 8 – Teaching & Public Content Around HybridOps**  
  - Path: `docs/briefings/gtv/OC2/08_teaching-public-content.md`  
  - Role: Videos, posts, webinars and other public content that explain HybridOps patterns (DR, cost, NetBox) and route people into docs and Academy.  
  - Criteria: **OC2** (primary).

- **Slot 10 – Public Adoption & External Recognition**  
  - Path: `docs/briefings/gtv/OC2/10_public-adoption-external-recognition.md`  
  - Role: Ansible Galaxy collections, download metrics, external feedback and references that show other engineers adopting and extending HybridOps roles and patterns.  
  - Criteria: **OC2** (primary), also supports **MC/OC1** as external validation.

---

## 2. Structuring Plan (Single Source of Truth)

This README and `gtv_cover_sheet.md` are the **only active maps** for the GTV narrative.  
Older “structuring plan” notes are considered legacy and can be archived.

### 2.1 Where things live

- **Personal statement**
  - `docs/briefings/gtv/personal_statement.md`

- **Tech Nation evidence narratives (PDF sources)**
  - **Mandatory Criteria (MC)**
    - Slot 1 – Platform overview & trajectory  
      → `docs/briefings/gtv/MC/01_platform-overview.md`
    - Slot 2 – Academic excellence & early innovation  
      → `docs/briefings/gtv/MC/02_academic-early-innovation.md`
    - Slot 9 – Real-world contributions in employed roles (Latymer)  
      → `docs/briefings/gtv/MC/03_real-world-contributions-latymer.md`

  - **Optional Criteria 1 (OC1 – innovation / technical contributions)**
    - Slot 3 – Hybrid network & WAN edge  
      → `docs/briefings/gtv/OC1/03_hybrid-network-wan-edge.md`
    - Slot 4 – Source of truth & automation (NetBox)  
      → `docs/briefings/gtv/OC1/04_source-of-truth-automation.md`
    - Slot 5 – Hybrid DR & cost-aware automation  
      → `docs/briefings/gtv/OC1/05_hybrid-dr-cost.md`

  - **Optional Criteria 2 (OC2 – contributions outside occupation)**
    - Slot 6 – Public impact: open source & learning surface  
      → `docs/briefings/gtv/OC2/06_public-impact.md`
    - Slot 7 – Docs engine & HybridOps Academy  
      → `docs/briefings/gtv/OC2/07_docs-engine-academy.md`
    - Slot 8 – Teaching & public content around HybridOps  
      → `docs/briefings/gtv/OC2/08_teaching-public-content.md`
    - Slot 10 – Public adoption & external recognition  
      → `docs/briefings/gtv/OC2/10_public-adoption-external-recognition.md`

- **Technical “solids” (deep backbone evidence)**
  - `docs/briefings/gtv/solids/evidence-01-hybrid-network-connectivity.md`
  - `docs/briefings/gtv/solids/evidence-02-wan-edge-hybrid-connectivity.md`
  - `docs/briefings/gtv/solids/evidence-03-source-of-truth-netbox-automation.md`
  - `docs/briefings/gtv/solids/evidence-04-delivery-platform-gitops-cluster-operations.md`
  - `docs/briefings/gtv/solids/evidence-05-documentation-teaching-community.md`
  - `docs/briefings/gtv/solids/evidence-06-teaching-public-content.md` *(future)*  
  - `docs/briefings/gtv/solids/evidence-10-public-adoption-external-recognition.md` *(future)*

Think of the **solids** as the technical backbone and the **MC/OC1/OC2 files** as the polished 2–3 page slices Tech Nation actually sees.

---

### 2.2 Drafting rules for all evidence slots

- **Length**
  - Each Tech Nation evidence PDF should be **max 3 pages**.
  - Aim for ~900–1,200 words per slot once diagrams and screenshots are inserted.

- **Placeholders**
  - While drafting in Markdown, use explicit placeholders where visuals will go:
    - `[IMG-01 – <short description> – ~6 lines]`
    - `[ART-01 – <code / JSON snippet> – ~6 lines]`
    - `[VID-01 – <video thumbnail + URL> – ~4 lines]`
  - Treat each placeholder as occupying roughly the given number of lines when you later export to PDF.

- **Framing**
  - Always refer to HybridOps.Studio as a **“hybrid platform blueprint and reference implementation”**, not a homelab.
  - **MC slots**: emphasise *trajectory* and *recognition* (HybridOps.Studio, academics, Latymer, future plans).
  - **OC1 slots**: emphasise *innovation and depth* (network, SoT, delivery, DR, cost).
  - **OC2 slots**: emphasise *teaching, docs, open source, community and public impact*.

- **Evidence wiring**
  - Each slot should explicitly reference the relevant **solid(s)** and any key ADRs / HOWTOs / runbooks / CI docs.
  - If a solid changes, update the references in the corresponding MC/OC1/OC2 slot and in `gtv_cover_sheet.md`.

---

### 2.3 How to work day-to-day

1. **Write only in these files** for Tech Nation evidence:  
   `docs/briefings/gtv/MC/*.md`, `docs/briefings/gtv/OC1/*.md`, `docs/briefings/gtv/OC2/*.md`.
2. Use `gtv_cover_sheet.md` to check:
   - Which criteria a slot is supporting.
   - Whether the one-line impact statement still matches the narrative.
3. When ready to export:
   - Replace `[IMG-XX]` / `[ART-XX]` / `[VID-XX]` with real diagrams and screenshots.
   - Trim to 3 pages and sanity-check against Tech Nation’s wording for MC / OC1 / OC2.

---

## 3. How to Use This Workspace

1. **Write and iterate in these Markdown files**  
   - Treat each file under `MC/`, `OC1/`, `OC2/` as the working source.  
   - Keep headings and rhythm consistent so all evidence “reads like one pack”.

2. **Use `[IMG-XX]` and `[ART-XX]` placeholders**  
   - When you know a diagram, screenshot or artefact belongs in a section, insert a placeholder line, for example:  
     - `[IMG-02 – Screenshot of pfSense dual WAN status – ~6 lines]`  
   - Later, when generating PDFs, replace these with real visuals.

3. **Respect length (2–3 pages each when PDF’d)**  
   - When converting to PDF, trim or tighten if any slot goes far beyond 3 pages.  
   - Prioritise clarity and impact over including every possible detail.

4. **Wire up links to real artefacts**  
   - As you create more ADRs, HOWTOs, runbooks and proof folders, update each slot to reference actual paths, for example:  
     - `docs/adr/ADR-0604-packer-image-pipeline-proxmox-templates.md`  
     - `docs/howtos/HOWTO_dr_cost_drill.md`  
     - `docs/proof/dr/...`, `docs/proof/cost/...`.

5. **Keep the “blueprint” framing consistent**  
   - Refer to HybridOps.Studio as a **hybrid platform blueprint and reference implementation**, not as a “homelab” or “personal project”.  
   - Emphasise reusability for startups, engineering teams and teaching.

---

## 4. Next Steps Checklist (High-Level)

- [ ] Review each evidence file for tone and consistency (no “homelab”, no underselling).  
- [ ] Identify and create the key diagrams needed for `[IMG-XX]` / `[ART-XX]` placeholders.  
- [ ] Ensure ADR/HOWTO/runbook references match real files in `docs/`.  
- [ ] For **OC2 Slot 6–8**, line up and polish public-facing pieces (GitHub, docs portal, videos/posts) so screenshots and URLs are ready.  
- [ ] For **OC2 Slot 10**, publish and exercise Ansible Galaxy collections and capture download / feedback metrics.  
- [ ] For **MC Slot 9**, keep emails/reference and script snippets organised for redacted screenshots.  
- [ ] When ready to apply, export each slot as a PDF and cross-check against Tech Nation’s criteria wording and page limits.

This `docs/briefings/gtv/` folder is the **control panel** for your application narrative: it tells you which story each evidence slot is responsible for and how they fit together into a coherent picture.

# HybridOps.Studio – Evidence Packs (Working Guide)

This is a **private working guide** to keep all evidence packs consistent.  
It is not itself submitted, but each evidence document should broadly follow it.

This guide is mainly for the **deep technical “solids”** under `docs/evidence/solids/`.  
Tech Nation PDFs are shorter (2–3 pages) and slice *from* these solids.

---

## 1. Purpose of Evidence Packs

Each pack should:

- Tell a **clear story** about one big theme (e.g. networking core, automation, DR).  
- Prove that the work is **real, repeatable, and operated like an enterprise system**, not a hobby lab.  
- Make it easy for assessors and reviewers to jump out to live artefacts (docs site, GitHub, video demos).  

Think of each evidence pack as:

> “A guided tour of one slice of HybridOps.Studio, with links and screenshots that prove what I’m claiming.”

Tech Nation evidence PDFs will then be **compressed versions** of these packs.

---

## 2. Recommended Structure (per Evidence Pack)

Target length for a full “solid”: **4–8 pages once screenshots are added**.

1. **Executive Summary** (short, narrative)  
   - What this evidence is about.  
   - 4–5 bullets on what it demonstrates (architecture, practice, impact).  

2. **Architecture / Concept Overview**  
   - 1–2 diagrams or annotated topology views.  
   - A short narrative on *why* the design looks like this (not just “what”).  

3. **Demo Video (Walk-Through)**  
   - A short section explicitly pointing to a **demo video**.  
   - In MkDocs, embed via `??? info` block + `<iframe>`.  
   - In PDF, just include the YouTube link and/or docs page link.  

4. **Key Design Decisions (ADRs)**  
   - 4–8 bullets, 1–2 lines each.  
   - Each bullet references an ADR id and summarises the decision.  
   - Full ADR links live in the “Links & Artefacts” section.  

5. **Implementation Highlights**  
   - 2–4 sub-sections with “representative slices” of implementation:  
     - Config snippets (Terraform, Ansible, pfSense, Jenkinsfile, etc.).  
     - How pieces fit together (pfSense + Proxmox + RKE2, Packer + Terraform + Ansible, Jenkins + GitHub Actions).  
   - Keep them **glanceable** – don’t paste full files; show small, focused excerpts.

6. **Validation & Evidence**  
   - Concrete proofs that it works and is operated properly:  
     - CLI screenshots (ping, curl, kubectl, terraform plan/apply).  
     - Packet/flow evidence where relevant.  
     - Grafana / Prometheus screenshots to show metrics and labels.  
     - Output snippets from Ansible / Nornir runs.  
   - Link or mention **runbooks/HOWTOs** that a second engineer could follow.

7. **Links & Artefacts**  
   - Clear, grouped links to:  
     - Docs site (MkDocs) pages.  
     - ADR pages.  
     - GitHub source directories and key files.  

You can shuffle the order slightly (e.g. put “Demo Video” after “Architecture”), but keep these ingredients.

---

## 3. Style & Tone

### 3.1 Voice

- Confident but not hypey.  
- Matter-of-fact and **evidence-oriented** (“this is how it’s built and how we prove it”).  
- No “homelab” language – always frame as an **enterprise-style hybrid platform blueprint**.  

### 3.2 Formatting

- Use standard Markdown headings (`##`, `###`).  
- Use bullet lists liberally for readability.  
- Use blockquotes for **placeholders** (e.g. “Insert diagram here”, “Screenshot of Grafana”).  
- Use fenced code blocks for short config examples; avoid full files.  

### 3.3 Links and Referencing

We have three types of links:

1. **Docs site (MkDocs)** – primary for readers  
   - Use descriptive text + URL, for example:  
     - `[Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/)`  
     - `[ADR-0101 – VLAN Allocation Strategy](https://docs.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)`  
   - These are the **main links assessors will click**.  

2. **GitHub (source code & markdown)**  
   - Also use descriptive text, not raw paths:  
     - `[HybridOps.Studio – Repository Root](https://github.com/jeleel-muibi/hybridops-studio)`  
     - `[Network Architecture – Markdown Source](https://github.com/jeleel-muibi/hybridops-studio/blob/main/docs/prerequisites/network-architecture.md)`  
     - `[Terraform – Proxmox Modules](https://github.com/jeleel-muibi/hybridops-studio/tree/main/infra/terraform/modules/proxmox)`  
   - Keep this section short: 3–6 links is enough per pack.  

3. **Bare paths (for orientation only)**  
   - Use inline code style when you want to show structure, e.g.:  
     - ``docs/adr/ADR-0101-vlan-allocation-strategy.md``  
     - ``infra/terraform/modules/proxmox/``  
   - These are **not** clickable; they are for people browsing the repo.  
   - Do not turn bare paths into `[]()` with the same text – that adds no value.

General rules:

- If ADRs or HOWTOs are mentioned in context (e.g. in “Context” or “Key Decisions”), keep those references **light** (ID + name).  
- The **“Links & Artefacts”** section is the main place for full MkDocs + GitHub links.  
- Avoid listing the same URL in multiple sections unless there’s a very strong reason.

### 3.4 Placeholders

Because PDFs will include screenshots and diagrams that don’t exist yet, use clear placeholders:

- `> **Diagram placeholder – …**`  
- `> **Screenshot placeholder – …**`  
- `> **Dashboard placeholder – …**`  
- `> **Code snippet placeholder – …**`  

This keeps the writing flowing without blocking on visuals.

---

## 4. Demo Video Pattern

Every evidence pack should have **one primary demo video** (more are optional).

Pattern:

- Section: **“Demo Video (Walk-Through)”** – usually section 3.  
- Text: 2–4 lines describing what the viewer will see.  
- Links:  
  - A docs link where the video is embedded:  
    - e.g. `https://docs.hybridops.studio/evidence/networking/hybrid-network-core-demo/`  
  - A direct YouTube link for the PDF:  
    - e.g. `https://www.youtube.com/watch?v=YOUR_VIDEO_ID`  

In MkDocs, use something like:

```markdown
??? info "▶ Watch the hybrid network core demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="HybridOps.Studio – Hybrid Network Core Demo"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }
```

For PDFs, you only need the text + links; the iframe is for the docs site.

---

## 5. Redundancy & Cross-Referencing

To keep things tight and non-repetitive:

- “Context” / “Architecture” sections may mention ADR IDs and names, but **not** full URLs.  
- “Key Design Decisions (ADRs)” summarises what each ADR says in 1–2 lines.  
- “Links & Artefacts” is where you list full MkDocs + GitHub links.  

You do **not** need to show every ADR + HOWTO + runbook in every pack.  
Instead, pick the ones that actually support the story of that evidence.

If in doubt, ask:

> “Does this link help them verify a claim I just made?”  
> If not, drop it.

---

## 6. Ownership & Licensing Footer

Each evidence pack should end with:

```markdown
---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC BY 4.0 for documentation
```

This keeps branding consistent and makes it clear that the artefacts are intentionally open.

---

## 7. Quick Checklist Before Exporting to PDF

- [ ] Executive summary clearly states what this evidence demonstrates.  
- [ ] Architecture section has at least one diagram placeholder or real diagram.  
- [ ] Demo section is present with clear video links.  
- [ ] Key ADRs are summarised in 1–2 lines each.  
- [ ] Implementation highlights show real config/code, but only small, focused excerpts.  
- [ ] Validation section has concrete checks (CLI, dashboards, logs).  
- [ ] Links are grouped cleanly in “Links & Artefacts” and use descriptive text.  
- [ ] Footer uses the standard HybridOps.Studio owner + license block.

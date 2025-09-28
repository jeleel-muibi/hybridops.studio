# Documentation Index — HybridOps.Studio

This folder hosts the documentation that backs the **Architecture Overview** and all related proof.
If you're here to **verify claims**, start with the **Evidence Map**. If you're here to **edit diagrams**, see **Diagrams**.
For security and operational maturity plans, see **Guides → SecOps roadmap**.

## Quick Links
- **Repository README (executive overview):** `../README.md`
- **Evidence Map (claims → proof links):** `./evidence_map.md`
- **Network Design (Mermaid + narrative):** `./network-design.md`
- **SecOps Roadmap** — planned upgrades & maturity goals: `./guides/secops-roadmap.md`
- **License for docs/diagrams:** `./license-docs.md` (CC BY 4.0)

---

## Structure

```
docs/
├── case-studies/                         # Narrative proof & deep dives
│   └── bsc-nornir.md
├── diagrams/
│   ├── flowcharts/                       # draw.io sources + notes
│   │   ├── diagram_brief.md
│   │   ├── architecture-overview.drawio
│   │   └── renders/
│   │       └── architecture-overview.png
│   └── mermaid/                          # GitHub-friendly Mermaid sources
│       └── architecture-overview.mmd
├── evidence_map.md                       # Canonical claims → proof tables
├── guides/                               # Roadmaps & non-tutorial guides
│   └── secops-roadmap.md
├── license-docs.md                       # CC BY 4.0 for docs/diagrams
├── network-design.md                     # Hub-and-spoke design + Mermaid
└── README.md                             # You are here
```

---

## Evidence Map

Use **`evidence_map.md`** to map each public claim (KPIs, architecture assertions) to direct proof:
- Link **directly** to a Grafana panel, CI run, or config — avoid homepages.
- Add a **timestamp** in link text when helpful (e.g., *Terraform Apply — 2025‑09‑18 14:22 UTC*).
- Prefer URLs over screenshots; add screenshots only when a link requires authentication.

---

## Diagrams

### Flowcharts (draw.io)
- **Source**: `diagrams/flowcharts/*.drawio`
- **Renders**: `diagrams/flowcharts/renders/*.png`
- **Briefs/notes**: `diagrams/flowcharts/diagram_brief.md`

**Export guidance**
- Export width: **3840 px** (4K) PNG for overview diagrams.
- Keep embedded icons as SVGs inside the `.drawio` to ensure crisp exports.
- Snap to grid and keep **hub & cluster grouping** consistent to avoid visual clutter.

### Mermaid
- **Source**: `diagrams/mermaid/*.mmd` (renders inline on GitHub).
- Use labels sparingly and prefer **clusters/subgraphs** for readability.

---

## Guides

Use `guides/` for **roadmaps and standards** (not tutorials). Start here:
- `guides/secops-roadmap.md` — planned security/ops maturity upgrades for HybridOps.Studio.

---

## Case Studies

Use `case-studies/` for narrative, reproducible stories (e.g., Nornir automation, DR runbooks):
- Keep each case study **1–2 pages** with a short **Outcome** section and **Steps to replicate**.
- Link to the Evidence Map entry and code paths wherever possible.

---

## Conventions

- **File naming**: `architecture-overview.*` for the primary diagram; add view suffixes only if needed (`-exec`, `-tech`).
- **Timestamps**: Use **UTC** in screenshots and link text.
- **References**: Prefer relative links within the repo.
- **Licensing**: All content here is **CC BY 4.0** (see `license-docs.md`); vendor logos are trademarks (see repository `NOTICE`).

---

_Last updated: 2025-09-24 08:17 UTC

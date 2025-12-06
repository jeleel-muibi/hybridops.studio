# Evidence Slot 10 – Public Adoption & External Recognition (OC2)

> **Criteria:** Optional Criteria 2 (OC2) – contributions outside employment (external adoption and recognition).  
> **Also supports:** Mandatory Criterion (MC) and OC1 as external validation of technical work.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final screenshots before submission.

---

## 1. Summary – From Blueprint to External Use

This evidence shows how elements of HybridOps.Studio move beyond a private blueprint into **external adoption and recognition**, through:

- **Ansible Galaxy collections** extracted from the platform.  
- **Usage metrics** (downloads, stars, feedback).  
- Any **external references** (issues, comments, posts) that show other engineers are using or learning from this work.

The emphasis is on **real-world uptake**: other people pulling these roles and patterns into their own environments.

[IMG-01 – Screenshot of Ansible Galaxy profile / main collection page – ~6 lines]

---

## 2. Context – Why Collections and Reusable Patterns

HybridOps.Studio is designed as a **reusable hybrid platform blueprint**. A natural extension of this is to package some of the key roles as **Ansible collections**, so that:

- Other teams can reuse baseline patterns without cloning the entire repo.  
- Behaviour can be tested and versioned independently via CI.  
- You can track **usage over time** via download metrics.

Typical candidates for extraction include:

- **RKE2 / Kubernetes bootstrap roles**.  
- **Connectivity / DR drill roles** (e.g., “Connectivity Test / Env Guard”).  
- **Baseline hardening or platform setup roles** used frequently across environments.

[IMG-02 – Screenshot of GitHub repo section where roles live, showing README / structure – ~6 lines]

---

## 3. Ansible Galaxy Collections – What’s Published and How They’re Used

Describe the collections you publish, for example:

### 3.1 Collection A – HybridOps.RKE2 (example name)

- **Purpose:** Install and bootstrap **RKE2** clusters with sane defaults for small hybrid platforms, aligned with HybridOps.Studio.  
- **Contents:** Roles for server/agent install, basic config, optional Longhorn or CNI hooks.  
- **Quality signals:**
  - CI pipeline with **Molecule tests** against representative OS images.  
  - Tagged releases (`v0.x`, `v1.0`) with clear changelog.

- **Usage / metrics (example framing):**
  - `<N>` total downloads (at time of application).  
  - `<N>` stars / watches on GitHub if mirrored.  
  - Any notable issues or PRs from external users.

[IMG-03 – Screenshot of this collection’s Galaxy page with download count and version list – ~6 lines]

### 3.2 Collection B – HybridOps.EnvGuard (example name)

- **Purpose:** Implement the **“Connectivity Test / Env Guard”** pattern used in HybridOps.Studio, so teams can run pre-flight checks before deployments or DR drills.  
- **Contents:** Roles to:
  - Run connectivity checks across environments (on-prem, cloud).  
  - Emit structured results and risk scores.  
  - Optionally integrate with CI/CD (Jenkins, GitHub Actions) as a gating step.

- **Usage / metrics:**
  - `<N>` downloads.  
  - Any external feedback or forks that indicate adoption.

[IMG-04 – Screenshot of EnvGuard collection page or repo, showing README and usage examples – ~6 lines]

---

## 4. External Feedback, References and Engagement

Summarise any **external signals** that show this work is landing:

- GitHub issues or discussions from other engineers asking how to use or extend the roles.  
- Comments on posts or videos specifically mentioning the roles/collections.  
- Mentions in other repos or blog posts (if any).

You don’t need huge numbers; the key is to show **real people** using or engaging with the artefacts, for example:

- A user opening an issue: “Used this RKE2 role to stand up a small lab cluster; here’s what worked / what I changed.”  
- A comment on LinkedIn or YouTube: “This Env Guard pattern is exactly what we needed before running risky changes.”

[IMG-05 – Screenshot of a representative issue/comment (redacted) mentioning your collection – ~6 lines]

---

## 5. Future Growth – Scaling Adoption and Community Use

Briefly describe how you plan to **grow** this over time:

- Improving docs and examples for collections (e.g. `examples/` folder with small lab scenarios).  
- Referencing collections explicitly from:
  - `docs.hybridops.studio` HOWTOs and showcases.  
  - HybridOps Academy materials (so students learn using the same artefacts).  
- Possibly adding:
  - More specialised roles (e.g. DR drills, cost checks, connectivity baselines).  
  - Tags and keywords so collections are easy to discover for target audiences.

[IMG-06 – Screenshot of a HOWTO or docs page that references an Ansible Galaxy collection – ~6 lines]

---

## 6. How This Meets Optional Criteria 2 (and Supports MC/OC1)

This evidence supports **OC2** by showing that:

- I am **packaging real platform patterns** (not toy examples) as reusable collections.  
- Other engineers can and do **consume** these artefacts via a standard public channel (Ansible Galaxy).  
- I track adoption and iterate based on feedback, not just publishing once and forgetting.

It also indirectly supports **MC and OC1** because:

- External adoption is a **signal of technical credibility** (MC).  
- Exporting patterns like Env Guard and RKE2 bootstrap demonstrates that HybridOps.Studio’s patterns are **robust and general enough to be reused** (OC1).

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.

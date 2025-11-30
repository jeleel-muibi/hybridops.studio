---
title: "HOWTO – Build and Preview Public and Academy Docs"
category: "platform"
summary: "Step-by-step guide for generating and locally previewing the public and academy documentation sites."
difficulty: "Intermediate"

topic: "docs-build-and-preview"

video: ""
source: "https://github.com/hybridops-studio/hybridops-studio/tree/main/control/tools/docs"

draft: false
is_template_doc: false
tags: ["docs", "mkdocs", "platform"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO – Build and Preview Public and Academy Docs

**Purpose:** Show how to generate the audience-specific doc trees and static sites, and preview them locally.  
**Difficulty:** Intermediate  
**Prerequisites:**  
- HybridOps.Studio repo cloned.
- Python and virtualenv (or equivalent) available.
- `mkdocs` and `mkdocs-material` installed in the environment used for builds.
- Able to run `make` from the repo root.

---

## Demo (optional)

If you record a short walkthrough later, link it here.

- Demo: *(TBD)*  
- Source: [Docs tooling](https://github.com/hybridops-studio/hybridops-studio/tree/main/control/tools/docs)

---

## Context

The documentation system produces two audience-specific sites from a single `docs/` tree:

- **Public docs** – for GitHub visitors, assessors, and hiring managers.
- **Academy docs** – for HybridOps Academy learners.

The build pipeline:

1. Scans `docs/` and generates ADR, HOWTO, runbook, CI and showcase indexes.
2. Applies the access/stub model to build:

   - `deployment/build/docs/public`
   - `deployment/build/docs/academy`

3. Generates MkDocs configs and builds static sites:

   - `deployment/build/site/docs-public`
   - `deployment/build/site/docs-academy`

This HOWTO walks through those steps and how to preview the result.

---

## Steps

### 1. Activate the environment

From the repo root:

```bash
cd /home/user/hybridops-studio

# If using a virtualenv:
source .venv/bin/activate
```

Confirm `mkdocs` is available:

```bash
mkdocs --version
```

Expected: `mkdocs` reports a version and exits with status 0.

---

### 2. Generate indexes and audience-specific doc trees

Run the docs preparation target:

```bash
make docs.prepare
```

What this does:

- Runs index generators under `control/tools/docs/indexing/`.
- Applies the access/stub model with:

  - `control/tools/docs/mkdoc/build_generator/stub_filter.py`

- Produces the audience-specific trees:

  - `deployment/build/docs/public`
  - `deployment/build/docs/academy`

- Generates MkDocs configs via:

  - `control/tools/docs/mkdoc/build_generator/build_mkdocs_trees.py`

Expected results:

- No errors in the terminal.
- The paths above exist and contain Markdown trees filtered by audience.
- New configs appear under `control/tools/docs/mkdoc/`:

  - `mkdocs.public.yml`
  - `mkdocs.academy.yml`

---

### 3. Build the public and academy sites

From the repo root:

```bash
make docs.build
```

This runs:

- `mkdocs build -f control/tools/docs/mkdoc/mkdocs.public.yml`
- `mkdocs build -f control/tools/docs/mkdoc/mkdocs.academy.yml`

Expected results:

- `deployment/build/site/docs-public` contains `index.html` and the docs structure.
- `deployment/build/site/docs-academy` contains `index.html` and the docs structure.
- MkDocs reports “Documentation built” for both configs.

---

### 4. Serve the built sites locally

For a simple static preview, use Python’s HTTP server.

Public docs:

```bash
python -m http.server --directory deployment/build/site/docs-public 8000
# Browse to http://127.0.0.1:8000
```

Academy docs (second terminal):

```bash
python -m http.server --directory deployment/build/site/docs-academy 8001
# Browse to http://127.0.0.1:8001
```

Expected results:

- Public site at `http://127.0.0.1:8000` shows public docs with stubs where appropriate.
- Academy site at `http://127.0.0.1:8001` shows full academy content.

---

### 5. Live reload with MkDocs (optional)

For development, use `mkdocs serve` with the generated configs:

```bash
mkdocs serve -f control/tools/docs/mkdoc/mkdocs.public.yml -a 127.0.0.1:8000
mkdocs serve -f control/tools/docs/mkdoc/mkdocs.academy.yml -a 127.0.0.1:8001
```

Expected results:

- Local servers with automatic rebuild when you edit `docs/`.
- Navigation and audience behaviour matching the static builds.

---

## Validation

- `make docs.prepare` and `make docs.build` complete without errors.
- `deployment/build/docs/public` and `deployment/build/docs/academy` exist and contain filtered trees.
- `deployment/build/site/docs-public/index.html` and `deployment/build/site/docs-academy/index.html` exist.
- Public site:
  - Shows full content for `access: public`.
  - Shows stubs for `access: academy` where configured.
- Academy site:
  - Shows full content for both public and academy documents.

For formal evidence, capture:

- A short screen recording of building and browsing both sites.
- Screenshots of ADR/runbook/HOWTO indices and at least one stubbed academy page.

---

## Troubleshooting

- **Issue:** `mkdocs` not found.  
  **Cause:** Environment not activated or `mkdocs` not installed.  
  **Fix:** Activate the virtualenv or install MkDocs:

  ```bash
  pip install mkdocs mkdocs-material
  ```

- **Issue:** Build fails with link warnings only.  
  **Cause:** Missing HOWTO/runbook/diagram referenced by existing docs.  
  **Fix:** Create the referenced file or update/remove the link. Warnings do not block the build unless `strict: true` is set.

- **Issue:** `'bool' object has no attribute 'split'` during MkDocs build.  
  **Cause:** `template:` front-matter field set to `true`/`false` instead of a template name.  
  **Fix:** Remove `template:` or rename it to `is_template_doc:` and set `true`/`false`.

- **Issue:** Public and academy sites look identical.  
  **Cause:** No documents marked with `access: academy` or stubs not enabled.  
  **Fix:** Review ADR-0021/ADR-0022 and front matter of selected documents.

---

## References

- [ADR-0021 – Documentation Access and Gating Model](../adr/ADR-0021-docs-access-model.md)  
- [ADR-0022 – Documentation, Public Site, and Academy Strategy](../adr/ADR-0022-docs-and-academy-strategy.md)  
- Docs tooling overview: `../guides/docs-tooling-overview.md` (if present)  
- [Evidence Map](../evidence_map.md)

---

**Author:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

---
title: "Runbook – Build and Clean Documentation Sites (Public and Academy)"
category: "platform"
summary: "Operational procedure for building, validating, and cleaning the public and academy documentation sites."
severity: "P3"

topic: "docs-build-and-clean"

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

# Runbook – Build and Clean Documentation Sites (Public and Academy)

**Purpose:** Ensure the public and academy documentation sites are built correctly, recover from build failures, and clean derived artefacts when needed.  
**Owner:** Platform / Documentation Tooling  
**Trigger:**  
- Scheduled docs refresh.  
- After significant ADR/runbook/HOWTO changes.  
- Following a failed docs build in CI.  
**Impact:**  
- Public docs availability and correctness at `docs.hybridops.studio` (or equivalent).  
- Academy docs availability for learners and assessors.  
**Severity:** P3 (non-critical, but important for portfolio and Academy operations).  
**Pre-reqs:**  
- Repo access and ability to run `make`.  
- Correct Python environment with MkDocs installed.  
- Access to CI logs if debugging CI failures.  
**Rollback strategy:**  
- Revert the documentation changes that introduced the failure and rebuild.  
- If needed, redeploy the last known good docs artefacts from CI or backup.

---

## Context

The documentation build pipeline produces:

- Audience-specific doc trees:

  - `deployment/build/docs/public`
  - `deployment/build/docs/academy`

- Static sites:

  - `deployment/build/site/docs-public`
  - `deployment/build/site/docs-academy`

This runbook standardises how platform engineers:

- Run the build.
- Validate results.
- Clean and recover when generated artefacts become inconsistent or corrupted.

---

## Preconditions and safety checks

Before running the steps:

- Confirm you are in the correct repository and branch:

  ```bash
  git status
  ```

- Ensure the Python environment is active and has MkDocs:

  ```bash
  mkdocs --version
  ```

- If responding to a CI failure, open the failing job logs and identify:

  - Which command failed (`docs.prepare`, `docs.build`, or a direct `mkdocs` invocation).
  - Any specific error messages (e.g. front-matter issues, missing templates).

- If you plan to clean generated artefacts, confirm no one is currently deploying from `deployment/build/` manually.

---

## Steps

1) **Run the docs preparation stage**

   - Action: Generate indexes, apply the access model, and create audience-specific doc trees.

   - Command:

     ```bash
     make docs.prepare
     ```

   - Expected result:

     - Command exits with status 0.
     - `deployment/build/docs/public` and `deployment/build/docs/academy` exist and contain filtered trees.
     - `control/tools/docs/mkdoc/mkdocs.public.yml` and `mkdocs.academy.yml` are present.

   - Evidence:  
     - Save terminal output to `output/artifacts/docs/<timestamp>_docs_prepare.log` if running as part of a formal change.

2) **Build the public and academy sites**

   - Action: Run MkDocs builds for both audiences.

   - Command:

     ```bash
     make docs.build
     ```

   - Expected result:

     - MkDocs reports a successful build for both configs.
     - `deployment/build/site/docs-public/index.html` exists.
     - `deployment/build/site/docs-academy/index.html` exists.

   - Evidence:  
     - Save build logs to `output/artifacts/docs/<timestamp>_docs_build.log`.

3) **Local spot-check of public and academy sites**

   - Action: Perform a quick local validation.

   - Command (optional local preview):

     ```bash
     python -m http.server --directory deployment/build/site/docs-public 8000
     python -m http.server --directory deployment/build/site/docs-academy 8001
     ```

   - Expected result:

     - Public site shows content for a sample ADR, runbook, and HOWTO.
     - Academy site shows the same plus any academy-only content where configured.

   - Evidence:  
     - Capture screenshots of key pages and attach to the relevant ticket or change record.

4) **Clean generated documentation artefacts (when required)**

   - Action: Remove all generated documentation artefacts to recover from inconsistent or corrupted state.

   - Command:

     ```bash
     make clean.generated.docs
     ```

   - Expected result:

     - Generated index READMEs and `000-INDEX.md` files are removed from:

       - `docs/adr`, `docs/runbooks`, `docs/howto`, `docs/ci`, `docs/showcases`.

     - Generated `by-*` views are removed from the same areas.
     - `deployment/build/docs` is removed.
     - `deployment/build/site/docs-public` and `deployment/build/site/docs-academy` are removed.
     - `control/tools/docs/mkdoc/mkdocs.public.yml` and `mkdocs.academy.yml` are removed.

   - Evidence:  
     - Optionally capture `tree deployment/build` before and after to show clean-up.

5) **Rebuild after clean**

   - Action: Recreate all documentation artefacts from source.

   - Command:

     ```bash
     make docs.prepare
     make docs.build
     ```

   - Expected result:

     - Documentation build pipeline completes cleanly.
     - Trees and sites are recreated as in steps 1 and 2.

   - Evidence:  
     - Updated logs in `output/artifacts/docs/` if this is part of a tracked incident or change.

---

## Verification

Success criteria:

- `make docs.prepare` and `make docs.build` complete without errors.
- Public and academy sites are reachable in local preview and/or via the deployed URLs.
- Spot-checks of ADR, runbook, and HOWTO indices show:

  - Public content available as expected.
  - Academy-only content represented correctly (as stubs in public, full content in academy).

For formal verification:

- Update associated change or incident tickets with:

  - Build log locations.
  - Screenshots or recordings.
  - Any deviations or follow-ups required.

---

## Post-actions and clean-up

- Stop any local HTTP servers or `mkdocs serve` processes used during validation.
- If the runbook was triggered by a CI failure:

  - Update the CI ticket with root cause and resolution.
  - If the cause was a documentation content issue, link to the fixing commit.

- If this runbook is used during a release:

  - Confirm release notes and documentation pointers reference the updated docs site.
  - Archive key artefacts under `docs/proof/docs-build/` if part of a formal evidence set.

---

## References

- [HOWTO – Build and Preview Public and Academy Docs](../../howto/HOWTO_docs_build_and_preview.md)  
- [ADR-0021 – Documentation Access and Gating Model](../../adr/ADR-0021-docs-access-model.md)  
- [ADR-0022 – Documentation, Public Site, and Academy Strategy](../../adr/ADR-0022-docs-and-academy-strategy.md)  
- [Evidence Map](../../evidence_map.md)

---

**Author:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

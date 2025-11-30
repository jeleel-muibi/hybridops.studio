# Documentation tooling

This directory contains the documentation tooling for HybridOps.Studio. It is responsible for generating documentation indexes, applying the access model, producing audience-specific doc trees, and generating MkDocs configuration files for the documentation sites.

This directory is intended for maintainers and platform engineers. Readers of the published documentation do not need to interact with it directly.

## Layout

```text
control/tools/docs
├── indexing/
│   ├── _index_utils.py
│   ├── gen_adr_index.py
│   ├── gen_ci_index.py
│   ├── gen_howto_index.py
│   ├── gen_runbook_index.py
│   └── gen_showcase_index.py
├── mkdoc/
│   ├── build_generator/
│   │   ├── build_mkdocs_trees.py
│   │   └── stub_filter.py
│   ├── mkdocs.base.yml
│   ├── mkdocs.public.yml   # generated
│   └── mkdocs.academy.yml  # generated
└── README.md
```

### indexing/

Index generators and shared helpers.

- `_index_utils.py`  
  Shared utilities for loading markdown files, parsing front matter, and applying common skip rules.

- `gen_adr_index.py`  
  Builds ADR index pages and updates ADR-related README content.

- `gen_ci_index.py`  
  Builds index pages for CI/CD documentation.

- `gen_howto_index.py`  
  Builds index pages and topic views for HOWTO content.

- `gen_runbook_index.py`  
  Builds index pages and category views for runbooks.

- `gen_showcase_index.py`  
  Builds the showcase catalogue and by-audience views under `docs/showcases/`, based on showcase front matter (for example access, audience, tags, and academy metadata).

Each generator scans the `docs/` tree, reads front matter (for example `id`, `title`, `access`, `domains`, `category`, `audience`), and produces index files and structured views (such as `by-domain`, `by-category`, `by-topic`, or `by-audience`). Generators may also update selected `README.md` files between well-defined marker comments.

Files that are templates, drafts, or otherwise excluded from public consumption are filtered by the shared rules in `_index_utils.py`.

### mkdoc/

MkDocs configuration and audience-aware doc tree generation.

- `mkdocs.base.yml`  
  Base MkDocs configuration shared by all documentation variants. It defines theme, plugins, navigation skeleton, repository metadata and other defaults.

- `build_generator/stub_filter.py`  
  Applies the documentation access model and produces audience-specific doc trees under `deployment/build/docs`:

  - `deployment/build/docs/public`  
    Documentation tree for public readers.

  - `deployment/build/docs/academy`  
    Documentation tree for academy learners.

  Front matter is used to determine access and behaviour:

  - `access: public`  
    Included in both public and academy trees.

  - `access: academy`  
    Included in the academy tree; a stub page is generated for the public tree.

  - `access: internal`  
    Excluded from both public and academy trees.

  When stubbing academy-only content for the public tree, optional `stub` metadata can be used:

  - `stub.blurb` – short description rendered on the public stub page.
  - `stub.highlights` – bullet list of key points.
  - `stub.cta_url` – link to academy or related resources.
  - `stub.cta_label` – link label.

- `build_generator/build_mkdocs_trees.py`  
  Generates MkDocs configuration files for the documentation sites from `mkdocs.base.yml` and the audience-specific doc trees.

  Outputs:

  - `control/tools/docs/mkdoc/mkdocs.public.yml`  
    Configured to build the public documentation site from `deployment/build/docs/public` into `deployment/build/site/docs-public` with audience metadata `public`.

  - `control/tools/docs/mkdoc/mkdocs.academy.yml`  
    Configured to build the academy documentation site from `deployment/build/docs/academy` into `deployment/build/site/docs-academy` with audience metadata `academy`.

  Navigation placeholders in `mkdocs.base.yml` (such as `__HOWTO_TOPICS__`, `__RUNBOOK_CATEGORIES__`, `__ADR_DOMAINS__`, and showcase audience placeholders) are expanded at generation time using the index outputs under `docs/`.

## Build flow for documentation sites

From the repository root, documentation artefacts are produced in two stages using the main `Makefile`.

### 1. Prepare documentation trees and MkDocs configs

```bash
make docs.prepare
```

This target performs the following steps:

1. Runs all active index generators in `control/tools/docs/indexing/` (ADR, HOWTO, runbooks, CI/CD, showcases).
2. Applies the access model with `stub_filter.py` to build:

   - `deployment/build/docs/public`
   - `deployment/build/docs/academy`

3. Generates audience-specific MkDocs configurations with `build_mkdocs_trees.py`:

   - `control/tools/docs/mkdoc/mkdocs.public.yml`
   - `control/tools/docs/mkdoc/mkdocs.academy.yml`

### 2. Build static documentation sites

```bash
make docs.build
```

This target uses MkDocs to build the static sites into `deployment/build/site`:

- `deployment/build/site/docs-public`  
  Public documentation site.

- `deployment/build/site/docs-academy`  
  Academy documentation site.

These directories are suitable for publication behind a web server or reverse proxy, for example under `/docs/` and `/academy/` paths or separate hostnames.

### 3. Clean generated documentation artefacts

```bash
make clean.generated.docs
```

This target removes generated documentation artefacts, including:

- Index READMEs and `000-INDEX.md` files in `docs/adr`, `docs/runbooks`, `docs/howto`, and `docs/ci`.
- Generated `by-*` views under `docs/adr`, `docs/runbooks`, `docs/howto`, `docs/ci`, and `docs/showcases` (for example by-domain, by-category, by-topic, by-audience).
- Audience-specific doc trees under `deployment/build/docs`.
- Generated MkDocs configuration files under `control/tools/docs/mkdoc/` (`mkdocs.public.yml`, `mkdocs.academy.yml`).
- Static documentation sites under `deployment/build/site/docs-public` and `deployment/build/site/docs-academy`.

The clean target is safe to run at any time. A subsequent `make docs.prepare` and `make docs.build` will fully recreate the documentation artefacts.

## Maintenance

- Index generators and mkdoc builders are part of the platform tooling. Changes should be made in this directory and tested locally with `make docs.prepare` and `make docs.build`.
- The directories under `deployment/build/docs` and `deployment/build/site` are derived artefacts and may be safely removed and regenerated.
- New documentation types (for example additional index views or audience variants) should extend the existing generators and MkDocs build process rather than introduce ad-hoc scripts.

## Related documentation

For step-by-step operational procedures and user-facing guidance, see:

- [HOWTO – Build and Preview Public and Academy Docs](../../../docs/howto/HOWTO_docs_build_and_preview.md)
- [Runbook – Build and Clean Documentation Sites (Public and Academy)](../../../docs/runbooks/platform/docs-build-and-clean.md)

Design rationale and access strategy are documented in:

- [ADR-0021 – Documentation Access and Gating Model](../../../docs/adr/ADR-0021-docs-access-model.md)
- [ADR-0022 – Documentation, Public Site, and Academy Strategy](../../../docs/adr/ADR-0022-docs-and-academy-strategy.md)

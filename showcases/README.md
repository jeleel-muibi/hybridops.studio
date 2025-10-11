# Showcases

Thin, demo-focused wrappers around the real deployment pipeline.

- Do **not** duplicate roles or playbooks here.
- Each showcase has a `Makefile` that calls root Make targets and copies evidence.
- Keep scenario-specific vars under `vars/` and diagrams under `diagrams/`.

## Run any showcase
```bash
# From repo root
make env.setup sanity
make showcase.<name>.demo
```

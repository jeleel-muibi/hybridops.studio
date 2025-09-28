# Contributing to HybridOps.Studio

Thanks for your interest! This project demonstrates a product‑led hybrid automation blueprint.
Contributions are welcome where they improve clarity, reproducibility, or security.

## Quick Start (local)
1. Ensure tooling is installed: Terraform, Ansible, Packer, Make, Python 3.x
2. Copy / create secrets outside git (see `.gitignore`); never commit secrets.
3. Use the guarded make targets:
   ```bash
   make governed-prepare ENV=staging
   make governed-deploy  ENV=staging
   ```

## Branching & PRs
- Create a feature branch: `feat/<short-name>` or `fix/<short-name>`
- Keep PRs small and scoped; include a short rationale and testing notes.
- Add or update docs in `docs/` when behavior changes.

## Code Style
- Terraform: `terraform fmt -recursive`
- Ansible: prefer idempotent roles; include `check_mode` where possible
- Python: `black` and `ruff` (if applicable)
- YAML: 2‑space indentation; no tabs

## Security
- Do not commit credentials, keys, or `.tfvars`/`.pkrvars.hcl` files.
- Use environment variables or a secure secret store for sensitive values.
- If you discover a security issue, email the maintainer directly.

## License
By contributing, you agree that your contributions are licensed under **MIT‑0**.

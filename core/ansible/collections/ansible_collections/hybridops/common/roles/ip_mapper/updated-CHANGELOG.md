# Changelog

_All notable changes to the **ip_mapper** role are documented here. This project follows **Semantic Versioning** and the format of **Keep a Changelog**._

## [2.2.0] - 2025-09-27
### Added
- **NetBox-first resolution mode (bridge):** role now prefers NetBox over local files when resolving host IPs.
  - New configuration options:
    - `ip_mapper_sources`: default `["netbox", "runtime_yaml", "terraform_outputs"]`.
    - `netbox_url`, `netbox_token`, `netbox_validate_certs`.
    - Optional scoping: `netbox_site`, `netbox_tenant`, `netbox_tags`.
    - `runtime_yaml_path`: default `core/ansible/runtime/ips/{{ env }}.yml`.
    - `terraform_output_file`: default `core/terraform-infra/output/{{ env }}.json`.
- **Auto-skip behavior** when the **NetBox dynamic inventory** is used: if hostvars include NetBox identifiers (`nb_id`/`nb_device`/`nb_vm`), the role can be safely skipped.
- **Documentation overhaul:** clear “bridge architecture”, inputs/outputs table, and guidance on when to use vs. skip the role.
- **Example playbook** showing NetBox → YAML → Terraform fallbacks with per-host source chosen.

### Changed
- **Default resolution order:** now **NetBox → runtime YAML → Terraform outputs** (previously YAML/TF only).
- **Structured logging:** each mapped host logs the **selected source** (with CID) at info/debug levels.
- README rewritten to be assessor-facing and aligned with the NetBox-first approach.

### Deprecated
- **Direct reliance on** `group_vars/all/ip_addresses.yml`. A deprecation warning is emitted if detected.
  - This path will be **removed in v3.0.0**. Use NetBox or runtime artifacts instead.

### Fixed
- Mapping logic now guards against **duplicate hostnames** across environments (requires `env` input).
- **IPv6** addresses are accepted and validated.
- Role now **fails the play** when **zero hosts** are mapped, preventing silent drift.

### Security
- IP values are **redacted** from non-verbose logs; use `-vvv` for detailed mapping traces.
- **NetBox tokens** are never echoed; recommend storing via Ansible Vault or environment variables.

## [2.1.1] - 2025-09-09
### Added
- Isolated test harness under `roles/common/ip_mapper/tests/` with dedicated inventory and group_vars
- Prompt-based environment selection (`vars_prompt`) for interactive testing
- CLI override support for `validated_env` in test playbook
- Documentation on isolated testing and prompt mode in README.md

### Changed
- Updated README.md with:
  - Detailed Testing section
  - CLI and prompt-based examples
  - Note on isolated inventory usage
- Improved clarity on pipeline integration and usage examples

### Fixed
- Ensured test playbook uses `connection: local` to prevent remote connection attempts during placeholder resolution

## [2.1.0] - 2025-09-01
### Added
- CID Logging Behavior section in README.md for audit traceability
- Dynamic Correlation ID (CID) support with fallback to env vars or runtime generation
- CID tagging in debug and fail messages across tasks
- `defaults/main.yml` with CID configuration variables

### Changed
- Updated `validate_prerequisites.yml` to seed and generate CID
- Refactored `validate_mapping.yml` and `set_ansible_host.yml` to use CID in log messages
- Enhanced README.md with enterprise value, pipeline flow, and testing instructions

### Fixed
- Ensured CID is consistently inherited or generated across all role executions

---

**Author:** jeleel-muibi · **License:** MIT-0

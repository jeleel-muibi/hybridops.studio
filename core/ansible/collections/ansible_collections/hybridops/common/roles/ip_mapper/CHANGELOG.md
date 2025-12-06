# Changelog

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

---

**Maintainer:** HybridOps.Studio

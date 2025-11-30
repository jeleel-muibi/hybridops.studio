# Changelog

All notable changes to the Environment Guard Framework will be documented in this file.

## [2.1.4] - 2025-09-10
### Changed
- Removed flat-path audit logging to reduce clutter in logs directory
- Removed use of `LATEST_RUN_PATH.txt`; now dynamically resolves latest run folder
- Updated test and CI playbooks to copy audit log and report files from latest run folder into `test/output`
- Improved dynamic path discovery for audit artifacts

## [2.1.3] - 2025-09-07
### Added
- UUID-based correlation ID generation with fallback to epoch+hex
- CID propagation across logs, reports, and Ansible callbacks
- CID-stamped report filenames for traceability
- Hardened test suite with shell-free audit verification
- Published audit/report filenames via `set_stats` for external consumers

### Changed
- Final summary now references CID-stamped report pattern
- Audit log entries include full correlation ID and justification

## [2.1.2] - 2025-01-09
### Added
- Interactive environment selection and validation
- Risk scoring and approval workflows
- Maintenance window enforcement for production
- Structured audit logging and Markdown report generation
- Dynamic path discovery for homelab projects

## [2.1.0] - 2025-09-03
### Added
- Initial enterprise validation test suite
- Environment input validation and role execution assertions
- Test summary generation with correlation ID and risk score

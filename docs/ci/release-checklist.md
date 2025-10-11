# Release Checklist (public summary)

- Lint: ansible-lint · tf fmt/validate · pre-commit
- Test: molecule (roles) · dry-run GitOps
- Versioning: SemVer bump + CHANGELOG entry
- Tag: `vX.Y.Z` and GitHub Release with checksums
- Publish (when applicable): Galaxy role/module · Terraform Registry module
- Evidence: attach CI artifacts/screenshots to Proof Archive

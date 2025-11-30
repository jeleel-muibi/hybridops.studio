## GitHub Actions Example

```yaml
name: CI Test
on:
  push:
    paths:
      - roles/common/env_guard/**
      - Makefile
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Ansible
        run: sudo apt-get update && sudo apt-get install -y ansible
      - name: Run CI Test
        run: make ci-test CI_ENV=staging
```

## Artifact Handling

- Audit logs are written to `common/logs/env_guard_logs/<timestamped_run_folder>/env_guard_audit.log`
- CID-stamped reports are saved as `env_guard_report_<timestamp>_<cid8>.md`
- During CI and test runs, these files are copied to `test/output/` for validation

## Notes

- CI test playbook: `roles/common/env_guard/tests/test_env_validation_ci.yml`
- No interactive prompts (uses `env` variable directly)
- Fails if correlation ID is missing from logs or reports

---

Maintained by jeleel-muibi

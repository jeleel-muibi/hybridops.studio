### Network prerequisites

Before you run any Packer template builds or automation against Proxmox, make sure your lab network matches the prerequisites:

- [Network Infrastructure Prerequisites](../prerequisites/NETWORK_INFRASTRUCTURE.md)

For the architectural rationale behind these assumptions, see
[ADR-0015 — Network Infrastructure Assumptions](../adr/ADR-0015-network-infrastructure-assumptions.md).


## Next steps: hardening and secrets

This quickstart focuses on getting the platform running.

For how secrets are handled across Ctrl-01, Proxmox, Azure, GCP and RKE2, see:

- [Secrets lifecycle and responsibilities](../guides/secrets-lifecycle.md)
- [ADR-0020 — Secrets strategy (AKV primary, SOPS DR fallback, Vault optional later)](../adr/ADR-0020_secrets-strategy_akv-now_sops-fallback_vault-later.md)

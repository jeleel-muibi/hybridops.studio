# hybridops.common (internal collection)

Roles and helpers used across HybridOps.Studio demos (not a Galaxy release by itself).

## Use in this repo
```yaml
- hosts: linux:&tag_baseline
  collections:
    - hybridops.common
  roles:
    - role: hybridops.common.harden_ssh
    - role: hybridops.common.user_management
```

## Role index
| Role | Purpose | Key vars | Notes |
|---|---|---|---|
| `linux.harden_ssh` | Baseline SSH hardening (CIS-leaning) | `ssh_permit_root`, `ssh_ciphers` | Reloads `sshd` |
| `linux.user_management` | Sys users, groups, sudoers | `users`, `sudoers` | Idempotent |
| `linux.rke2_install` | Install & pin RKE2 | `rke2_channel`, `node_role` | CP/worker flags |
| `linux.deploy_nginx` | Simple nginx deploy | `nginx_ports` | Optional TLS |
| `netbox.seed` | Seed NetBox objects | `nb_url`, `nb_token`, `seed_data` | HTTP modules |
| `network.base_config` | Baseline device config | `hostname`, `ntp`, `snmp` | Platform vars |
| `network.configure_bgp` | eBGP/VPN edge config | `bgp_asn`, `neighbors[]` | Route-maps |
| `windows.domain_join` | Join host to AD | `domain_name`, `ou_path`, `cred_*` | WinRM/PS |
| `windows.install_sql` | SQL Server install & config | `edition`, `features` | Basic HA hooks |
| `windows.windows_updates` | Patch orchestration | `maintenance_window` | |

> Each role has its own `README.md` under `roles/<role>` describing variables and a runnable example.

## Notes
- Reusable, versioned roles are mirrored to **Ansible Galaxy** from dedicated repositories for external consumption.
- This internal collection is optimized for the portfolio’s deployment playbooks and CI; interfaces may evolve.

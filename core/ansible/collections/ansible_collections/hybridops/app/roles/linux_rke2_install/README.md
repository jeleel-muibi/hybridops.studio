# rke2_install (linux role)

Installs and configures RKE2 as server or agent and ensures the service is enabled/running.

## Variables
- `rke2_type`: `"server"` or `"agent"`
- `rke2_channel`: install channel (default: `stable`)
- `rke2_server_url`, `rke2_token`: required when `rke2_type=agent`
- `rke2_config_extra`: freeform map merged into `config.yaml`

## Example
```yaml
- hosts: rke2_nodes
  become: true
  collections:
    - hybridops.common
  roles:
    - role: linux/rke2_install
      vars:
        rke2_type: server
```

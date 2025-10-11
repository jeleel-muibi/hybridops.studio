# Ansible Role — TEMPLATE

> Replace placeholders and move this into a **dedicated repo** when publishing to Ansible Galaxy.

## Role name
`YOUR_NAMESPACE.role_name`

## Description
Short sentence about what the role configures (e.g., baseline hardening, user management, RKE2 install).

## Requirements
- Ansible >= 2.12
- Supported platforms: Ubuntu 20.04/22.04; EL 8/9

## Role Variables
| Variable | Default | Description |
|---|---|---|
| `role_example_enabled` | `true` | Example boolean toggle |
| `role_example_users` | `[]` | Example list of users |

## Dependencies
None.

## Example Playbook
```yaml
- hosts: all
  become: true
  collections:
    - YOUR_NAMESPACE  # optional if you keep roles in a collection
  roles:
    - role: YOUR_NAMESPACE.role_name
      vars:
        role_example_enabled: true
        role_example_users:
          - "ops"
```

## Testing
- Lint: `ansible-lint`
- Molecule: add scenarios under `molecule/` as needed

## License
MIT-0

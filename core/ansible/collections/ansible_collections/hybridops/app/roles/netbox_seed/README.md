# seed (netbox role)

Skeleton role for seeding NetBox. Start by verifying reachability, then replace the debug task with `netbox.netbox` modules (e.g., `netbox_site`, `netbox_tenant`).

Variables: `netbox_url`, `netbox_token`, `site_name`, `tenant_name`, `dry_run`.

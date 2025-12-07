# Stage the fixes
git add -A

# Commit again
git commit -m 'feat: add generic VM module and ctrl-01 Jenkins deployment

- Create reusable proxmox/vm module for all VM deployments
- Add ctrl-01 Jenkins controller deployment configuration
- Include cloud-init bootstrap for Jenkins installation
- Static IP assignment (NetBox IPAM integration planned for Phase 3)
- Supports multi-environment deployment (dev/staging/prod)
- Updates IPAM module documentation

Refs: Phase 2 - Control Plane Bootstrap'

echo ""
git log --oneline -3

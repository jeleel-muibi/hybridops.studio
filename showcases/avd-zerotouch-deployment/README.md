# AVD Zero‑Touch Deployment (Showcase)

This showcase demonstrates a zero‑touch Azure Virtual Desktop deployment using your repo's pipeline.
It calls your real Terraform/Ansible code and collects evidence — no duplicated logic here.

## Zero‑touch scope
- RG + VNet + subnets (hosts/services)
- (Next) AVD host pool, app group, workspace, FSLogix

## Run
```bash
make env.setup sanity
make showcase.avd-zerotouch-deployment.demo
```
Evidence goes to `showcases/avd-zerotouch-deployment/evidence/`.

## Advanced networking (optional)
```bash
make showcase.avd-zerotouch-deployment.advanced-networking
```
This applies Terraform under `terraform-infra/environments/cloud/azure-advanced/` with vars from
`showcases/avd-zerotouch-deployment/vars/advanced.tfvars`.

Destroy with:
```bash
make showcase.avd-zerotouch-deployment.destroy
make showcase.avd-zerotouch-deployment.destroy-advanced
```

# ctrl-01: Jenkins Control Plane

Jenkins controller VM that orchestrates all infrastructure automation.

## Configuration

- IP: 10.10.0.100/24 (Management VLAN)
- vCPU: 4 cores
- RAM: 8 GB
- Disk: 64 GB
- OS: Ubuntu 22.04 (cloud-init)

## Bootstrap Process

1.Deploy VM via Terraform
2.Cloud-init installs Jenkins
3.Access Jenkins at http://10.10.0.100:8080
4.Get initial admin password

## Deploy

cd infra/terraform/live-v1/ctrl01
terragrunt plan
terragrunt apply

## Post-Deployment

1.SSH: ssh sysadmin@10.10.0.100
2.Get password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
3.Access Jenkins UI and complete setup

## Next Steps

Jenkins will orchestrate:
- PostgreSQL deployment
- NetBox deployment  
- IPAM synchronization
- All future infrastructure

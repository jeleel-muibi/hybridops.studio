# JCasC Bundle — AKV

**akv-core.yaml**: Jenkins core/security + Azure Key Vault plugin and SP credentials  
**akv-jobs.yaml**: Job DSL — creates `ci/` folder and pipelines (akv-smoke, packer-build, terraform, ansible)

Apply:
1) Copy both files to `/var/lib/jenkins/casc/bundles/akv/`
2) Set `CASC_JENKINS_CONFIG=/var/lib/jenkins/casc/bundles/akv`
3) Restart Jenkins

Prereqs:
- Jenkins has the Azure Key Vault plugin
- SP/tenant/subscription values provided via env or AKV secrets

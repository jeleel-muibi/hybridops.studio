# Jenkins

Jenkins executes environment‑aware plans/applies and end‑to‑end flows. Shared steps live in the core Jenkins library.

**Components**
- **Shared library:** `core/ci-cd/jenkins/shared-library/` (Groovy helper steps).
- **Pipeline templates:** `core/ci-cd/jenkins/pipeline-templates/` (reference Jenkinsfiles).

**Typical stages**
1. Environment sanity (`make env.setup sanity`)
2. Terraform plan/apply (onprem/cloud)
3. Ansible playbook runs (baseline / domain / network)
4. GitOps sync and health check
5. Evidence archiving (logs/artifacts to `out/`)

**Example**
See the Jenkinsfile snippet inside **Core → CI/CD (Jenkins) at a glance**.

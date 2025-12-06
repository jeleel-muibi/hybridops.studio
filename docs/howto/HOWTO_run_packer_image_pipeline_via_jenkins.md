---
title: "Run the Packer Image Pipeline via Jenkins"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Execute the standard HybridOps.Studio Packer pipeline from Jenkins to build Proxmox VM templates with evidence capture."
difficulty: "Intermediate"

topic: "packer-pipeline-jenkins"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"  # Adjust if repo path differs.

draft: false
is_template_doc: false
tags: ["packer", "proxmox", "jenkins", "templates", "automation"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Run the Packer Image Pipeline via Jenkins

This HOWTO shows how to run the **standard Packer image pipeline** from Jenkins to build Proxmox VM templates used by RKE2 and other platform workloads, and where to find the resulting **evidence artefacts**.

It assumes you are using the shared Packer workspace in [`infra/packer-multi-os/`](../../infra/packer-multi-os/) and that templates are treated as immutable, cloud-init–ready images per [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md).

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Trigger a Jenkins pipeline that runs the Packer build for a selected template (for example, Ubuntu or Rocky).
- Confirm that the build used the **standard workspace and Makefile**.
- Locate the generated logs and artefacts under [`docs/proof/platform/packer-builds/`](../../docs/proof/platform/packer-builds/).
- Capture enough evidence for Evidence 4 to show how templates are built and rebuilt.

---

## 2. Prerequisites

### 2.1 Infrastructure and access

You should have:

- A working Proxmox cluster with:
  - API endpoint reachable from the Jenkins controller.
  - Storage pools defined for ISO images and VM disks.
- A Jenkins controller running on the control node (see [ADR-0603 – Run Jenkins Controller on Control Node, Agents on RKE2](../adr/ADR-0603-jenkins-controller-docker-agents-rke2.md)).
- At least one Jenkins agent with:
  - Access to the Git repository containing `infra/packer-multi-os/`.
  - Network access to the Proxmox API endpoint.

### 2.2 Credentials and environment

- Proxmox API token configured as Jenkins credentials (for example, `proxmox-api-token`).
- A Packer environment file (for example, `shared/.env`) compatible with ADR-0016, containing:

  ```bash
  PKR_VAR_proxmox_url="https://<PROXMOX_IP>:8006/api2/json"
  PKR_VAR_proxmox_token_id="automation@pam!infra-token"
  PKR_VAR_proxmox_token_secret="<SECRET>"
  PKR_VAR_proxmox_node="<NODE_NAME>"
  PKR_VAR_proxmox_skip_tls_verify=true
  ```

- Jenkins pipeline definition that:
  - Checks out the repo.
  - Exports the required environment variables from `.env`.
  - Calls the Makefile in `infra/packer-multi-os/`.

### 2.3 Related decisions and docs

- [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  

---

## 3. Locate the Jenkins job

1. Open the Jenkins UI on the control node.
2. Navigate to the Packer pipeline job, for example:

   - `ci/packer/build-template`
   - or a similar foldered pipeline dedicated to image builds.

3. Confirm in the job configuration (or Jenkinsfile) that it:

   - Checks out the HybridOps.Studio repository.
   - Runs within a node/agent with access to Proxmox.
   - Invokes `make` targets inside `infra/packer-multi-os/`.

Example excerpt from a Jenkinsfile (for illustration):

```groovy
pipeline {
  agent { label 'ctrl-docker' }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Ubuntu 22.04 template') {
      steps {
        dir('infra/packer-multi-os') {
          withCredentials([string(credentialsId: 'proxmox-api-token', variable: 'PKR_VAR_proxmox_token_secret')]) {
            sh 'make validate'
            sh 'make build-ubuntu-2204'
          }
        }
      }
    }
  }
}
```

Adjust labels and target names to match your actual configuration.

---

## 4. Run the pipeline

1. In the Jenkins UI, click **Build with Parameters** (if parameters exist) or **Build Now**.
2. Select:
   - The OS/template you want to build (for example, `ubuntu-2204`, `rocky-9`, `win2022`).
   - Target environment (for example, `lab`, `dr-test`) if the job is parameterised.
3. Start the build and monitor:

   - Console output should show:
     - `packer init` / `packer validate` and `packer build` calls.
     - References to `infra/packer-multi-os/...`.
   - Packer logs should show connection to the Proxmox API and VM creation.

If the build fails, capture the console log; it is often useful evidence for troubleshooting and can be stored under `docs/proof/infra/packer/` as a failure artefact.

---

## 5. Verify the Proxmox template

After a successful build:

1. Log in to the Proxmox UI.
2. Navigate to the **VM templates** list.
3. Locate the new or updated template, for example:
   - `tpl-ubuntu-22.04`
   - `tpl-rocky-9`
4. Check that the template:

   - Has the expected VMID range reserved for templates.
   - Uses the correct storage pools (ISO and disk).
   - Is marked as a template in Proxmox.

Record any relevant screenshots or configuration details if you need visual evidence for assessors.

---

## 6. Locate and review evidence artefacts

The pipeline should write logs and artefacts to the proof tree. Typical locations:

- [`docs/proof/platform/packer-builds/`](../../docs/proof/platform/packer-builds/)
  - Build logs (for example, `packer-ubuntu-2204-<timestamp>.log`).
  - JSON or text manifests summarising images created.
  - Optional screenshots or notes.

Verify that:

- There is an entry for the specific build you just ran (based on timestamp or template name).
- The artefacts are committed to Git (for runs you want to preserve as evidence).

These artefacts support Evidence 4 by showing how templates are built and giving third parties enough information to repeat or review the process.

---

## 7. Clean up (optional)

If the build created intermediate VMs or test resources that are no longer required:

1. Confirm that the final template exists and is correct.
2. Use Proxmox or automation to remove any stray non-template VMs created during testing.
3. Keep logs and artefacts; they are useful for regression analysis and as proof of how the template was produced.

---

## 8. Validation checklist

Use this quick checklist to confirm the run is complete:

- [ ] Jenkins job ran successfully and used `infra/packer-multi-os/`.
- [ ] The expected template is present in Proxmox with the correct name and VMID.
- [ ] Evidence artefacts exist under [`docs/proof/infra/packer/`](../../docs/proof/infra/packer/).
- [ ] Changes to artefacts are committed and pushed (for evidence runs).
- [ ] Any follow-on steps (for example, RKE2 node creation from the new template) are scheduled or executed.

---

## References

- [ADR-0016 – Adopt Packer + Cloud-Init for VM Template Standardization](../adr/ADR-0016-packer-cloudinit-vm-templates.md)  
- [ADR-0603 – Run Jenkins Controller on Control Node, Agents on RKE2](../adr/ADR-0603-jenkins-controller-docker-agents-rke2.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/platform/packer-builds/`](../../docs/proof/platform/packer-builds/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

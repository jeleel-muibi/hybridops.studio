---
title: "Jenkins Controller Outage on ctrl-01"
category: "ops"              # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Diagnose and recover from a Jenkins controller outage on the control node, and decide when to escalate to DR."
severity: "P1"               # P1 = critical, P2 = high, P3 = normal.

topic: "jenkins-controller-outage-ctrl01"

draft: false
is_template_doc: false
tags: ["jenkins", "ops", "dr", "ctrl-01", "agents"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Jenkins Controller Outage on ctrl-01

**Purpose:** Provide a structured response to outages of the **Jenkins controller** running as Docker on `ctrl-01`, including local recovery steps and criteria to escalate to DR orchestration.  
**Owner:** Platform / SRE team (HybridOps.Studio)  
**Trigger:** Jenkins UI is unavailable or core pipelines are failing due to controller issues.  
**Impact:** CI/CD pipelines for Packer, Terraform, Ansible and app deployments are disrupted. Platform changes may be blocked.  
**Severity:** P1 – Jenkins is a core control-plane component for HybridOps.Studio.

---

## 1. Scenario overview

HybridOps.Studio runs:

- Jenkins controller as a Docker container on `ctrl-01`.
- Jenkins agents:
  - Initially as Docker containers on `ctrl-01`.
  - Primarily as pods on the RKE2 cluster once available.

This runbook covers:

1. Quick checks on `ctrl-01` to confirm the nature of the outage.  
2. Recovery attempts (restart container, restore from backup).  
3. When to trigger DR orchestration (GitHub Actions) if Jenkins is down long enough or coincides with broader platform issues.  
4. Evidence capture to support post-mortem and portfolio artefacts.

---

## 2. Symptoms and initial triage

Common symptoms:

- Jenkins UI not reachable (HTTP 5xx or timeouts).
- Critical pipelines stuck in queue or failing immediately.
- Agents reporting as offline unexpectedly.

Initial triage:

1. **Check reachability**

   - From your workstation or control node, try:

     ```bash
     curl -I http://<ctrl-01-or-jenkins-url>/
     ```

   - Note the HTTP status or connection error.

2. **Check `ctrl-01` host status**

   - SSH to `ctrl-01`:

     ```bash
     ssh <user>@ctrl-01
     ```

   - If SSH fails, treat this as a broader host outage and escalate via infra procedures.

3. **Check Docker and Jenkins container**

   - On `ctrl-01`, run:

     ```bash
     sudo systemctl status docker
     docker ps --format 'table {{.Names}}	{{.Status}}'
     ```

   - Identify the Jenkins controller container (for example, `jenkins-controller`).

4. **Record initial observations**

   - Store quick notes and screenshots/logs under:

     - [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/)

---

## 3. Phase 1 – Basic recovery on ctrl-01

> Goal: Restore Jenkins from simple causes (container crash, docker service issues, disk full) without invoking DR.

1. **Restart Docker (if needed)**

   - If `systemctl status docker` shows errors, attempt:

     ```bash
     sudo systemctl restart docker
     ```

   - Re-check container status:

     ```bash
     docker ps
     ```

2. **Restart Jenkins container**

   - If the container is stopped or unhealthy:

     ```bash
     docker restart jenkins-controller
     docker logs --tail=100 jenkins-controller
     ```

   - Look for:
     - Port binding errors.
     - Disk or permissions issues.
     - Plugin or configuration failures.

3. **Check disk and filesystem**

   - Verify that `ctrl-01` is not out of disk space:

     ```bash
     df -h
     ```

   - If disk is full, perform clean-up of logs or artefacts following local procedures, then restart Jenkins.

4. **Re-test access**

   - Confirm the UI is reachable again.
   - Trigger a small, non-destructive pipeline (for example, a lint or `validate` job) to verify health.

If Jenkins is recovered and stable, proceed to **Phase 4 – Evidence and close-out**.

---

## 4. Phase 2 – Restore from backup

> Goal: Restore Jenkins from backup if configuration or data is corrupted.

1. **Confirm backup availability**

   - Identify the latest successful backup of `JENKINS_HOME` (for example, via snapshot, backup job, or file-level archive).
   - Document backup date and scope.

2. **Stop the Jenkins container**

   ```bash
   docker stop jenkins-controller
   ```

3. **Restore `JENKINS_HOME`**

   - Follow your documented restore procedure (for example, snapshot rollback, `rsync` from backup location).
   - Ensure correct ownership/permissions on the restored directory.

4. **Start Jenkins container**

   ```bash
   docker start jenkins-controller
   docker logs --tail=100 jenkins-controller
   ```

5. **Validate**

   - Check:
     - UI access.
     - Recent jobs history (where relevant).
     - Agent connectivity (Docker and RKE2 agents).

Record the restore steps and any deviations in [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/).

---

## 5. Phase 3 – Escalation to DR orchestration (if needed)

> Goal: Decide when Jenkins outage should trigger or contribute to a DR event.

Escalate to DR if:

- Jenkins remains unavailable despite basic and backup-based recovery attempts, **and**
- The outage coincides with broader signs of on-prem platform failure (for example, RKE2 or key workloads down), **or**
- The outage exceeds a defined time threshold that threatens SLOs for critical delivery operations.

Steps:

1. **Engage incident command**

   - Present:
     - Timeline of Jenkins outage and recovery attempts.
     - Impact on critical pipelines.
     - Status of RKE2 and other dependencies.

2. **If DR is approved**

   - Follow:

     - [Runbook – DR Cutover: On-Prem RKE2 to Cloud Cluster](../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md)

   - GitHub Actions DR workflows may be triggered independently of Jenkins availability.

3. **Evidence**

   - Ensure the decision to trigger DR is documented in the incident notes and supported by logs in:

     - [`docs/proof/dr/`](../../docs/proof/dr/)
     - [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/)

---

## 6. Phase 4 – Evidence and close-out

Once Jenkins is restored or DR has been triggered:

1. **Capture logs and state**

   - From `ctrl-01`:

     ```bash
     docker logs --tail=500 jenkins-controller > docs/proof/infra/jenkins/jenkins-controller-logs-<date>.log
     ```

   - Optionally capture system logs (for example, `journalctl -u docker`).

2. **Validate pipelines**

   - Run:
     - A small Packer pipeline.
     - A Terraform/Ansible pipeline.
   - Confirm they complete successfully or note any residual issues.

3. **Update incident or ops ticket**

   - Document:
     - Root cause (if identified).
     - Recovery steps taken.
     - Any configuration changes made.
   - Link the ticket to proof artefacts and, if applicable, DR actions.

4. **Follow-up actions**

   - Schedule maintenance or refactoring if:
     - Jenkins is a single point of failure with insufficient backup.
     - Disk, memory or plugin bloat contributed to the outage.

---

## 7. Validation checklist

- [ ] Jenkins controller container is running and healthy on `ctrl-01`.  
- [ ] Jenkins UI is reachable and core pipelines can run.  
- [ ] Any restore-from-backup steps completed successfully and are documented.  
- [ ] DR escalation was considered and performed if warranted.  
- [ ] Evidence and logs have been stored under [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/) and, if applicable, [`docs/proof/dr/`](../../docs/proof/dr/).  
- [ ] Incident ticket is updated with timeline, root cause (if known), and follow-ups.  

---

## References

- [ADR-0603 – Run Jenkins Controller on Control Node, Agents on RKE2](../adr/ADR-0603-jenkins-controller-docker-agents-rke2.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

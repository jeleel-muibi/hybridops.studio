---
title: "Runbook – Argo CD / GitOps Sync Issues"
category: "ops"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Diagnose and resolve Argo CD Application sync and health issues affecting workloads on RKE2."
severity: "P3"

topic: "gitops-sync-issues"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final incident/demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["gitops", "argo-cd", "sync-issues", "rke2", "kubernetes"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Runbook – Argo CD / GitOps Sync Issues

## 1. Context

This runbook covers **Argo CD Application sync and health issues** for workloads running on **RKE2** in HybridOps.Studio.

Typical symptoms include:

- Argo CD Applications showing **OutOfSync**, **Degraded** or **Missing**.  
- Expected deployments/services not present or stuck in a bad state.  
- Rollouts not occurring after a Git change, or rolling back unexpectedly.

This runbook assumes:

- Argo CD is the **GitOps controller** for application delivery (ADR-0203).  
- RKE2 is the primary runtime for platform and apps (ADR-0202).  
- Application manifests are stored under `deploy/<app>/...` (HOWTO – GitOps onboarding).

This is a **P3** operational incident unless it directly affects critical services, in which case escalate according to the service runbook.

---

## 2. Triggers

Use this runbook when you observe one or more of the following:

- An Argo CD Application is **OutOfSync** and does not reconcile as expected.  
- An Application is **Degraded** (for example, pods failing, missing services).  
- A Git change should have triggered a rollout but nothing changed in the cluster.  
- Argo CD reports **sync errors** (for example, invalid manifests, permission issues).  

If multiple Applications are impacted, or Argo CD itself is unavailable, first check:

- Platform health (Prometheus dashboards, ADR-0401/0402).  
- Any ongoing DR events (see DR runbooks).

---

## 3. Preconditions and Safety

Before taking action:

- Confirm you have **read/write** access to:
  - The Git repo hosting the manifests.  
  - The Argo CD namespace (for example, `argocd`).  
  - The relevant application namespaces on RKE2.  

- Avoid:
  - Editing live resources with `kubectl` unless required for mitigation.  
  - Making unreviewed changes directly in Argo CD UI; favour Git commits and PRs.

- If the application is **user-facing** or important for other pipelines (for example, NetBox, Jenkins agents), consider:

  - Notifying stakeholders in the relevant channel (if configured).  
  - Logging the incident start time and affected Applications.

---

## 4. Phase 1 – Identify the impacted Application(s)

1. **List Applications**

   Use Argo CD UI or CLI:

   ```bash
   argocd app list
   ```

   Look for Applications with status:

   - `OutOfSync`  
   - `Degraded`  
   - `Missing`

2. **Inspect the Application**

   For one application (example: `demo-api-dev`):

   ```bash
   argocd app get demo-api-dev
   ```

   Note:

   - Health: `Healthy` / `Degraded` / `Missing`  
   - Sync status: `Synced` / `OutOfSync`  
   - Recent conditions and messages  

3. **Check cluster resources**

   In the target namespace (for example, `demo-api-dev`):

   ```bash
   kubectl get deploy,svc,ingress,pods -n demo-api-dev
   ```

   Compare what exists in the cluster with what Argo CD expects.

---

## 5. Phase 2 – Check Git and Application definition

1. **Confirm repo and path**

   From `argocd app get` output, confirm:

   - `repoURL`  
   - `targetRevision` (branch/tag)  
   - `path` (for example, `deploy/demo-api/overlays/dev`)

2. **Verify manifests in Git**

   In the repo:

   ```bash
   ls deploy/demo-api/overlays/dev
   ```

   Check for:

   - Missing or renamed files  
   - Invalid references (for example, removed base path)  

3. **Check recent Git changes**

   ```bash
   git log -5 -- deploy/demo-api
   ```

   Look for:

   - Manifest changes without corresponding Argo CD updates  
   - Accidental deletions or renames  

If a recent commit is clearly wrong, plan to **revert** or fix it via Git rather than patching directly in the cluster.

---

## 6. Phase 3 – Investigate sync and health errors

1. **View sync details**

   ```bash
   argocd app history demo-api-dev
   argocd app diff demo-api-dev
   ```

   Identify:

   - Resources Argo CD wants to create/update/delete.  
   - Any resources with errors indicated in the diff or history.

2. **Check Argo CD events and logs**

   ```bash
   kubectl logs -n argocd deploy/argocd-server
   kubectl logs -n argocd deploy/argocd-application-controller
   ```

   Look for:

   - Permission errors (for example, RBAC / ServiceAccount issues).  
   - Invalid manifest errors from Kubernetes API.

3. **Validate manifests locally (optional)**

   In the repo:

   ```bash
   kubectl kustomize deploy/demo-api/overlays/dev | kubectl apply --dry-run=client -f -
   ```

   or, for plain manifests:

   ```bash
   kubectl apply --dry-run=client -f deploy/demo-api/overlays/dev/
   ```

   This can reveal structural or schema issues before Argo CD attempts to sync.

---

## 7. Phase 4 – Apply a safe fix

Use the simplest fix that restores **desired state = actual state**, while preserving Git as the source of truth.

### 7.1 Manifest fix in Git

If the issue is caused by invalid or incomplete manifests:

1. Fix the manifest(s) in a branch.  
2. Commit with a clear message (for example, `fix: correct demo-api dev service port`).  
3. Merge to the branch Argo CD is watching (for example, `main`).  
4. Allow Argo CD to auto-sync or trigger manually:

   ```bash
   argocd app sync demo-api-dev
   ```

5. Re-check health:

   ```bash
   argocd app get demo-api-dev
   kubectl get pods -n demo-api-dev
   ```

### 7.2 Revert a bad change

If a recent commit broke the Application and the previous version was stable:

1. Identify the last known-good commit from `git log`.  
2. Revert the problematic commit(s):

   ```bash
   git revert <bad-commit-sha>
   git push
   ```

3. Let Argo CD reconcile.  

This maintains Git history and keeps Argo CD as the authority.

### 7.3 Limited manual intervention (only if required)

If a manual change is necessary to stabilise the environment (for example, scale down a failing deployment):

1. Capture the change:

   ```bash
   kubectl scale deploy demo-api -n demo-api-dev --replicas=0
   ```

2. Document what you did and why.  
3. Update manifests in Git to match any intended long-term change so Argo CD does not revert them.

---

## 8. Phase 5 – Confirm resolution

An Application is considered **recovered** when:

- Argo CD reports status:

  - `Synced`  
  - `Healthy`

- Required resources exist and are running in the target namespace.  
- No new errors appear in Argo CD controller logs related to that Application.

Capture:

```bash
argocd app get demo-api-dev
kubectl get deploy,svc,pods -n demo-api-dev
```

Store output (redacted if necessary) in:

```bash
docs/proof/runbooks/gitops-sync-issues-<date>/
```

---

## 9. Rollback and escalation

If the above steps do not resolve the issue or the blast radius grows:

- Consider temporarily **disabling auto-sync** for the Application to prevent repeated failed rollouts.  
- Escalate to a higher severity if:

  - A critical service is impacted, or  
  - The issue appears to affect multiple Applications or the Argo CD control plane itself.

In that case:

- Follow platform or DR-related runbooks as appropriate.  
- Coordinate changes through the normal change process.

---

## 10. Evidence and logging

For each incident, capture:

- Application name(s) and namespace(s).  
- Screenshots or CLI output showing:

  - Before: `OutOfSync` / `Degraded` state.  
  - After: `Synced` / `Healthy` state.  

- Git commit IDs used in the fix or rollback.  

Store all artefacts under:

```bash
docs/proof/runbooks/gitops-sync-issues-<date>/
```

This contributes to Evidence 4 and supports Academy material for GitOps troubleshooting.

---

## 11. Validation checklist

- [ ] Impacted Argo CD Application(s) identified.  
- [ ] Repo URL, path, and target revision verified.  
- [ ] Sync and health errors understood (from Argo CD output/logs).  
- [ ] Fix applied via Git where possible (manifest correction or revert).  
- [ ] Application status returns to `Synced` and `Healthy`.  
- [ ] Any manual cluster changes reconciled with Git.  
- [ ] Proof artefacts captured under `docs/proof/runbooks/gitops-sync-issues-<date>/`.  

---

## References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0203 – Adopt Argo CD as GitOps Controller for Application Delivery](../adr/ADR-0203-argo-cd-gitops-application-delivery.md)  
- [HOWTO – Onboard an Application into GitOps with Argo CD](../howtos/HOWTO_gitops_onboarding_argo_cd.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

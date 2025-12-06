---
title: "Onboard an Application into GitOps with Argo CD"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Model an application for GitOps, define Argo CD Applications, and deploy it to RKE2 using a declarative, environment-aware structure."
difficulty: "Intermediate"

topic: "gitops-onboarding"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["gitops", "argo-cd", "rke2", "kubernetes", "cd"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Onboard an Application into GitOps with Argo CD

This HOWTO shows how to onboard an application into **GitOps** using **Argo CD** on an RKE2 cluster in HybridOps.Studio.

You will:

- Model an application with a **clean Git structure** for environments.  
- Create an **Argo CD Application** that points at those manifests.  
- Trigger a deployment by changing Git, not by running `kubectl` manually.  

It aligns with:

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0203 – Adopt Argo CD as GitOps Controller for Application Delivery](../adr/ADR-0203-argo-cd-gitops-application-delivery.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Structure application manifests in Git for **dev / staging / prod** (or equivalent).  
- Create an Argo CD Application targeting your RKE2 cluster.  
- Deploy and update the application **by changing Git only**.  
- Capture basic evidence of GitOps behaviour for HybridOps.Studio.

---

## 2. Prerequisites

### 2.1 Platform

You should have:

- An RKE2 cluster running, as per Evidence 4.  
- Argo CD deployed and reachable (CLI and/or UI).  
- A container registry you can push images to (or an existing public image).  

### 2.2 Git and repository

- A Git repository that will hold your application manifests.  
- Access to the HybridOps.Studio repo or a separate demo repo, depending on how you want to present the app.

### 2.3 Access to Argo CD

- Argo CD credentials with permission to create Applications in the desired project/namespace.  
- `argocd` CLI configured, or access to Argo CD UI.

---

## 3. Phase 1 – Choose or create a sample application

For the purposes of this HOWTO, you can use:

- A simple demo API or web app already in HybridOps.Studio, or  
- A public container image such as `nginx:stable` or a small test app.

Assume a logical application name, e.g. `demo-api`.

---

## 4. Phase 2 – Structure application manifests in Git

1. **Create a base directory**

   In the repo where you keep deployment manifests, create:

   ```bash
   mkdir -p deploy/demo-api/base
   mkdir -p deploy/demo-api/overlays/dev
   mkdir -p deploy/demo-api/overlays/staging
   mkdir -p deploy/demo-api/overlays/prod
   ```

2. **Define base manifests**

   At minimum, create:

   - Deployment
   - Service
   - Namespace (or use a shared one)

   under `deploy/demo-api/base/`. Use a standard K8s pattern with labels like:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: demo-api
     labels:
       app: demo-api
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: demo-api
     template:
       metadata:
         labels:
           app: demo-api
       spec:
         containers:
           - name: demo-api
             image: your-registry/demo-api:1.0.0
             ports:
               - containerPort: 8080
   ```

3. **Define overlays**

   Use your preferred mechanism (for example, Kustomize) or just separate manifests. A simple directory-per-environment layout might contain:

   - A `kustomization.yaml` that references `../../base`.  
   - Environment-specific patches (replica count, config, URLs).

4. **Commit the structure**

   Commit and push the changes so Argo CD can track them.

---

## 5. Phase 3 – Create an Argo CD Application

1. **Decide on RKE2 target**

   Determine:

   - The RKE2 cluster/endpoint Argo CD is targeting.  
   - The namespace(s) for each environment (`demo-api-dev`, `demo-api-staging`, `demo-api-prod` or similar).

2. **Create Application via manifest (recommended)**

   For one environment (e.g. `dev`), define:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: demo-api-dev
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/hybridops-studio/hybridops-studio.git
       targetRevision: main
       path: deploy/demo-api/overlays/dev
     destination:
       server: https://kubernetes.default.svc
       namespace: demo-api-dev
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   ```

   Apply this using `kubectl`:

   ```bash
   kubectl apply -f deploy/demo-api/argo/demo-api-dev-application.yaml
   ```

   Or create it via Argo CD UI with equivalent settings.

3. **Repeat for other environments**

   - `demo-api-staging` pointing at `overlays/staging`.  
   - `demo-api-prod` pointing at `overlays/prod`.

   Use separate `Application` objects even if they share the same repo.

---

## 6. Phase 4 – Sync and validate

1. **Initial sync**

   - In the Argo CD UI or via CLI (`argocd app sync demo-api-dev`), trigger a sync.  
   - Confirm that:
     - The namespace is created.  
     - Deployment and Service are created.  

2. **Check application status**

   - Argo CD should show `Healthy` / `Synced` for `demo-api-dev`.  
   - If there are errors (for example, image pull issues, invalid manifests), inspect logs and fix the manifests in Git.

3. **Capture basic evidence**

   Store in a proof folder such as:

   ```bash
   mkdir -p docs/proof/apps/demo-api/gitops-onboarding-<date>/
   ```

   Capture:

   - `kubectl get pods -n demo-api-dev` output.  
   - Argo CD Application status (screenshot or CLI output).  

---

## 7. Phase 5 – Demonstrate GitOps change and rollback

1. **Change the application via Git**

   - Update the image tag from `1.0.0` to `1.0.1` (or similar) in the `base` manifests.  
   - Commit and push.

2. **Observe Argo CD reaction**

   - Argo CD will detect the change and either:
     - Auto-sync (if `automated` is enabled), or  
     - Show `OutOfSync` status and allow you to sync manually.

3. **Verify rollout**

   - Check that the new pods are running with the updated image.  
   - Capture CLI output and/or screenshots into the same `docs/proof/apps/demo-api/gitops-onboarding-<date>/` folder.

4. **Rollback via Git**

   - Revert the change (for example, `git revert` or editing the tag back).  
   - Push the revert.
   - Argo CD will again reconcile, rolling back the deployment.

   Capture evidence of rollback (status, pod versions).

---

## 8. Phase 6 – Tie back to Evidence 4

Document briefly (for your notes or a short internal page):

- Which repo path is used for the app (`deploy/demo-api/...`).  
- Which Argo CD Applications represent each environment.  
- Where the proof artefacts are stored.

This helps wiring the onboarding story into:

- Evidence 4 (GitOps and cluster operations), and  
- Academy content that shows a concrete GitOps onboarding path.

---

## 9. Validation checklist

- [ ] Application manifests structured under `deploy/demo-api/` with base + overlays.  
- [ ] Argo CD Application created and pointing at the correct repo path and branch.  
- [ ] Initial sync succeeded and pods are running on RKE2.  
- [ ] A change to manifests in Git triggered a reconciliation and rollout.  
- [ ] Rollback was performed by reverting Git and letting Argo CD reconcile.  
- [ ] Proof artefacts stored under `docs/proof/apps/demo-api/gitops-onboarding-<date>/`.  

---

## References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0203 – Adopt Argo CD as GitOps Controller for Application Delivery](../adr/ADR-0203-argo-cd-gitops-application-delivery.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

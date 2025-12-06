4---
title: "Runbook – External Secrets / Azure Key Vault Projection Issues"
category: "ops"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Diagnose and resolve issues where External Secrets Operator fails to project secrets from Azure Key Vault into RKE2."
severity: "P2"

topic: "eso-akv-issues"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final incident/demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["secrets", "azure-key-vault", "external-secrets-operator", "rke2", "kubernetes"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Runbook – External Secrets / Azure Key Vault Projection Issues

## 1. Context

This runbook covers **secrets projection issues** where **External Secrets Operator (ESO)** fails to create or update Kubernetes `Secret` objects from **Azure Key Vault (AKV)** on **RKE2** in HybridOps.Studio.

Typical symptoms:

- `ExternalSecret` shows errors or never becomes **Synced / Ready**.  
- Expected Kubernetes `Secret` does not exist or has stale data.  
- Applications fail to start due to missing or invalid secrets (for example, database password, API keys).

This runbook assumes:

- ESO is the standard pattern for application secrets (ADR-0502).  
- RKE2 is the primary runtime (ADR-0202).  
- Secrets are modelled as `ExternalSecret` manifests in Git (HOWTO – ESO + AKV).

Severity is **P2** when:

- Critical applications (for example, NetBox) cannot start or authenticate.  
- Secret rotation fails and blocks DR or rollout.

---

## 2. Triggers

Use this runbook when:

- An application pod logs secret-related errors (for example, missing env vars, auth failures).  
- `ExternalSecret` objects report error conditions.  
- A recent secret rotation in AKV does not propagate to Kubernetes.  
- New environments or namespaces fail to receive required secrets.

If **multiple applications** or namespaces are impacted, suspect a **ClusterSecretStore / ESO / AKV** issue rather than a single app misconfiguration.

---

## 3. Preconditions and Safety

Before acting:

- Confirm you have access to:
  - The RKE2 cluster (kubectl).  
  - The namespace where `ExternalSecret` lives.  
  - Azure subscription with rights to view Key Vault configuration (read access is usually sufficient).

- Avoid:
  - Printing or storing raw secret values in logs, screenshots, or commit messages.  
  - Making ad-hoc changes that bypass Git for long-lived configuration (for example, hardcoding secrets in manifests).

- If the affected application is critical:
  - Notify stakeholders according to your incident channels.  
  - Record incident start time and impacted services.

---

## 4. Phase 1 – Identify scope and impacted components

1. **Identify failing application(s)**

   From logs or alerts, list impacted apps (for example, `netbox`, `demo-api`).

2. **Check namespace and ExternalSecret**

   For each app, identify its namespace (for example, `netbox`) and list ExternalSecrets:

   ```bash
   kubectl get externalsecret -n netbox
   ```

3. **Check Kubernetes Secret presence**

   For each expected Kubernetes Secret (for example, `netbox-db-credentials`):

   ```bash
   kubectl get secret netbox-db-credentials -n netbox
   ```

   Note whether the Secret:

   - Exists but is stale.  
   - Is missing entirely.

---

## 5. Phase 2 – Inspect ExternalSecret and store status

1. **Describe the ExternalSecret**

   ```bash
   kubectl describe externalsecret netbox-db-password -n netbox
   ```

   Review:

   - `Status` conditions.  
   - Error messages (for example, failed to fetch from store, auth issues).  

2. **Check SecretStore / ClusterSecretStore**

   Identify which store is referenced in `secretStoreRef` (for example, `akv-hybridops`):

   ```bash
   kubectl get clustersecretstore akv-hybridops
   kubectl describe clustersecretstore akv-hybridops
   ```

   Confirm:

   - The store exists.  
   - Conditions indicate it is **Ready**.

3. **Check ESO pods**

   In the ESO namespace (for example, `external-secrets`):

   ```bash
   kubectl get pods -n external-secrets
   kubectl logs deploy/external-secrets -n external-secrets
   ```

   Look for:

   - Connection/auth errors to AKV.  
   - Misconfiguration of the provider.

---

## 6. Phase 3 – Validate Azure Key Vault configuration

1. **Check Key Vault availability**

   Using Azure CLI:

   ```bash
   az keyvault show --name "<YOUR_KEYVAULT_NAME>"
   ```

   Confirm:

   - The Key Vault exists and is reachable.  
   - No obvious service outage in the region (check Azure status if in doubt).

2. **Confirm secret existence**

   ```bash
   az keyvault secret show      --vault-name "<YOUR_KEYVAULT_NAME>"      --name "netbox-db-password"
   ```

   Verify:

   - Secret name matches the `remoteRef.key` in the `ExternalSecret`.  
   - The secret is not disabled or expired.

3. **Review ESO identity permissions**

   Ensure the identity ESO uses (service principal or managed identity):

   - Has `get` (and optionally `list`) permission on secrets for the Key Vault.  
   - Has not been removed from Key Vault access policies or role assignments.

---

## 7. Phase 4 – Fix misconfiguration safely

### 7.1 ExternalSecret spec issues

If `ExternalSecret` points to the wrong secret name or store:

1. Edit the manifest in Git:

   - Correct `secretStoreRef` (kind and name).  
   - Correct `remoteRef.key` to match the AKV secret name.  
   - Confirm the namespace matches the workload namespace.

2. Commit and push with a clear message, for example:

   ```text
   fix: correct netbox ExternalSecret AKV key name
   ```

3. Allow Argo CD (or your GitOps tool) to sync, or apply in a lab environment:

   ```bash
   kubectl apply -f deploy/netbox/secrets/externalsecret-netbox-db-password.yaml
   ```

4. Re-check conditions:

   ```bash
   kubectl describe externalsecret netbox-db-password -n netbox
   ```

### 7.2 Store or credential issues

If `ClusterSecretStore` conditions report auth errors:

1. Confirm Kubernetes Secret holding credentials (if using service principal) exists and has correct keys:

   ```bash
   kubectl get secret akv-sp-credentials -n external-secrets
   kubectl describe secret akv-sp-credentials -n external-secrets
   ```

2. If client ID/secret/tenant changed:

   - Update the Secret with new values.  
   - Ensure no plaintext is logged or committed.  

3. If using managed identity:

   - Confirm the identity assignment on the node or pod host is still valid.  
   - Confirm Key Vault access policies/roles still include that identity.

4. After fixing credentials, restart ESO (if needed):

   ```bash
   kubectl rollout restart deploy/external-secrets -n external-secrets
   ```

5. Wait for ESO to reconcile and re-check ExternalSecret status.

---

## 8. Phase 5 – Verify workload recovery

1. **Confirm Kubernetes Secret is present and updated**

   ```bash
   kubectl get secret netbox-db-credentials -n netbox
   kubectl describe secret netbox-db-credentials -n netbox
   ```

   Do not print secret values. Use metadata and application behaviour to infer correctness.

2. **Restart or observe application pods**

   If pods previously failed due to missing secrets, they may restart automatically. If not:

   ```bash
   kubectl rollout restart deploy netbox -n netbox
   ```

3. **Check logs**

   Confirm the application now:

   - Connects successfully to its dependencies (for example, PostgreSQL).  
   - No longer logs secret-related auth errors.

4. **Capture evidence**

   Save:

   - ExternalSecret and ClusterSecretStore descriptions (with secrets redacted).  
   - High-level pod status and relevant log snippets.

   Under:

   ```bash
   docs/proof/runbooks/eso-akv-issues-<date>/
   ```

---

## 9. Phase 6 – Rotation-specific checks

If the incident was triggered by secret rotation:

1. **Confirm new version present in AKV**

   ```bash
   az keyvault secret show      --vault-name "<YOUR_KEYVAULT_NAME>"      --name "netbox-db-password"
   ```

2. **Confirm ESO refresh interval**

   In the `ExternalSecret` spec, verify `refreshInterval` is appropriate (for example, `1h`).

3. **Force refresh (if needed)**

   You can temporarily adjust `refreshInterval` in Git (to a shorter period) or trigger a reconcile by editing the ExternalSecret (for example, adding an annotation) and then reverting.

4. **Validate end-to-end**

   Confirm that:

   - AKV holds the new value.  
   - ESO updates the Kubernetes `Secret`.  
   - The application uses the new secret successfully.

---

## 10. Rollback and escalation

Escalate and consider temporary workarounds if:

- ESO or AKV is experiencing a wider outage, and  
- A critical service cannot function without updated secrets.

Short-term mitigations (to use sparingly):

- A one-off manually created Kubernetes `Secret` with minimal scope and a clear expiry plan.  
- Increased logging and monitoring around the affected workloads.

When normal ESO behaviour is restored:

- Remove any temporary manual Secrets.  
- Ensure Git manifests and AKV state reflect the intended long-term configuration.

---

## 11. Validation checklist

- [ ] Impacted applications and namespaces identified.  
- [ ] ExternalSecret and ClusterSecretStore conditions reviewed.  
- [ ] AKV secret existence and naming confirmed.  
- [ ] ESO credentials / identity and Key Vault permissions validated.  
- [ ] ExternalSecret spec corrected in Git where needed.  
- [ ] Kubernetes Secret created/updated and consumed by workloads.  
- [ ] Application logs show successful authentication / connectivity.  
- [ ] Proof artefacts captured under `docs/proof/runbooks/eso-akv-issues-<date>/`.  

---

## References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0502 – Use External Secrets Operator with Azure Key Vault for Application Secrets](../adr/ADR-0502-eso-akv-secrets.md)  
- [HOWTO – Project Secrets into RKE2 Using External Secrets Operator and Azure Key Vault](../howtos/HOWTO_eso_akv_secrets.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

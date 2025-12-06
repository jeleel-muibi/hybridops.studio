---
title: "Project Secrets into RKE2 Using External Secrets Operator and Azure Key Vault"
category: "platform"          # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Use External Secrets Operator (ESO) to project secrets from Azure Key Vault into RKE2, keeping application manifests declarative while centralising secret storage."
difficulty: "Intermediate"

topic: "eso-akv-secrets"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
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

# Project Secrets into RKE2 Using External Secrets Operator and Azure Key Vault

This HOWTO shows how to project secrets from **Azure Key Vault (AKV)** into an **RKE2** cluster using **External Secrets Operator (ESO)** in HybridOps.Studio.

You will:

- Create and name secrets in Azure Key Vault.  
- Configure ESO to read from AKV.  
- Define `ExternalSecret` resources in Git.  
- Verify that Kubernetes `Secret` objects are created and used by workloads.  

It aligns with:

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0502 – Use External Secrets Operator with Azure Key Vault for Application Secrets](../adr/ADR-0502-eso-akv-secrets.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Store application secrets centrally in Azure Key Vault.  
- Configure ESO to access AKV securely.  
- Represent secret needs declaratively via `ExternalSecret` manifests in Git.  
- Confirm that pods in RKE2 consume the projected Kubernetes `Secret` without handling raw values in manifests.

---

## 2. Prerequisites

### 2.1 Platform

You should have:

- An RKE2 cluster as described in Evidence 4.  
- External Secrets Operator installed and running in the cluster.  
- Network connectivity from the cluster to Azure Key Vault endpoints.

### 2.2 Azure

- An Azure subscription.  
- An Azure Key Vault instance created for HybridOps.Studio secrets.  
- An Azure AD identity that ESO can use:
  - Managed identity, or  
  - Service principal with access to Key Vault secrets.

### 2.3 Access and tools

- `kubectl` configured for the RKE2 cluster.  
- Access to the Git repository containing your deployment manifests.  
- Azure CLI or Portal access for Key Vault.

---

## 3. Phase 1 – Create a secret in Azure Key Vault

1. **Choose a secret name**

   Use a clear naming convention, for example:

   - `netbox-db-password`  
   - `demo-api-jwt-secret`

2. **Create the secret**

   Using Azure CLI (example):

   ```bash
   az keyvault secret set      --vault-name "<YOUR_KEYVAULT_NAME>"      --name "netbox-db-password"      --value "<STRONG_PASSWORD_VALUE>"
   ```

   Or create it via the Azure Portal with the same name.

3. **Record the secret identifier**

   Note:

   - Key Vault name  
   - Secret name  

   You will reference these from the ESO configuration.

---

## 4. Phase 2 – Configure ESO to access Azure Key Vault

> If ESO is already configured for AKV in your environment, review and reuse the existing `SecretStore` or `ClusterSecretStore` rather than creating duplicates.

1. **Create a Kubernetes Secret for credentials (if using client credentials)**

   For a service principal:

   ```bash
   kubectl create secret generic akv-sp-credentials      -n external-secrets      --from-literal=client-id="<APP_ID>"      --from-literal=client-secret="<APP_SECRET>"      --from-literal=tenant-id="<TENANT_ID>"
   ```

   Adjust the namespace to match where ESO expects credentials (for example, `external-secrets`).

   If you use workload identity or managed identity, this Secret may not be necessary; follow ESO’s AKV authentication guidance instead.

2. **Define a SecretStore or ClusterSecretStore**

   Example `ClusterSecretStore` for AKV:

   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ClusterSecretStore
   metadata:
     name: akv-hybridops
   spec:
     provider:
       azurekv:
         vaultUrl: "https://<YOUR_KEYVAULT_NAME>.vault.azure.net/"
         authType: ServicePrincipal
         tenantId:
           valueFrom:
             secretKeyRef:
               name: akv-sp-credentials
               namespace: external-secrets
               key: tenant-id
         clientId:
           valueFrom:
             secretKeyRef:
               name: akv-sp-credentials
               namespace: external-secrets
               key: client-id
         clientSecret:
           valueFrom:
             secretKeyRef:
               name: akv-sp-credentials
               namespace: external-secrets
               key: client-secret
   ```

   Apply it:

   ```bash
   kubectl apply -f infra/rke2/secrets/clustersecretstore_akv-hybridops.yaml
   ```

   Adjust the path to fit your repo structure.

3. **Verify ESO and store status**

   - Confirm ESO pods are running.  
   - Check that the `ClusterSecretStore` reports a ready status in ESO logs or via `kubectl describe`.

---

## 5. Phase 3 – Define an ExternalSecret in Git

You will now declare which AKV secret should appear as a Kubernetes `Secret` in a specific namespace.

1. **Create a directory for application secrets**

   For example, for `netbox`:

   ```bash
   mkdir -p deploy/netbox/secrets
   ```

2. **Create an ExternalSecret manifest**

   Example for NetBox DB password:

   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: netbox-db-password
     namespace: netbox
   spec:
     refreshInterval: "1h"
     secretStoreRef:
       kind: ClusterSecretStore
       name: akv-hybridops
     target:
       name: netbox-db-credentials
       creationPolicy: Owner
     data:
       - secretKey: DB_PASSWORD
         remoteRef:
           key: "netbox-db-password"
   ```

   Notes:

   - `remoteRef.key` is the AKV secret name.  
   - `target.name` is the Kubernetes `Secret` that will be created.  
   - `data.secretKey` is the key inside the Kubernetes `Secret` (for example, `DB_PASSWORD`).

3. **Commit and push**

   Commit `deploy/netbox/secrets/externalsecret-netbox-db-password.yaml` and push to the repo.

---

## 6. Phase 4 – Apply and validate in RKE2

If you use GitOps (Argo CD):

- Ensure the path `deploy/netbox/secrets/` is included in the Application’s manifest path or Kustomize configuration.  
- Allow Argo CD to sync the changes.

If you are applying directly (for a lab scenario):

```bash
kubectl apply -f deploy/netbox/secrets/externalsecret-netbox-db-password.yaml
```

Then validate:

1. **Check ExternalSecret status**

   ```bash
   kubectl get externalsecret -n netbox
   kubectl describe externalsecret netbox-db-password -n netbox
   ```

2. **Check the projected Kubernetes Secret**

   ```bash
   kubectl get secret netbox-db-credentials -n netbox
   kubectl get secret netbox-db-credentials -n netbox -o yaml
   ```

   Confirm that:

   - The `Secret` exists.  
   - It has a `DB_PASSWORD` key (value should be base64 encoded; do not decode or log it in plain text in shared artefacts).

3. **Capture evidence**

   Create a proof folder:

   ```bash
   mkdir -p docs/proof/secrets/eso-akv-netbox-<date>/
   ```

   Store:

   - Redacted `kubectl` output.  
   - Screenshots, if appropriate.

---

## 7. Phase 5 – Wire the Secret into the workload

Update the NetBox deployment (or another application) to consume the `netbox-db-credentials` Secret.

Example (fragment):

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: netbox-db-credentials
        key: DB_PASSWORD
```

- Commit and push the deployment manifest change.  
- Allow Argo CD to sync or apply directly in a lab context.  
- Confirm the application starts correctly using the secret from AKV via ESO.

---

## 8. Phase 6 – Rotate the secret

To demonstrate rotation:

1. **Update the secret in Azure Key Vault**

   ```bash
   az keyvault secret set      --vault-name "<YOUR_KEYVAULT_NAME>"      --name "netbox-db-password"      --value "<NEW_STRONG_PASSWORD>"
   ```

2. **Wait for ESO refresh**

   ESO will reconcile on the defined `refreshInterval` or when forced.

3. **Verify the Kubernetes Secret changed**

   - Check the `resourceVersion` or annotations on `netbox-db-credentials`.  
   - Avoid printing plaintext values; confirm via metadata and application behaviour (for example, app restarts or reconnects successfully if needed).

4. **Capture rotation evidence**

   Store relevant `kubectl` outputs and short notes under the same `docs/proof/secrets/eso-akv-netbox-<date>/` folder.

---

## 9. Validation checklist

- [ ] Azure Key Vault secret created with a clear name (for example, `netbox-db-password`).  
- [ ] ESO is installed and a `SecretStore` or `ClusterSecretStore` for AKV is configured and ready.  
- [ ] An `ExternalSecret` manifest in Git references the AKV secret and desired Kubernetes `Secret`.  
- [ ] A Kubernetes `Secret` is created in the target namespace and used by the application deployment.  
- [ ] The application runs correctly using the projected secret.  
- [ ] Secret rotation in AKV leads to an updated Kubernetes `Secret` without Git changes.  
- [ ] Proof artefacts stored under `docs/proof/secrets/eso-akv-<app>-<date>/`.  

---

## References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0502 – Use External Secrets Operator with Azure Key Vault for Application Secrets](../adr/ADR-0502-eso-akv-secrets.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation

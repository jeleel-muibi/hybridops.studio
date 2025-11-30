# Kubernetes Autoscaling Showcase (On‑Prem → Cloud)

Autoscaling/failover from on‑prem Kubernetes to **AKS/GKE** triggered by **Prometheus** alerts, orchestrated via **Jenkins/Terraform**.

- **Author:** Jeleel Muibi
- **Last Updated:** 2025-09-18
- **SPDX-License-Identifier:** MIT

## Layout
```
terraform/
ansible/
jenkins-pipeline/
diagrams/
```

## Flow
Alert → Pipeline → Provision → Route/Sync → Validate

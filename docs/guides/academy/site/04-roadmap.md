# HybridOps Academy — Roadmap

HybridOps Academy is built around the HybridOps.Studio platform and is intended to grow over time.  
This page outlines the planned direction so that learners, assessors, and potential partners can see how the Academy is evolving.

The roadmap is indicative and may change as the platform and community mature.

---

## Current status

**Flagship programme**

- **HybridOps Architect (6 weeks)**  
  Cohort-based programme covering hybrid DR, image-based builds, IaC with Terraform and Terragrunt, configuration with Ansible, observability, and multi-cloud connectivity across on-prem platforms (for example Proxmox and VMware) and public clouds (Azure, GCP, and selected AWS scenarios).

Supporting material is maintained in the public documentation and the Academy-specific guides.

---

## In development

The following items are under active design and prototyping. They build on the same repository, runbooks, and proof model.

### Specialist labs

**Network Automation and Multi-Vendor WAN Lab**

- Nornir and Ansible-driven automation.
- EVE-NG topologies with Fortinet, pfSense, VyOS, CSR1000v, Nexus or similar devices.
- Dual-ISP, BGP/OSPF, VRRP/CARP, VPN, and WAN failover validation.
- Focus on connecting traditional networking skills with automation and evidence.

**GitOps and Kubernetes SRE Lab**

- Argo CD and/or Flux on top of RKE2/AKS/GKE clusters.
- GitOps workflows for application and selected infrastructure changes.
- Deployment strategies (for example canary, blue/green) and rollback patterns.
- Integration with Prometheus federation and decision logic.

**Polyglot IaC Lab**

- Deep dive into Terraform and Terragrunt patterns used in HybridOps.Studio.
- Comparative view of Pulumi as a code-driven alternative for selected scenarios.
- Emphasis on design reuse, testing, and migration between tools.

These labs are intended for practitioners who have completed the flagship programme or have equivalent experience.

---

## Planned certification-aligned tracks

The following tracks are planned to align HybridOps.Studio lab work with common certification objectives:

- **Network skills with HybridOps**  
  Mapping the multi-vendor EVE-NG environment to network fundamentals and design topics (for example CCNA-style objectives), reinforced by automation.

- **Azure operations with HybridOps**  
  Using the platform’s Azure components and patterns to reinforce administrator-level skills (for example topics related to AZ-104).

- **Kubernetes and GitOps with HybridOps**  
  Using the existing clusters and GitOps workflows to practise application-level patterns and operational behaviours in line with Kubernetes-focused certifications.

These tracks will not duplicate official certification material. Instead, they provide realistic lab contexts and patterns that complement exam preparation.

---

## Public vs Academy-only material

HybridOps.Studio remains a public, evidence-backed portfolio. The documentation and proof archive will continue to expose:

- High-level architecture and design rationale.  
- A subset of ADRs, runbooks, and HOWTOs.  
- Selected showcases and proof examples.

Academy-only material, such as detailed lab notes, full walkthroughs of DR drills, and specialist topologies, is provided to participants as part of the programmes described above.

---

## Staying informed

Updates to the Academy roadmap will be reflected in:

- The public documentation under the Academy section.  
- Announcements on the main HybridOps.Studio site.  
- Cohort-specific information shared with enrolled participants.

For current cohort dates, availability, and enrolment details, refer to the Academy information on the main site.

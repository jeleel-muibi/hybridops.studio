# OS Baseline Rationale
**Document Type:** Technical Whitepaper  
**Maintainer:** HybridOps.Studio| HybridOps.Studio  
**Date:** 2025-11-10  
**Linked ADR:** [ADR-0017: Operating System Baseline](../../adr/ADR-0017-operating-system-baseline.md)

---

## 1. Purpose
This whitepaper defines the operating system (OS) selection rationale for *HybridOps.Studio* environments. It ensures platform consistency across on-premises, hybrid, and public cloud footprints while aligning with enterprise-grade support, compliance, and lifecycle requirements.

---

## 2. Baseline Overview
HybridOps.Studio implements a multi-OS baseline to reflect real-world enterprise ecosystems. This model enables cross-cloud portability, lifecycle resilience, and test fidelity across infrastructure, automation, and end-user domains.

| Layer | Platform | Role / Purpose | Support Lifecycle |
|--------|-----------|----------------|-------------------|
| **Primary Enterprise Base** | **Rocky Linux 9** → Future-ready to **Rocky Linux 10** | Core infrastructure, Proxmox templates, automation nodes | 2032 (Rocky 9), 2042 (Rocky 10 est.) |
| **Secondary Cloud/Control Layer** | **Ubuntu 24.04 LTS** | Control plane (CI/CD, Terraform, Ansible, observability) | 2029 (standard) + ESM to 2034 |
| **Compatible Alternative** | **AlmaLinux 9** | Drop-in RHEL-compatible fallback for non-Proxmox or cloud-native variants | 2032 |
| **Windows Infrastructure** | **Windows Server 2022 / 2025** | Hybrid domain services, management tools, and Windows workloads | 2031+ (aligned with LTSC cadence) |
| **End-User Simulation** | **Windows 11 Pro / Android (emulated)** | Endpoint validation, Intune/MDM testing, UX simulation | Continuous (rolling) |

---

## 3. Selection Rationale

### 3.1 Rocky Linux 9 (→10)
Chosen as the primary enterprise base OS for infrastructure and automation workloads.
- **RHEL-compatible:** 99.9% binary parity with Red Hat Enterprise Linux.
- **Governance:** Managed by the Rocky Enterprise Software Foundation (RESF) — neutral, community-first governance.
- **Enterprise Longevity:** 10-year lifecycle per major version; future-proofed by alignment with RHEL 10 roadmap.
- **Cloud Availability:** Official Rocky images available across AWS, Azure, and GCP.
- **Operational Consistency:** Common toolchain with RHEL/Ansible/OpenShift ecosystems.

### 3.2 Ubuntu 24.04 LTS
Adopted as the control and CI/CD layer OS for developer-aligned tooling and cloud-native services.
- **Cloud Dominance:** Default image across all major clouds.
- **Toolchain Support:** Strong integration with HashiCorp stack, GitHub Actions, and container runtimes.
- **Ease of Automation:** Superior cloud-init and systemd support.
- **Modern Packages:** Faster availability of newer software releases (e.g., Python 3.12, OpenSSH 9+).

### 3.3 AlmaLinux 9
Maintained as a technical equivalent of Rocky Linux for flexibility in non-Proxmox and vendor-managed environments.
- **RHEL-compatible:** Functionally identical to Rocky; interchangeable at runtime.
- **Commercial Backing:** Maintained by CloudLinux, offering enterprise contracts if required.
- **Governance Diversity:** Demonstrates optional vendor alignment for regulated enterprises.

### 3.4 Windows Server 2022 / 2025
Integrated to support hybrid operations, identity management, and Windows-specific workloads.
- **Hybrid Integration:** Compatible with Active Directory, DNS, and DHCP roles.
- **Infrastructure Compatibility:** Aligned with Azure AD Connect and Windows Admin Center.
- **Future Readiness:** Windows Server 2025 aligns with modern hardware, SMB over QUIC, and enhanced container support.

### 3.5 Windows 11 Pro / Android Simulation
Used for endpoint testing, management validation, and MDM (Intune) proof-of-concepts.
- **Windows 11 Pro:** Represents modern enterprise endpoints (hybrid join, BitLocker, MDM policies).
- **Android Emulation:** Optional, used for mobile app validation in enterprise mobility scenarios.

---

## 4. Strategic Justification

| Criterion | Rocky Linux | Ubuntu LTS | AlmaLinux | Windows Server | End-User Layer |
|------------|--------------|-------------|------------|----------------|----------------|
| Lifecycle | 10 years | 5 years + ESM | 10 years | 10 years | Rolling |
| Governance | Community (RESF) | Canonical Ltd. | CloudLinux Foundation | Microsoft | Vendor-controlled |
| Compliance | FIPS/STIG ready | CIS hardened | FIPS/STIG ready | ISO/FIPS certified | Varies |
| Cloud Coverage | All major clouds | All major clouds | All major clouds | Azure / hybrid | N/A |
| RHEL Compatibility | ✅ | ❌ | ✅ | ❌ | ❌ |
| Automation / IaC | Excellent | Excellent | Excellent | Moderate | N/A |
| Enterprise Perception | High | Moderate | High | Very High | Moderate |

---

## 5. Alignment with HybridOps.Studio Objectives
- **Demonstrates Multi-Cloud Portability** — identical automation blueprints across Proxmox, Azure, and GCP.
- **Enables Enterprise Credibility** — Rocky and Alma reflect RHEL enterprise standards.
- **Supports Modern DevOps** — Ubuntu covers developer ecosystems and rapid toolchains.
- **Covers End-to-End Scenarios** — Windows Server, Windows 11, and Android simulate enterprise-client integration.
- **Ensures Future Readiness** — Roadmapped for Rocky 10, Ubuntu 26.04 LTS, and Windows Server 2025.

---

## 6. Implementation Notes
- **Terraform/Terragrunt Modules:** Define `os_family` variable to select between `rocky`, `ubuntu`, or `windows` at plan time.
- **Packer Templates:** Maintain separate OS directories under `infra/packer-multi-os/`.
- **Ansible Roles:** Parameterize `ansible_os_family` for shared roles.
- **Continuous Validation:** CI pipelines test template parity and SSH provisioning for all OS baselines.

---

## 7. References
- ADR-0015: Network Infrastructure Assumptions  
- ADR-0016: Packer + Cloud-Init VM Templates  
- ADR-0017: Operating System Baseline  
- ADR-0018: LXC Containers for Lightweight Workloads  
- Vendor sources: RESF, Canonical, Microsoft, CloudLinux

---

**End of Document**

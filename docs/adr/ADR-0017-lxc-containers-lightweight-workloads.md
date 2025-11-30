---
id: ADR-0017
title: "LXC Containers for Lightweight Workloads on Proxmox"
status: Accepted
date: 2025-11-02
domains: ["platform", "infrastructure", "virtualization"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/platform/lxc-container-provisioning.md"]
  evidence: ["../proof/platform/lxc-containers/"]
  diagrams: []
---

# ADR-0017 — LXC Containers for Lightweight Workloads on Proxmox

## Status
**Accepted** — LXC containers are the standard compute platform for lightweight, stateless, and development workloads on Proxmox that do not require full VM isolation. Containers are provisioned directly via Terraform using Proxmox-provided OS templates without intermediate image building.

## Context

HybridOps.Studio operates a hybrid infrastructure where the on-premises Proxmox platform hosts both full virtual machines (ADR-0016) and lightweight container workloads. While full VMs provide complete isolation and bootable disk images, many workloads do not require this overhead and benefit from the efficiency of OS-level virtualization.

### Current State
The infrastructure currently provisions workloads exclusively as full virtual machines, even when complete kernel isolation is not required. This approach incurs unnecessary resource overhead for lightweight services such as:
- PostgreSQL database instances (ADR-0013)
- Development and testing environments
- Stateless application services
- CI/CD build agents
- Monitoring and logging collectors

### Problem Statement
Full virtual machines consume significant resources (CPU, memory, storage) and require longer provisioning times compared to containers. For workloads that do not require custom kernels, bootloaders, or complete security isolation, VMs introduce unnecessary complexity and cost.

LXC (Linux Containers) provides OS-level virtualization that shares the host kernel while maintaining process and filesystem isolation. This offers a middle ground between full VMs and Docker containers, suitable for long-running services that need persistent state and system-level access without full VM overhead.

### Requirements

**Technical Requirements**
- Fast provisioning times (seconds, not minutes)
- Lower resource consumption than full VMs
- Persistent storage for stateful services
- System-level access for service daemons (PostgreSQL, Redis, etc.)
- Network isolation and security boundaries
- Integration with existing Terraform and Ansible workflows
- Host-mounted storage for data persistence and backups

**Operational Requirements**
- Clear criteria for when to use LXC vs. full VMs
- Simplified provisioning without custom image building
- Ability to quickly spin up development and testing environments
- Efficient resource utilization on single Proxmox node
- Compatibility with existing backup and monitoring infrastructure

**Constraints**
- Single Proxmox node infrastructure
- Must coexist with full VM workloads
- Shared kernel limits isolation capabilities
- Cannot run custom kernel modules
- Must use unprivileged containers for security

## Decision

**Adopt LXC containers as the standard compute platform for lightweight workloads on Proxmox, provisioned directly via Terraform using Proxmox-provided OS templates without intermediate image building steps.**

### Core Principles
1. **Right-Sizing Compute**: Match workload isolation requirements to appropriate virtualization technology
2. **Resource Efficiency**: Minimize overhead for workloads that don't require full VM capabilities
3. **Operational Simplicity**: Eliminate unnecessary image building steps for container-appropriate workloads
4. **Clear Boundaries**: Maintain explicit decision criteria for VM vs. LXC selection
5. **Security Through Design**: Use unprivileged containers with appropriate capability restrictions

### Architectural Boundaries

**In Scope**
- **PostgreSQL database instances** running as LXC containers with host-mounted persistent storage (per ADR-0013)
- **Development and staging environments** for rapid iteration and testing
- **Stateless application services** that don't require custom kernels
- **Build agents and CI/CD workers** for ephemeral compute tasks
- **Monitoring and logging collectors** (Prometheus exporters, Fluent Bit, etc.)
- **Caching layers** (Redis, Memcached) with persistent or ephemeral storage
- **Utility services** (DNS servers, DHCP servers, jump hosts for dev environments)

**Explicitly Out of Scope**
- **Control plane VMs** (`ctrl-01`) — require full isolation per ADR-0016
- **RKE2 Kubernetes nodes** — require custom kernel modules per ADR-0016
- **Production application VMs** requiring high security boundaries per ADR-0016
- **Workloads requiring custom kernel modules** or boot configurations per ADR-0016
- **Windows-based workloads** (LXC is Linux-only)
- **Highly sensitive data processing** requiring complete kernel isolation
- **Workloads requiring KVM nested virtualization**

### Provisioning Model

**Direct Terraform Provisioning**
- LXC containers are provisioned directly using Terraform's Proxmox provider
- No intermediate image building step (unlike Packer for VMs in ADR-0016)
- Uses Proxmox-provided OS templates (Ubuntu, Debian, Rocky Linux, Alpine)
- Configuration applied via Terraform resource attributes and Ansible post-provisioning

**Template Sources**
- Proxmox built-in OS templates downloaded from official repositories
- Standard templates: `ubuntu-22.04-standard`, `debian-12-standard`, `rockylinux-9-default`
- No custom template building or maintenance required
- Updates handled by downloading new versions of Proxmox templates

## Decision Drivers

### Resource Efficiency
LXC containers share the host kernel and consume significantly less memory, CPU, and storage than equivalent full VMs. This is critical on a single-node Proxmox infrastructure where resource optimization directly impacts workload density and cost efficiency.

### Provisioning Speed
Container creation takes seconds compared to minutes for VM cloning and boot. This speed improvement is valuable for development environments, ephemeral build agents, and rapid testing workflows.

### Operational Simplicity
Eliminating the Packer image building step for lightweight workloads reduces operational complexity. Proxmox-provided templates are maintained upstream and require no custom build pipelines, versioning, or storage management.

### Workload Appropriateness
Many workloads (databases, caching layers, development environments) do not require the complete isolation of full VMs. Using containers for these workloads is architecturally appropriate and follows industry best practices.

### Complementary to VM Strategy
LXC containers complement rather than replace full VMs (ADR-0016). Together, they provide a balanced compute architecture that matches technology to workload requirements.

## Alternatives Considered

### Alternative 1: Full VMs for All Workloads
**Rejected** — Resource inefficient for lightweight services. Unnecessary overhead for workloads that don't require complete isolation.

**Analysis:**
- Complete isolation for all workloads
- Consistent provisioning workflow
- Excessive resource consumption on single-node infrastructure
- Slower provisioning times for development and testing
- Does not match workload requirements to appropriate technology

### Alternative 2: Docker Containers on VM Host
**Rejected** — Docker is appropriate for stateless microservices but less suitable for long-running system services like PostgreSQL that need direct system-level access and persistent storage.

**Analysis:**
- Industry-standard container runtime
- Rich ecosystem of pre-built images
- Less suitable for system services requiring full init systems
- Complex persistent storage management
- Namespace limitations for database workloads
- LXC provides better fit for system-level services

### Alternative 3: Kubernetes Pods for All Workloads
**Rejected** — Kubernetes introduces unnecessary orchestration complexity for simple, single-instance services on a single Proxmox node.

**Analysis:**
- Cloud-native orchestration
- Self-healing and scaling capabilities
- Massive overhead for single-instance services
- Requires RKE2 cluster infrastructure (chicken-and-egg for control plane)
- Inappropriate for stateful services like PostgreSQL on single node
- Reserved for multi-node, orchestrated workloads

### Alternative 4: Build Custom LXC Templates with Packer
**Rejected** — Adds unnecessary complexity. Proxmox-provided templates are sufficient and well-maintained for LXC use cases.

**Analysis:**
- Consistent template building approach with VMs
- Custom hardening baked into images
- Proxmox templates already provide secure, minimal baselines
- LXC configuration simple enough to apply at runtime
- Adds build pipeline complexity without commensurate benefit
- Violates principle of operational simplicity

## Consequences

### Positive Outcomes

**Operational**
- Container provisioning completes in seconds vs. minutes for VMs
- Reduced resource consumption enables higher workload density
- Simplified provisioning without custom template maintenance
- Faster development and testing iteration cycles
- Lower barrier to spinning up experimental environments

**Technical**
- Appropriate technology selection for workload requirements
- Balanced infrastructure combining VMs and containers
- Efficient resource utilization on single-node infrastructure
- Maintains security boundaries through unprivileged containers
- Host-mounted storage enables robust backup strategies (per ADR-0013)

**Organizational**
- Clear decision matrix for VM vs. LXC selection
- Demonstrates understanding of appropriate technology choices
- Reduces infrastructure costs through efficiency
- Enables rapid experimentation and learning

### Negative Outcomes

**Operational**
- Team must understand and maintain two provisioning workflows (VM and LXC)
- Risk of confusion about when to use VMs vs. containers
- Different security models require different hardening approaches
- Backup strategies differ between VMs and containers

**Technical**
- Shared kernel limits isolation capabilities
- Cannot run custom kernel modules or parameters
- UID/GID mapping complexity for host-mounted storage
- Slightly reduced isolation compared to VMs
- Not suitable for all workload types

**Organizational**
- Requires team training on LXC-specific considerations
- Decision criteria must be clearly documented and followed
- Potential for technology sprawl if not disciplined

### Risk Analysis

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Team confusion about VM vs. LXC selection | Medium | Medium | Clear decision matrix in documentation; code review enforcement; team training |
| Security boundary violations due to kernel sharing | High | Low | Use unprivileged containers; capability restrictions; security auditing; appropriate workload classification |
| UID/GID misalignment breaks host storage mounts | Medium | Medium | Standardized UID/GID mapping; documented procedures; automated validation |
| Proxmox template updates break containers | Low | Low | Pin template versions in Terraform; test updates in dev before production |
| Inappropriate workloads deployed as containers | Medium | Medium | Enforce decision criteria in code review; architectural governance |

## Implementation Considerations

### Workload Classification Matrix

Decision criteria for VM (ADR-0016) vs. LXC (this ADR):

| Criterion | Use Full VM (ADR-0016) | Use LXC Container (This ADR) |
|-----------|------------------------|------------------------------|
| **Isolation Requirements** | High security boundaries, production control plane | Development, staging, low-criticality services |
| **Kernel Requirements** | Custom modules, parameters, or nested virtualization | Standard kernel sufficient |
| **Resource Profile** | High CPU/memory needs, or already resource-efficient | Lightweight, optimize for density |
| **Workload Type** | Control plane, RKE2 nodes, high-security apps | Databases (PostgreSQL), caching, dev environments |
| **State Management** | VM disk-based state | Host-mounted storage or ephemeral |
| **Provisioning Speed** | Not critical | Fast iteration needed |
| **Portability** | May migrate to other platforms | On-prem only acceptable |

### Storage Architecture
- **Persistent Data**: Host-mounted directories (e.g., `/srv/db01-data` → `/var/lib/postgresql`)
- **Container Root**: Local-LVM storage for container filesystem
- **Backup Strategy**: Host-level snapshots (ZFS) and application-level backups (WAL-G for PostgreSQL)

### Security Model
- **Unprivileged Containers**: All containers run as unprivileged by default
- **Capability Restrictions**: Minimal capabilities granted via Proxmox features
- **Network Isolation**: Dedicated VLANs per environment (VLAN 10/20/30)
- **UID/GID Mapping**: Standardized subuid/subgid ranges documented

### Integration Points
- **Terraform**: Provisions containers using `proxmox_lxc` resource
- **Ansible**: Configures container services post-creation
- **NetBox**: Documents container inventory and network assignments
- **Monitoring**: Prometheus exporters run inside containers
- **Backups**: Host-level tooling for persistent storage; application-level for databases

### Success Metrics
- Container provisioning time ≤ 30 seconds
- Resource utilization 30-50% lower than equivalent VMs
- Zero security incidents related to container isolation
- Team correctly classifies 95%+ of workloads (VM vs. LXC)
- PostgreSQL performance meets or exceeds VM baseline (per ADR-0013)

## Monitoring and Review

### Operational Metrics
- Container provisioning success rate and duration
- Resource consumption per container vs. equivalent VM
- Number of containers vs. VMs by workload type
- UID/GID mapping issues encountered
- Security boundary violations or capability escalations

### Review Triggers
This decision should be reviewed when:
- Security incidents related to container isolation occur
- Team consistently misclassifies workloads (VM vs. LXC)
- Proxmox platform undergoes major version upgrade
- New workload types emerge that challenge decision criteria
- Performance issues attributed to shared kernel limitations
- After 6 months of production operation (2025-05-02)

### Exit Criteria
Reconsider this decision if:
- Security requirements mandate full VM isolation for all workloads
- Kubernetes orchestration becomes standard for all services
- Platform migration to cloud-only eliminates Proxmox infrastructure
- Container isolation proves inadequate for assumed workloads
- Team consensus favors simpler single-technology approach

## References

### Internal Documentation
- ADR-0016: Packer with Cloud-Init for VM Template Standardization (complementary decision)
- ADR-0013: PostgreSQL Runs in LXC (specific workload implementation)
- Runbook: LXC Container Provisioning (docs/runbooks/platform/lxc-container-provisioning.md)
- Evidence: LXC Container Deployments (docs/proof/platform/lxc-containers/)

### External Standards
- Proxmox LXC Documentation: https://pve.proxmox.com/wiki/Linux_Container
- LXC Project Documentation: https://linuxcontainers.org/lxc/
- Terraform Proxmox Provider - LXC: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/lxc

### Related ADRs
- ADR-0016: Packer with Cloud-Init for VM Template Standardization (complementary)
- ADR-0013: PostgreSQL Runs in LXC (workload-specific implementation)
- ADR-0002: Terraform with Terragrunt for Infrastructure Provisioning (planned)
- ADR-0003: Ansible for Post-Provisioning Configuration Management (planned)
- ADR-0004: NetBox as Infrastructure Source of Truth (planned)

---

**Author:** Jeleel Muibi  
**Date:** 2025-11-02  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0

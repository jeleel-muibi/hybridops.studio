
---
id: ADR-0019
title: "Jenkins Architecture with LXC Ephemeral Agents"
status: Proposed
date: 2025-11-02
domains: ["cicd", "platform", "orchestration"]
---

# ADR-0019: Jenkins Architecture with LXC Ephemeral Agents

**Author:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT-0

## Overview

Use **LXC ephemeral agents** as the primary Jenkins execution platform during bootstrap and steady-state infrastructure automation. Fall back to **VM agents** for workloads that require nested virtualization or stronger isolation, and adopt **Kubernetes pod agents** after RKE2 is available for application CI/CD.

```text
┌─────────────────────────────────────────────────────────┐
│                 Jenkins Controller (ctrl-01 VM)         │
│  - Master process (port 8080)                           │
│  - Job orchestration                                    │
│  - Pipeline definitions                                  │
│  - Credential management                                 │
│  - Proxmox API integration                               │
└─────────────────────────────────────────────────────────┘
              │                   │                    │
              ▼                   ▼                    ▼
    ┌──────────────────┐   ┌─────────────┐    ┌──────────────────┐
    │   LXC Agents     │   │  VM Agents  │    │ K8s Pod Agents   │
    │   (Primary)      │   │ (Exception) │    │    (Future)      │
    └──────────────────┘   └─────────────┘    └──────────────────┘
         │     │                 │                   │
         │ Terraform/Ansible     │ Packer/Docker     │ Helm/App CI
         │ Git/Python/Go         │ Untrusted PRs     │ Multi-cluster
         │ Fast (5–10s)          │ Slow (45s+)       │ Post-RKE2
```

---

## Agent Strategy by Workload

| Workload Type | Agent Platform | Rationale |
|---|---|---|
| **Terraform plan/apply** | LXC | Fast provisioning, stateless, trusted code |
| **Ansible playbook execution** | LXC | SSH-based, no special requirements, trusted |
| **Git operations** (clone, push, pull) | LXC | Lightweight, fast, no isolation needs |
| **Python/Go testing** | LXC | Quick startup, disposable, internal code |
| **Shell scripts** (backup, utilities) | LXC | Minimal overhead, trusted scripts |
| **Docker image builds** | VM | Docker-in-Docker safer with full isolation |
| **Packer VM builds** | VM | Requires nested virtualization / Proxmox API |
| **Untrusted PR builds** | VM | Kernel isolation for external code |
| **RKE2 workload deployments** | K8s Pod | Post-RKE2 only, cloud-native context |

---

## Phased Implementation

**Phase 0: Bootstrap (Current)**  
- Controller: `ctrl-01` VM  
- Agents: **LXC only** (RKE2 not yet available)  
- Scope: Infra provisioning (Terraform, Ansible)

**Phase 1: Steady-State (Post-RKE2)**  
- Controller: `ctrl-01` VM (unchanged)  
- Agents: Hybrid (**LXC** for IaC, **K8s pods** for apps)  
- Scope: Infra + app CI/CD

**Phase 2: Multi-Cloud (Future)**  
- Controller: `ctrl-01` VM (unchanged)  
- Agents: Multi-platform (LXC, K8s on‑prem, **AKS** pods, **GKE** pods)  
- Scope: Hybrid multi-cloud orchestration

---

## Decision Drivers

### Bootstrap Independence
**Problem:** Kubernetes (RKE2) doesn't exist during bootstrap.  
**Decision:** LXC agents provide compute without a Kubernetes dependency, avoiding circular dependency.

### Provisioning Speed
- **LXC agent:** 5–10 seconds from request to ready  
- **VM agent:** 45+ seconds (clone + boot + cloud‑init)  
- **Impact:** 100 builds/day ≈ **13 min** (LXC) vs **75 min** (VM)

### Resource Efficiency
- **Memory:** LXC ~50 MB vs VM ~512 MB (≈90% reduction)  
- **Storage I/O:** Overlayfs vs full disk clone  
- **Density:** 50+ LXC vs 10–20 VMs per node (single-node constraint)

### Appropriate Isolation
- Infrastructure code is internal/trusted, version-controlled.  
- Unprivileged LXC containers give adequate isolation for trusted IaC workloads.  
- Use VMs for untrusted or isolation‑sensitive tasks.

### Operational Simplicity
- No custom image pipeline initially (uses Proxmox templates—see ADR‑0017).  
- Fast iteration, easy cleanup, minimal maintenance.  
- VMs reserved for niche cases (ADR‑0016).

### Future Flexibility
- Start with LXC.  
- Add K8s pod agents post‑RKE2 for app CI/CD.  
- Keep LXC for infra pipelines that benefit from speed and simplicity.

---

## Alternatives Considered

### 1) VM Agents for All Workloads — **Rejected**
- ✅ Max isolation; aligns with a full‑VM posture.  
- ❌ Slow startup; high resource overhead; lower density; over‑engineering for trusted infra code.

### 2) Static Agents on ctrl-01 VM — **Rejected**
- ✅ Simple to set up.  
- ❌ Violates ephemeral principles; poor concurrency; state pollution; security risk.

### 3) Wait for RKE2, Use Kubernetes Pod Agents — **Rejected**
- ✅ Cloud‑native, scalable.  
- ❌ Chicken‑and‑egg problem; blocks bootstrap; not viable initially.

### 4) Docker Containers on ctrl-01 — **Rejected**
- ✅ Common runtime, rich ecosystem.  
- ❌ Adds Docker daemon & storage complexity; no benefit over LXC for IaC.

### 5) Cloud-Based Agents (GitHub Actions/GitLab CI) — **Rejected**
- ✅ Managed service, no local compute.  
- ❌ External dependency; latency to on‑prem APIs; cost; violates hybrid principles.

---

## Consequences

### Positive
- Fast pipelines (5–10s agent startup), high concurrency on one Proxmox node.  
- Minimal ops overhead; ephemeral agents prevent state pollution.  
- No bootstrap circular dependency; appropriate isolation for trusted code.  
- Clear separation: infra (LXC) vs apps (future K8s pods).

### Negative
- Shared‑kernel isolation is weaker than full VMs.  
- Two agent types to maintain (LXC + VM exceptions; later K8s).  
- Need governance to avoid agent sprawl and confusion.

### Risk Analysis
| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| LXC provisioning failures block pipelines | High | Low | Fallback static agent; monitoring; retries |
| Shared kernel vulnerability exploited | High | Low | Unprivileged LXC, AppArmor, trusted code, audits |
| Agent sprawl exhausts resources | Medium | Medium | Quotas, auto-cleanup ≤ 1h idle, dashboards |
| Confusion on agent selection | Medium | Medium | Decision matrix; code review; Jenkinsfile templates |
| UID/GID mapping issues | Medium | Medium | Standard subuid/subgid ranges; validation |
| Network isolation/secrets exposure | High | Low | Dedicated VLAN; credential binding; firewalling |
| Migration to K8s disrupts jobs | Medium | Low | Phased rollout; keep LXC for infra pipelines |

---

## Implementation Considerations

### Jenkins Controller (ctrl-01 VM)
- **OS:** Ubuntu LTS (from Packer template)  
- **Jenkins:** LTS; managed via Ansible/JCasC  
- **Plugins:** Proxmox Cloud, JCasC, Pipeline, Credentials Binding, Git  
- **Sizing:** vCPU 4, RAM 8GB, Disk 100GB, Network on VLAN 10 (Mgmt)

### LXC Agent Template
- **Module:** `modules/compute/proxmox/jenkins-agent-lxc`  
- **Spec:** vCPU 2, RAM 2GB, Disk 8GB, VLAN 20 (DHCP), unprivileged  
- **Lifecycle:** On-demand, reused up to 1h idle, then auto-destroyed  
- **Tools:** OpenJDK 17, Terraform, Ansible, Git, Python 3.10+, Go, curl/wget/jq/yq

### Provisioning Flow
1. Pipeline triggers.  
2. Jenkins requests an agent from Proxmox.  
3. Terraform provisions unprivileged LXC (≈5–10s).  
4. Ansible ensures toolchain; agent connects to Jenkins.  
5. Job runs; on idle ≥1h, destroy; clean state.

### Security Model
```ini
# LXC (unprivileged) example
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
lxc.apparmor.profile = generated
```
**Network:** Agents on VLAN 20; firewall allows outbound HTTP/HTTPS and SSH to managed hosts; no direct access to VLAN 10 (Mgmt) or 30 (Windows).  
**Credentials:** Use Jenkins Credentials & binding at runtime; no secrets persisted on agents.  
**Workspace:** Ephemeral root FS; no persistent workspace.

### Decision Matrix Helper (Groovy)
```groovy
def selectAgent(workloadType) {
  switch(workloadType) {
    case 'terraform':
    case 'ansible':
    case 'git':
    case 'python':
      return 'lxc-standard'   // LXC agent
    case 'packer':
    case 'docker':
    case 'untrusted':
      return 'vm-isolated'    // VM agent
    case 'rke2-deploy':
      return 'kubernetes'     // K8s pod (post-RKE2)
    default:
      error("Unknown workload type: ${workloadType}")
  }
}
```

---

## Monitoring & Success Metrics

**Track:** provisioning time (p50/p95/p99), active/idle agent counts, CPU/RAM per agent, queue time, failures (provision/exec/cleanup), compute-hours per pipeline.  
**Dashboards:** Grafana (Jenkins exporter), Proxmox views, Jenkins queue/agents.  
**Alerts:** provisioning failure rate >5%, active agents >50, avg queue time >30s.

**Targets:** p95 startup ≤10s; success rate ≥95%; ≥20 concurrent agents; node ≤50% RAM and ≤70% CPU; zero isolation incidents; 95%+ correct agent selection in reviews.

---

## Governance & Review

**Review when:** RKE2 is live; provisioning failures >10%; resource exhaustion limits concurrency; any isolation incident; persistent developer friction; new workload types (e.g., Windows).  
**Time-boxed review:** After 3 months of production (2026-02-02).

**Exit criteria:** LXC reliability degrades; pod agents superior across the board; security mandates full VM isolation; strategic move to cloud agents; Proxmox decommissioned; strong team consensus to change.

---

## Related & References

**Internal**  
- ADR-0016: Packer VM Templates (ctrl-01 platform)  
- ADR-0017: LXC Containers for Lightweight Workloads (agent compute)  
- ADR-0013: PostgreSQL Runs in LXC (related example)  
- Runbook: *Jenkins Agent Management* (`docs/runbooks/cicd/jenkins-agent-management.md`) — *TBD*  
- HOWTO: *Create a Jenkins Pipeline with LXC Agents* (`docs/howtos/jenkins-lxc-pipeline.md`) — *TBD*  
- Evidence: *Jenkins LXC Agent Deployments* (`docs/proof/cicd/jenkins-lxc-agents/`) — *TBD*

**External**  
- Jenkins Documentation — https://www.jenkins.io/doc/  
- Jenkins Proxmox Plugin — https://plugins.jenkins.io/proxmox/  
- Pipeline Best Practices — https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/  
- Configuration as Code — https://github.com/jenkinsci/configuration-as-code-plugin

---

## ADR Summary (Context)

| ADR | Title | Status | Purpose |
|---|---|---|---|
| **ADR-0016** | Packer VM Templates | Accepted | Platform: How to build VM templates |
| **ADR-0017** | LXC Containers | Proposed | Platform: When to use LXC vs VM |
| **ADR-0018** | Jenkins + LXC Agents | Proposed | CI/CD: How Jenkins orchestrates IaC |

---

## Acceptance Criteria

Change status to **Accepted** when:  
1) `ctrl-01` VM has Jenkins installed.  
2) First LXC agent provisions and runs a pipeline.  
3) Terraform module for agent provisioning is validated.  
4) Workload classification is embedded in Jenkinsfile templates.

---

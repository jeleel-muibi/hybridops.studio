# HybridOps.Studio — Zero‑Touch Hybrid Cloud Automation Blueprint

HybridOps.Studio is a self‑bootstrapping hybrid infrastructure lab that automates control plane setup, DR orchestration, and CI/CD pipelines across on‑prem and cloud environments — entirely from Git.

From a single Proxmox command, the control plane (Jenkins `ctrl‑01`) builds itself, provisions infrastructure on ephemeral agents, and writes audit‑ready evidence back into Git.

## It demonstrates:
- Enterprise‑grade reproducibility and auditability.
- Multi‑cloud DR with PostgreSQL replication and policy‑driven failover.
- End‑to‑end GitOps with Argo CD / Flux and federated Prometheus observability.

### Try it yourself (no setup needed):
```bash
ssh demo@hybridops.studio
# password: TryHybridOps!
curl -fsSL https://raw.githubusercontent.com/jeleel-muibi/hybridops.studio/main/control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh   -o demo.sh && sudo bash demo.sh

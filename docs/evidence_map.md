# Evidence Map — HybridOps.Studio
_Map each claim in the README to a concrete proof (panel, log, config, code). Use direct, public URLs._

## KPIs
| Claim                                | Proof Type                       | Link |
|--------------------------------------|----------------------------------|------|
| **RTO ≤ 15m**                        | Grafana DR panel + failover run  | (URL) |
| **RPO ≤ 5m**                         | Replication lag panel / AG graph | (URL) |
| **Packer ≤ 12m**                     | CI run log + artifact            | (URL) |
| **Terraform ≤ 10m**                  | Terraform Cloud run page         | (URL) |
| **Autoscale +2@70% (scale-in <40%)** | Grafana chart + K8s events trace | (URL) |

## Architecture Assertions
| Claim                                             | Proof Type                                 | Link |
|---------------------------------------------------|--------------------------------------------|------|
| **NCC hub-and-spoke**                             | Topology screenshot + hub/spokes JSON      | [notes](./proof/ncc/notes.md) |
| **Prometheus federation (on-prem ↔ cloud)**       | Scrape config + federation dashboard       | [notes](./proof/observability/notes.md) |
| **SQL WSFC → Azure RO**                           | Replica status dashboard + config          | [notes](./proof/sql-ro/notes.md) |
| **Runtime images built & mirrored (Blob/GCS)** | CI run + Packer template + storage listing | [notes](./proof/images-runtime/notes.md) |
| **Burst-to-cloud Kubernetes (AKS/GKE)**           | `kubectl get nodes` before/after + events  | [notes](./proof/burst-k8s/notes.md) |
| **Site-to-site IPsec (Site-A↔B1↔B2)**             | Device VPN status + logs                   | [notes](./proof/vpn/notes.md) |
| **Multivendor routing (OSPF/BGP/VRRP/HSRP/CARP/STP)** | Router configs + path tests | [Routing pack](./proof/others/multivendor-routing.md) |
| **Decision Service (policy-governed, cost/SLO aware)** | Policy file → CI trigger run | [notes](./proof/decision-service/notes.md#policy--orchestration) |
| **Cloud monitor signals → Decision Service**           | Alert policy → webhook → CI  | [notes](./proof/decision-service/notes.md#cloud-signals) |
| **Governance pipeline (approvals/audit)**             | CI rules + audit artifact   | [Governance pack](./proof/others/governance.md) |

## Recognition & Demos
| Claim                                                  | Proof Type                    | Link |
|--------------------------------------------------------|-------------------------------|------|
| **Product-led blueprint**                              | GitHub repo — architecture    | https://github.com/jeleel-muibi/hybridops.studio#architecture |
| **Public automation roles**                            | Ansible Galaxy listing        | (URL) |
| **Talk / live failover demo**                          | YouTube video                 | (URL) |
| **Foundational BSc Nornir project (seeded patterns)**  | Public GitHub repo            | [Network automation & abstraction](https://github.com/jeleel-muibi/Network_automation_and_Abstraction) |

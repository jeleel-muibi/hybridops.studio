# Proof Archive

The proof archive collects curated operational evidence for HybridOps.Studio.  
It backs up key claims about automation, resilience, disaster recovery, networking, and cost with concrete artefacts.

Evidence is organised by theme so you can move from a high-level statement to supporting logs, screenshots, and JSON output in a few clicks.

---

## Layout

The archive lives under `docs/proof/` and is structured as follows:

- `burst-k8s/`  
  Evidence for Kubernetes burst and autoscaling scenarios, including images and references into runtime metrics.

- `cost/`  
  Cost-related summaries and supporting files, including `summary.md` and timestamped estimate folders.

- `decision-service/`  
  Evidence for the decision service and its impact on autoscale, burst, and DR flows.

- `images-runtime/`  
  Screenshots and related artefacts captured during image build and runtime validation.

- `ncc/`  
  Artefacts related to Network Connectivity Center and multi-cloud connectivity flows.

- `observability/`  
  Evidence from observability tooling (for example Prometheus and Grafana) that underpins autoscale, DR, and capacity decisions.

- `platform/packer-builds/`  
  Evidence for Packer image builds and init flows, including logs, JSON summaries, and `latest` symlinks for each image type.

- `sql-ro/`  
  Artefacts showing SQL read-only patterns and related DR scenarios.

- `vpn/`  
  Evidence related to VPN configuration, connectivity, and failover behaviour.

- `others/`  
  Additional artefacts such as governance and multi-vendor routing evidence that do not fit neatly into the categories above.

---

## KPI evidence shortcuts

Use these as starting points when you want to see proof for specific targets or guarantees.

- **DR timings (RTO / RPO)**  
  - DR drill metrics and screenshots: `observability/`  
  - SQL read-only and RPO behaviour: `sql-ro/`

- **Image build timings**  
  - Packer build evidence, by image type: `platform/packer-builds/` and `images-runtime/`

- **Autoscaling and burst behaviour**  
  - Decision inputs and actions: `decision-service/`  
  - Runtime effect on workloads: `burst-k8s/` and `observability/`

- **Network and connectivity**  
  - NCC and multi-cloud connectivity: `ncc/`  
  - VPN and site-to-site tunnels: `vpn/`  
  - Governance and multi-vendor routing: `others/`

Each of these folders contains a `README.md` describing what is being proven and how to interpret the artefacts.

---

## Relationship with `output/`

The `docs/proof/` tree is the curated, documentation-facing layer.  
The `output/` tree contains the raw logs and artefacts produced by pipelines and scripts.

Typical mapping:

- `output/logs/packer/...` → referenced from `platform/packer-builds/` and `images-runtime/`.  
- `output/logs/terraform/...` → referenced from decision, DR, or cost-related proof.  
- `output/artifacts/...` → inventories, state extracts, and other structured outputs linked from the relevant proof folders.

Where practical, proof README files point to:

- Specific runs (for example a dated folder under `platform/packer-builds/`), and  
- The `latest` symlink for a given flow, so you can inspect either individual runs or the most recent successful one.

---

## How to use this archive

If you are:

- **An assessor or hiring manager** — start from the [Evidence Map](../evidence_map.md), then follow links into the proof folders listed above to validate specific claims.  
- **A learner or practitioner** — follow the relevant showcase first, then use the links from the showcase README into `docs/proof/` to see the evidence for that scenario.  
- **Working on the platform** — when you introduce a new capability or adjust an existing one, extend the appropriate folder here and update its `README.md` so the documented behaviour stays backed by concrete runs and artefacts.

The structure is intentional: each documented behaviour should be traceable to concrete evidence in `docs/proof/` and, where relevant, to the underlying code and pipelines.

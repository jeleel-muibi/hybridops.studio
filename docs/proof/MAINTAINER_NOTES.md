# MAINTAINER_NOTES.md (Private) — HybridOps.Studio
Updated: 2025-09-22 (UTC)

> Keep this file **out of Git**. Add to `.gitignore`:
>
> ```
> MAINTAINER_NOTES.md
> ```

## Purpose
Quick rules for keeping **proof packs**, the **Evidence Map**, and **social preview** current — without leaking real IPs or secrets.

## Update Cadence (TL;DR)
- **After any demo or infra change:** refresh the relevant *proof pack* (`docs/proof/<slug>/`).
- **Monthly:** sanity‑check Grafana/TFC links still resolve; bump timestamps in pack notes.
- **When the overview diagram changes:** re‑export 3840‑px PNG and 1280×640 social preview.

## Proof packs — cheat sheet
| Pack slug | `images/` focus | `links.txt` focus | `notes.md` hint |
|---|---|---|---|
| `ncc/` | Hub + spokes topology, route table | Hub/spoke JSON (console deep links) | Spoke names/regions; capture time (UTC). |
| `observability/` | Federation targets, on‑prem targets, Grafana | Grafana panel deep links | Recording rules/alerts feeding Decision Service. |
| `sql-ro/` | RO replica status, AG/log‑shipping | Replication lag panel, SQL dashboard | RPO target + test window. |
| `images-runtime/` | Packer success, artifact name/version | CI run URL; template path | Image IDs/checksums if available. |
| `artifacts/` | Azure Blob & GCS listings | Direct listing URLs; checksums | Visible timestamps in UI. |
| `vpn/` | pfSense/CSR IPsec status | Device UI deep links / exported JSON | Which tunnels are A↔B1↔B2 and A↔NCC. |
| `network-protocols/` | Neighbor tables (BGP/OSPF), path tests | Links to sanitized configs/test logs | Communities/local‑pref policy. |
| `decision-service/` | Policy snippet, CI run, scale events | Policy file commit; CI run URL | Inputs: SLO, credits/cost, cloud signals. |
| `burst-k8s/` | `kubectl get nodes` before/after, VMSS/MIG | Autoscaler/scale‑set event links | Tie back to KPI autoscale +2@70%.


## Evidence Map — how to update
1. Drop screenshots in `docs/proof/<slug>/images/`.
2. Paste **deep links** into `docs/proof/<slug>/links.txt`.
3. Update `docs/evidence_map.md` to point to the pack’s `notes.md` (keeps the table tidy).
4. Commit: `docs(proof): refresh <slug> (UTC <YYYY‑MM‑DD>)`.

## Social preview (GitHub)
- Export: `docs/diagrams/flowcharts/renders/social-preview_1280x640.png`.
- Upload: **Settings → General → Social preview**.
- Keep the card **minimal** (title only).

## Safety
- **No real IPs** or secrets in screenshots or URLs.
- Prefer **read‑only** dashboards/run pages.
- Redact tenant/subscription/project IDs.

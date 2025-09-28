# quick run script for one-off commands

# from repo root
mkdir -p docs/proof/others/assets

# empty placeholder PDFs (optional – replace with real exports)
: > docs/proof/others/assets/governance_evidence.pdf
: > docs/proof/others/assets/multivendor_routing_evidence.pdf

# governance.md
cat > docs/proof/others/governance.md <<'EOF'
# Governance — Proof Pack
_Last updated: 2025-09-21 (UTC)_

## What this proves
- Approvals/windows enforced in CI.
- Audit artifacts present and retained.

## Direct links (public where possible)
- (URL to CI rules/policy)
- (URL to audit artifact or run page)

## Screenshots / PDFs
- `./assets/governance_evidence.pdf` (exported screenshots)

## Notes
- Include correlation/run IDs and timestamp (UTC).
EOF

# multivendor-routing.md
cat > docs/proof/others/multivendor-routing.md <<'EOF'
# Multivendor Routing — Proof Pack
_Last updated: 2025-09-21 (UTC)_

## What this proves
- OSPF/BGP neighbors established across vendors (Cisco/Arista/Fortinet/pfSense).
- Path tests succeed; policy (communities/local-pref) applied.

## Direct links (public where possible)
- (URL to sanitized configs in repo)
- (URL to test logs or CI run)
- (Optional) (URL to topology page)

## Screenshots / PDFs
- `./assets/multivendor_routing_evidence.pdf` (exported screenshots)

## Notes
- Call out which neighbors/paths are shown and capture window (UTC).
EOF

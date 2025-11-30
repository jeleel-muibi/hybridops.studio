#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo ../..)}"
EVID="$ROOT/showcases/hybrid-failover-migration-showcase/evidence"
mkdir -p "$EVID"
cp -r "$ROOT/out/artifacts/ansible-runs" "$EVID/" 2>/dev/null || true
cp -r "$ROOT/out/artifacts/dr-drills" "$EVID/" 2>/dev/null || true
echo "Evidence at: $EVID"

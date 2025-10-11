#!/usr/bin/env bash
set -Eeuo pipefail

# Create target folders
mkdir -p docs/runbooks/{bootstrap,dr,burst,ops}

# Helper that prefers git mv (keeps history) but falls back to mv
mvf() {
  src="$1"; dst="$2"
  [ -e "$src" ] || { echo "[skip] $src (not found)"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git mv -f "$src" "$dst" 2>/dev/null || mv -f "$src" "$dst"
  else
    mv -f "$src" "$dst"
  fi
  echo "[moved] $src -> $dst"
}

# --- Bootstrap ---
mvf docs/runbooks/bootstrap-gitops.md         docs/runbooks/bootstrap/bootstrap-gitops.md
mvf docs/runbooks/bootstrap-netbox.md         docs/runbooks/bootstrap/bootstrap-netbox.md
mvf docs/runbooks/bootstrap-rke2-install.md   docs/runbooks/bootstrap/bootstrap-rke2-install.md

# --- DR ---
mvf docs/runbooks/dr-failover-to-cloud.md           docs/runbooks/dr/dr-failover-to-cloud.md
mvf docs/runbooks/dr-failback-to-onprem.md          docs/runbooks/dr/dr-failback-to-onprem.md
mvf docs/runbooks/dr_cutover.md                     docs/runbooks/dr/dr_cutover.md
mvf docs/runbooks/sot_pivot.md                      docs/runbooks/dr/sot_pivot.md
mvf docs/runbooks/ops-postgres-walg-restore-promote.md docs/runbooks/dr/ops-postgres-walg-restore-promote.md
mvf docs/runbooks/walg_restore.md                   docs/runbooks/dr/walg_restore.md

# --- Burst ---
mvf docs/runbooks/burst-scale-out-in.md       docs/runbooks/burst/burst-scale-out-in.md

# --- Ops ---
mvf docs/runbooks/ops-avd-zero-touch.md       docs/runbooks/ops/ops-avd-zero-touch.md
mvf docs/runbooks/ops-dns-cutover.md          docs/runbooks/ops/ops-dns-cutover.md
mvf docs/runbooks/ops-secrets-rotation.md     docs/runbooks/ops/ops-secrets-rotation.md
mvf docs/runbooks/ops-vpn-bringup.md          docs/runbooks/ops/ops-vpn-bringup.md

# Optional: add small folder README stubs if missing
for d in bootstrap dr burst ops; do
  f="docs/runbooks/$d/README.md"
  if [ ! -e "$f" ]; then
    printf "# %s runbooks\n\nSee the index: [../README.md](../README.md)\n" "$d" > "$f"
    git add "$f" 2>/dev/null || true
    echo "[created] $f"
  fi
done

echo "Done. Review with: git status"

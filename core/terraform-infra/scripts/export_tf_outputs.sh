
#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/export_tf_outputs.sh terraform/environments/onprem/staging ansible/artifacts/terraform_outputs.json
WORKDIR=${1:?"path to terraform working dir"}
OUT=${2:?"path to write JSON"}

pushd "$WORKDIR" >/dev/null
terraform output -json > /tmp/tf_outputs.json
popd >/dev/null

mkdir -p "$(dirname "$OUT")"
cp /tmp/tf_outputs.json "$OUT"
echo "Wrote $OUT"

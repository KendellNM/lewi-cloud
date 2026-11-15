#!/usr/bin/env bash
# Orden: 10 -> 20 -> 30 -> 40 -> 50 -> 60 -> 70 -> 80. Azure (90) se activa a mano en el ensayo T15.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for s in 10-aws-base 20-oci-base; do
  (cd "$ROOT/stacks/$s" && terraform init -backend-config=../../backend.hcl -input=false && terraform apply -input=false -auto-approve $( [[ "$s" == 70-observability || "$s" == 80-dns ]] && echo "-var oci_enabled=true" ))
done
"$ROOT/scripts/apply-vpn.sh"
for s in 40-aws-app 50-oci-app 60-backup-azure 70-observability 80-dns; do
  (cd "$ROOT/stacks/$s" && terraform init -backend-config=../../backend.hcl -input=false && terraform apply -input=false -auto-approve $( [[ "$s" == 70-observability || "$s" == 80-dns ]] && echo "-var oci_enabled=true" ))
done

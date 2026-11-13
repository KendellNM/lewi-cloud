#!/usr/bin/env bash
# Valida formato y sintaxis de TODO el codigo sin credenciales ni backend remoto.
# Uso: ./scripts/validate-all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

fail=0
terraform fmt -check -recursive >/dev/null || { echo "FORMATO: ejecutar 'terraform fmt -recursive'"; fail=1; }

for d in 00-bootstrap stacks/*/; do
  d="${d%/}"
  printf '%-28s ' "$d"
  out=$(cd "$d" && terraform init -backend=false -input=false -no-color 2>&1 && terraform validate -no-color 2>&1) \
    && echo "OK" || { echo "FALLA"; echo "$out"; fail=1; }
done
exit $fail

#!/usr/bin/env bash
# Teardown (T17): orden inverso. NO toca 00-bootstrap (estado) ni el dominio/zona de Cloudflare.
# Al destruir 80-dns se quita solo el registro temporal y los ajustes de la zona gestionados aqui.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for s in 90-azure-recovery 80-dns 70-observability 60-backup-azure 50-oci-app 40-aws-app 30-interconnect 20-oci-base 10-aws-base; do
  echo "== destroy $s"
  (cd "$ROOT/stacks/$s" && terraform init -backend-config=../../backend.hcl -input=false >/dev/null && terraform destroy -input=false -auto-approve)
done
echo "Ejecutar scripts/teardown-check.sh para buscar residuos."

#!/usr/bin/env bash
# Copia el estado de S3 a Azure Blob Storage (copia fuera de AWS). Requiere aws CLI y az CLI con sesion iniciada.
# Uso: ./backup-state.sh <bucket-s3-de-estado> <cuenta-azure> <contenedor>
set -euo pipefail
SRC="$1"; ACC="$2"; CONT="$3"
TMP="$(mktemp -d)"
aws s3 sync "s3://$SRC" "$TMP" --only-show-errors
az storage blob upload-batch --account-name "$ACC" --destination "$CONT" --destination-path "tfstate/$(date +%Y%m%d-%H%M%S)" \
  --source "$TMP" --auth-mode login --overwrite false
rm -rf "$TMP"

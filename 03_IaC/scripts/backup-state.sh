#!/usr/bin/env bash
# Copia el estado de S3 al bucket GCS creado por 00-bootstrap (copia fuera de AWS).
set -euo pipefail
SRC="$1"   # bucket S3 de estado
DST="$2"   # bucket GCS de copia
aws s3 sync "s3://$SRC" "gs-tmp-state" --only-show-errors
gsutil -m rsync -r gs-tmp-state "gs://$DST"
rm -rf gs-tmp-state

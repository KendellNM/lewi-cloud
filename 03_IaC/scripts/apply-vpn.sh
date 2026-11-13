#!/usr/bin/env bash
# Aplica 30-interconnect en dos pasadas (ver comentario en stacks/30-interconnect/main.tf).
set -euo pipefail
cd "$(dirname "$0")/../stacks/30-interconnect"
terraform init -backend-config=../../backend.hcl -input=false
terraform apply -input=false -auto-approve
terraform output -json aws_tunnel_ips | python3 -c 'import json,sys; print(json.dumps({"aws_tunnel_ips": json.load(sys.stdin)}))' > tunnels.auto.tfvars.json
terraform apply -input=false -auto-approve
echo "VPN lista. Verificar BGP/rutas (T03, T10) antes de continuar con 40-aws-app."

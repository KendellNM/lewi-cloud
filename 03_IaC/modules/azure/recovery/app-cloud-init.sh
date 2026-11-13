#!/bin/bash
# Origen de recuperacion: HTTPS 443 autofirmado (Cloudflare en modo Full no valida; para Full (strict)
# instalar el certificado Cloudflare Origin CA durante la restauracion). Reemplazar por la aplicacion restaurada.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx openssl
mkdir -p /etc/nginx/tls
openssl req -x509 -nodes -newkey rsa:2048 -days 30 -subj "/CN=azure-origen" \
  -keyout /etc/nginx/tls/key.pem -out /etc/nginx/tls/cert.pem
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
  listen 443 ssl;
  ssl_certificate     /etc/nginx/tls/cert.pem;
  ssl_certificate_key /etc/nginx/tls/key.pem;
  location = /healthz { default_type text/plain; return 200 "ok"; }
  location / { default_type text/plain; return 200 "Abelito Lewista S.A.C. - recuperacion Azure\n"; }
}
EOF
systemctl enable --now nginx
systemctl reload nginx

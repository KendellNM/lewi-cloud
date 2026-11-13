# 03_IaC — Terraform de Abelito Lewista S.A.C.

Terraform ≥ 1.10. Proveedores: aws ~>6, oci ~>9, google ~>8, azurerm ~>5, cloudflare ~>5 (ver `.terraform.lock.hcl` de cada stack).

**Estado de validación:** `terraform fmt` + `terraform validate` pasan en los 10 directorios (`./scripts/validate-all.sh`, sin credenciales). **No se ha ejecutado `plan` ni `apply`**: requiere cuentas reales. Cualquier error de permisos, cuotas o de comportamiento del proveedor aparecerá ahí, no en `validate`.

## Estructura

```
00-bootstrap/            estado remoto (S3 + copia GCS). Local. NO se destruye.
modules/{aws,oci,gcp,azure}/...   lógica reutilizable
modules/shared/          script de origen de demostración (nginx 8443)
stacks/                  un estado por carpeta; el número es el orden
  10-aws-base            VPC, subredes, NAT, VGW, endpoints, SG, KMS, RDS Multi-AZ, S3, Backup
  20-oci-base            compartment, VCN, DRG, NSG, Bastion, PostgreSQL VM, Object Storage, Vault, IAM
  30-interconnect        VPN AWS–OCI: 2 caminos IPsec + BGP (2 pasadas, ver abajo)
  40-aws-app             ACM (DNS Cloudflare), ALB, WAF, ASG 2–4
  50-oci-app             Origin CA, LB web, LB privado del relay, pool 2–3 en 2 fault domains, autoscaling
  60-backup-gcp          bucket GCS us-central1 + cuentas de servicio mínimas
  70-observability       dashboard, alarmas, SNS, CloudTrail (AWS) + alarmas OCI
  80-dns                 abelito.me → origen activo (aws|oci), SSL strict, cabecera de origen
  90-azure-recovery      VNet + 2 VM; enabled=false por defecto
scripts/                 validate-all, apply-all, apply-vpn, destroy-all, teardown-check, backup-state
```

> **Trabajo en grupo con agentes de IA:** reglas comunes en `../AGENTS.md` y un archivo por agente en `../agentes/`. Cada agente solo edita lo que posee.

## Uso

```bash
cd 00-bootstrap && terraform init && terraform apply -var owner=<tu-nombre>
terraform output -raw backend_hcl > ../backend.hcl          # bucket/region del estado
# en cada stack: cp terraform.tfvars.example terraform.tfvars y completar
export CLOUDFLARE_API_TOKEN=...                              # stacks 40, 80
export CLOUDFLARE_API_USER_SERVICE_KEY=...                   # stack 50 (Origin CA)
./scripts/apply-all.sh
```

`apply-all.sh` no incluye Azure (`90`): se activa a mano con `-var enabled=true` solo en el ensayo T15.

## Decisiones que conviene conocer

| Tema | Decisión | Motivo |
|---|---|---|
| NAT AWS | 1 por AZ (`nat_per_az=true`) | Elimina el SPOF de egreso y SSM sigue funcionando si cae una AZ. Es más barato que usar un solo NAT + 5 endpoints de interfaz en 2 AZ (~USD 0,10/h frente a +0,045/h). |
| Clave de RDS | `manage_master_user_password` | La crea y rota RDS en Secrets Manager; no pasa por el estado de Terraform. |
| Relay OCI | LB privado (L4) en vez de NLB | `oci_core_instance_pool` solo se asocia a *Load Balancer*, no a NLB: con NLB los nodos escalados no se registrarían. |
| Lista de seguridad OCI | vacía y adjunta a todas las subredes | La predeterminada abre SSH 22 a Internet; el control real va en NSG. |
| Alta disponibilidad (prioridad sobre costo) | ASG 4–8 (2 por AZ); pool OCI 4–6 (2 por fault domain); NAT por AZ; RDS Multi-AZ; **PostgreSQL OCI primario + standby** en fault domains distintos; 2 caminos VPN | Decisión del grupo. Supera Always Free: el costo se documenta en `costos/`. |
| WAF | AWS WAF (reglas comunes, límite por IP del cliente, cabecera de origen) **y** WAF de OCI (límite de tasa; reglas OWASP pendientes, agente 05) | Paridad de protección en ambos orígenes. |
| Auditoría y detección | GuardDuty, VPC Flow Logs, logs de acceso del ALB, CloudTrail, Performance Insights de RDS | Más visibilidad; si el Learner Lab no permite roles IAM: `enable_flow_logs=false`, `enable_guardduty=false`. |
| Certificados | ACM (AWS) y Cloudflare Origin CA (OCI) | Ambos válidos para Cloudflare *Full (strict)*. |
| Origen protegido | prefix list de Cloudflare + cabecera `x-origin-verify` (WAF) | Permitir solo rangos de Cloudflare no basta: cualquier cliente de Cloudflare llegaría al ALB. |
| Alarma de copias | 90 min | El respaldo es cada hora; 60 min alarmaría siempre en el límite. |

## VPN AWS–OCI (dos pasadas)

AWS necesita la IP pública de OCI y OCI necesita la IP del túnel AWS: dependencia circular. `scripts/apply-vpn.sh` aplica dos veces: la segunda fija `cpe_local_identifier` con las IP reales. Cada camino usa **un** túnel de AWS y **uno** de OCI; el túnel sobrante queda sin pareja y por eso las alarmas solo vigilan los emparejados (`paired_tunnel_ips`).

**Riesgos abiertos (se confirman en T10):** la IP provisional del CPE (`cpe_placeholder_ip`) podría ser rechazada por OCI; los parámetros IKE/IPsec usan los valores por defecto de ambos lados; el orden de `ip_sec_connection_tunnels[0]` no está garantizado.

## Pendiente fuera de Terraform

- Aplicación real (hoy los nodos sirven un nginx de demostración con `/healthz`).
- Roles y publicación lógica en RDS, y `scripts/oci-subscriber.sql` en OCI.
- Job de copia portable (pg_dump → S3 → relay → GCS) y la métrica `Abelito/Backup`.
- Las listas de IP de Cloudflare deben verificarse contra <https://www.cloudflare.com/ips-v4> antes de aplicar.

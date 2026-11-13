# Agente 01 — AWS — Red y seguridad

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Red y seguridad de AWS: VPC, subredes, NAT por AZ, VGW, endpoints, SG, prefix list de Cloudflare, flow logs.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/aws/network/`
- `03_IaC/modules/aws/security/`
- `03_IaC/stacks/10-aws-base/` (llamadas a `network` y `security`, variables y outputs de red)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/01-aws-red-seguridad.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- CIDR del plan: VPC `10.10.0.0/16`; públicas `10.10.1.0/24`, `10.10.2.0/24`; app `10.10.11.0/24`, `10.10.12.0/24`; datos `10.10.21.0/24`, `10.10.22.0/24`.
- Rangos IPv4 de Cloudflare (verificar en https://www.cloudflare.com/ips-v4).

**Salidas / contrato**
- Outputs de `10-aws-base`: `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `app_subnet_ids`, `vgw_id`, `nat_public_ips`, `alb_sg_id`, `app_sg_id`, `rds_sg_id`.

## 4. Tareas (marca al completar)
- [ ] Con credenciales: `terraform plan` de `stacks/10-aws-base`; corregir errores de permisos/cuotas.
- [ ] Verificar los 15 CIDR de Cloudflare contra la fuente oficial y actualizar `modules/aws/security/variables.tf` y las copias en `stacks/10-aws-base/main.tf`, `stacks/20-oci-base/main.tf`, `stacks/90-azure-recovery/variables.tf` (avisar a 04 y 08).
- [ ] Confirmar `nat_per_az = true` (un NAT por AZ) y que cada tabla de rutas de app apunta al NAT de su AZ.
- [ ] Confirmar que la propagación de rutas del VGW está activa en tablas de app y datos (`aws_vpn_gateway_route_propagation`).
- [ ] Si el Learner Lab no permite crear roles IAM: `enable_flow_logs = false` y documentarlo.
- [ ] Agregar NACL explícitas (opcional, defensa en profundidad) sin romper retorno de tráfico; documentar reglas.
- [ ] Registrar IDs reales de AZ, VPC, subredes, SG en `evidencias/` (Anexo C del informe) vía agente 10.
- [ ] Revisar que ningún SG permita `0.0.0.0/0` entrante; solo salida 443 y 5432 hacia SG de RDS.

## 5. Criterios de aceptación
- [ ] `cd 03_IaC && terraform fmt -check -recursive && cd stacks/10-aws-base && terraform init -backend=false && terraform validate`
- [ ] `terraform plan` sin errores con credenciales reales (adjuntar resumen).
- [ ] Búsqueda: ningún `0.0.0.0/0` en reglas de ingreso (`grep -rn "0.0.0.0/0" modules/aws/security`).

## 6. Pruebas relacionadas
T03 (rutas privadas), T06 (acceso denegado). (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- VGW o flow logs bloqueados en Learner Lab.
- Prefix list de Cloudflare desactualizada.

## Entrega y estado
- Actualiza `agentes/estado/01-aws-red-seguridad.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

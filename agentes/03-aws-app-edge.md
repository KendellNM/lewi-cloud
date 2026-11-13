# Agente 03 — AWS — Aplicación, ALB, WAF y borde

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Entrada pública en AWS: ACM, ALB, AWS WAF, Auto Scaling Group, rol de instancia y publicación del origen de la aplicación.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/aws/app/`
- `03_IaC/stacks/40-aws-app/`
- `03_IaC/stacks/80-dns/` (registro `abelito.me`, SSL strict, cabecera de origen)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/03-aws-app-edge.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Salidas del stack 10 (subredes, SG, KMS, bucket de objetos, secreto de BD).
- Artefacto de aplicación del agente 09.
- `cloudflare_zone_id` de `abelito.me`.

**Salidas / contrato**
- Outputs: `alb_dns_name`, `alb_arn_suffix`, `target_group_arn_suffix`, `asg_name`.
- Registro DNS que apunta al origen activo (`active_origin = aws|oci`).

## 4. Tareas (marca al completar)
- [ ] `terraform plan` del stack 40. Exportar `CLOUDFLARE_API_TOKEN`.
- [ ] **WAF de AWS** (ya incluido): comprobar reglas `reglas-comunes-aws`, `limite-por-ip-cliente` (CF-Connecting-IP) y la regla opcional de cabecera `x-origin-verify`. Ajustar `rate_limit_per_5min`; añadir reglas administradas extra (SQLi, bad inputs, IP reputation) si el Learner Lab lo permite.
- [ ] Definir un secreto `origin_verify_secret` (aleatorio, largo) y pasarlo **igual** a los stacks 40 y 80 por `TF_VAR_origin_verify_secret`; verificar que sin la cabecera el ALB responde 403 (T07).
- [ ] Sustituir el nginx de demostración: el `user_data` debe descargar el artefacto de `app/` (S3 del stack 10 o paquete) y arrancar el servicio en **8443 HTTPS**; `/healthz` debe devolver 200 sin revelar secretos. Coordinar con agente 09.
- [ ] Política IAM de la instancia: solo bucket de objetos, secreto de BD y clave KMS. No añadir permisos de administración.
- [ ] Ajustar ASG (min 4 / max 8, 2 por AZ), `cpu_target`, warm-up 180 s y health check ELB; probar reemplazo de instancia (T08) y escalado (T09). Nota: las `t3` usan créditos de CPU.
- [ ] Cloudflare: confirmar modo **Full (strict)**, TLS mínimo 1.2 y *Always HTTPS* (stack 80).
- [ ] Opcional (HA extra): Cloudflare Load Balancer con health checks. Solo documentar; **no** automatizar el cambio a OCI (riesgo de segundo escritor).

## 5. Criterios de aceptación
- [ ] `terraform validate` de stacks 40 y 80.
- [ ] `curl -I https://abelito.me/healthz` → 200 con certificado válido (T01).
- [ ] Petición directa al ALB sin `x-origin-verify` → 403 (T07).

## 6. Pruebas relacionadas
T01, T07, T08, T09. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- WAF no disponible en Learner Lab.
- Validación DNS de ACM puede tardar minutos.
- Si Cloudflare agrega la cabecera pero el secreto no coincide, el ALB bloquea todo.

## Entrega y estado
- Actualiza `agentes/estado/03-aws-app-edge.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

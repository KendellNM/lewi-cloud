# Agente 07 — Observabilidad y alarmas

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Monitoreo, alarmas, dashboards, auditoría y detección de amenazas en AWS y OCI.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/aws/observability/`, `modules/oci/observability/`
- `03_IaC/stacks/70-observability/`

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/07-observabilidad.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Salidas de los stacks 10, 20, 30, 40.
- `alarm_email` (solo el destinatario autorizado).

**Salidas / contrato**
- Outputs: `aws_dashboard`, `aws_sns_topic_arn`.
- Métrica personalizada `Abelito/Backup` · `MinutosDesdeUltimaCopiaVerificada` (la publica el job del agente 08).

## 4. Tareas (marca al completar)
- [ ] `terraform plan` del stack 70. Confirmar suscripción por correo (aceptar el mensaje de SNS/ONS).
- [ ] GuardDuty: es un detector por cuenta/región; si ya existe, `enable_guardduty=false`.
- [ ] Ajustar umbrales tras medir: `rds_max_connections`, `slot_lag_bytes`, p95 2 s, 5xx 1 %.
- [ ] Dashboard AWS: verificar widgets (ALB, ASG, RDS, VPN, copias). Crear el equivalente OCI (dashboard/consultas de Monitoring y Logging).
- [ ] Logs OCI: habilitar logs de servicio del LB y del WAF en el log group creado; exportar a Object Storage si procede.
- [ ] CloudTrail y OCI Audit: comprobar que registran cambios y que los logs de aplicación no incluyen secretos.
- [ ] Provocar una alarma real controlada (T12): CPU, VPN o lag, y registrar cambio de estado y recuperación con hora.
- [ ] Coordinar con 08 que la métrica de copias se publique cada ≤ 60 min (la alarma salta a 90 min).

## 5. Criterios de aceptación
- [ ] `terraform validate` del stack 70.
- [ ] Una alarma pasa a `ALARM` y vuelve a `OK` con evidencia (captura + hora) — T12.

## 6. Pruebas relacionadas
T12 (y apoya T08, T09, T10, T11). (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Alertas de presupuesto con retraso: no son un apagado automático.
- GuardDuty duplicado.

## Entrega y estado
- Actualiza `agentes/estado/07-observabilidad.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

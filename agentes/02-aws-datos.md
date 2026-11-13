# Agente 02 — AWS — Datos (RDS, S3, KMS, Backup)

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Datos de AWS: RDS PostgreSQL Multi-AZ, KMS, S3, AWS Backup y todo el SQL (esquema, datos sintéticos, roles, publicación lógica).

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/aws/data/`
- `03_IaC/stacks/10-aws-base/` (llamada a `data`)
- `datos/` (todo el SQL del proyecto)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/02-aws-datos.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- `vpc`, subredes de datos y `rds_sg_id` (agente 01).
- IP del suscriptor OCI: `postgres_private_ip` (stack 20; la regla de SG la crea el stack 30).

**Salidas / contrato**
- Outputs: `kms_key_arn`, `db_identifier`, `db_endpoint`, `db_master_secret_arn`, `allocated_storage_gb`, `objects_bucket_arn`, `exports_bucket`.
- Archivos en `datos/`: `schema.sql`, `seed.sql`, `roles-rds.sql`, `publicacion.sql` (ver `datos/README.md`).

## 4. Tareas (marca al completar)
- [ ] `terraform plan` del stack 10 (parte de datos). La clave maestra de RDS la gestiona RDS en Secrets Manager (`manage_master_user_password`): no la pongas en Terraform.
- [ ] Crear `datos/schema.sql`: tablas `cliente`, `producto`, `pedido`, `detalle_pedido`, `movimiento_inventario` con PK/FK y restricciones; cada tabla publicada con PK.
- [ ] Crear `datos/seed.sql` con **datos sintéticos** (hasta 200 clientes). Nada de datos reales.
- [ ] Crear `datos/roles-rds.sql`: roles `app_rw` (aplicación), `replicador` (con `rds_replication`), `respaldo` (solo lectura), sin usar `pgadmin` desde la app.
- [ ] Crear `datos/publicacion.sql`: `CREATE PUBLICATION abelito_pub FOR ALL TABLES;` y notas para `scripts/oci-subscriber.sql`.
- [ ] Confirmar que el grupo de parámetros aplica `rds.logical_replication=1` (requiere **reinicio** la primera vez) y `rds.force_ssl=1`.
- [ ] Probar el failover de RDS y documentar si la suscripción lógica continúa (T11). Anotar versión de PostgreSQL exacta y fijarla (`pg_major`) igual en OCI y Azure.
- [ ] Verificar que AWS Backup funciona en el Learner Lab (`enable_backup`); si no, justificar y usar snapshots manuales.
- [ ] Ajustar `rds_max_connections` (módulo observabilidad) según la clase real.

## 5. Criterios de aceptación
- [ ] `terraform validate` del stack 10.
- [ ] Los `.sql` se ejecutan sin error sobre un PostgreSQL local del mismo `pg_major` (`psql -f`).
- [ ] T04/T05/T11 documentados con el agente 10.

## 6. Pruebas relacionadas
T02 (datos), T04 (replicación), T05 (TLS SQL), T11 (failover RDS), T13 (restauración nativa). (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Reinicio requerido para activar replicación lógica.
- Slots lógicos y failover Multi-AZ: **debe probarse**.

## Entrega y estado
- Actualiza `agentes/estado/02-aws-datos.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

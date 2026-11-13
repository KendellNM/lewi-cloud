# datos/ — SQL del proyecto (agentes 02 y 04)

| Archivo | Dueño | Contenido |
|---|---|---|
| `schema.sql` | 02 | Tablas `cliente`, `producto`, `pedido`, `detalle_pedido`, `movimiento_inventario` (PK/FK/restricciones) |
| `seed.sql` | 02 | Datos **sintéticos** (hasta 200 clientes) |
| `roles-rds.sql` | 02 | Roles `app_rw`, `replicador` (`rds_replication`), `respaldo` |
| `publicacion.sql` | 02 | `CREATE PUBLICATION abelito_pub FOR ALL TABLES;` |
| `subscriber.sql` | 04 | Suscripción lógica en OCI (base: `03_IaC/scripts/oci-subscriber.sql`) |
| `standby.md` | 04 | Replicación física primario→standby en OCI y manejo de la suscripción tras promoción |

Reglas: misma versión mayor de PostgreSQL en RDS, OCI y Azure (variable `pg_major`); un solo escritor; ningún dato real.

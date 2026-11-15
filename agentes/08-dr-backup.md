# Agente 08 — Continuidad: copias y Azure

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Continuidad: copia portable cifrada, relay OCI, almacenamiento Azure Blob (copia independiente) y recuperación en Azure; scripts de restauración y medición de RTO/RPO.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/azure/` (`backup-storage` y `recovery`)
- `03_IaC/stacks/60-backup-azure/`, `stacks/90-azure-recovery/`
- `backup/` (scripts, manifiestos, relay)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/08-dr-backup.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Stacks 10, 20, 50 (buckets, `relay_lb_ip`, `exports_bucket`).
- Sesión de Azure del propio humano (`az login`) y su `subscription_id`.

**Salidas / contrato**
- Outputs 60: `storage_account_name`, `storage_account_id`, `container_name`, `container_id`, `resource_group`, `location`. Outputs 90: `app_public_ip`, `db_private_ip`.
- Scripts en `backup/` (ver `backup/README.md`).

## 4. Tareas (marca al completar)
- [ ] **Credencial de escritura hacia Azure** (el relay de OCI y el job de AWS no pueden usar identidad administrada de Azure): crear un *service principal* con rol `Storage Blob Data Contributor` **solo sobre el contenedor** `copias-portables` (pasar su Object ID en `writer_principal_ids` del stack 60). Guardar su secreto en OCI Vault y en AWS Secrets Manager; **nunca** en el repositorio. Si la suscripción estudiantil no permite crear service principals, alternativa: SAS de usuario con vencimiento corto, renovada por el job.
- [ ] La cuenta de almacenamiento solo admite Entra ID (`shared_access_key_enabled = false`): probar `az storage blob upload --auth-mode login`. Región por defecto `centralus` (Iowa, fuera de Virginia); `eastus` y `eastus2` están en Virginia y **no** sirven para independencia geográfica.
- [ ] Decidir redundancia del almacenamiento: `ZRS` (defecto) o `GZRS/GRS` (la región pareada de Central US es East US 2, en Virginia: más redundancia, no más independencia de zona geográfica).
- [ ] `terraform plan` de los stacks 60 y 90 (Azure con `enabled=false` por defecto; solo `true` en el ensayo T15).
- [ ] `backup/export.sh`: `pg_dump` consistente (esquema, roles de aplicación, datos) + objetos de negocio + `manifiesto.json` (versión, fecha de corte, inventario, SHA-256). Cifrar el paquete **antes** del traslado.
- [ ] Custodia de la clave de cifrado **fuera de AWS** (si no, la copia es irrecuperable en contingencia). Documentar dónde.
- [ ] `backup/relay/`: servicio que recibe por 443 (LB privado de OCI), valida hash, guarda en Object Storage y copia a Azure Blob Storage (`az storage blob upload --auth-mode login`); idempotente (claves de objeto + manifiesto).
- [ ] Ruta alterna F05: subida directa AWS → Azure Blob si el relay falla.
- [ ] Programación: Systems Manager Run Command + EventBridge cada hora sobre **una** instancia del ASG, con bloqueo (solo una ejecuta). Publicar `MinutosDesdeUltimaCopiaVerificada`.
- [ ] `backup/restore-oci.md` y `backup/restore-azure.sh`: procedimientos de §19.5.2 y §19.5.3 (activar OCI con **único escritor**; restaurar en Azure desde Azure Blob (las VM leen con su identidad administrada, sin claves); instalar certificado Origin CA).
- [ ] Medir RTO/RPO con transacciones de control y reloj sincronizado; entregar tiempos al agente 10 (T13, T14, T15).
- [ ] Azure: región fuera de Norte de Virginia; confirmar disponibilidad en la suscripción estudiantil.

## 5. Criterios de aceptación
- [ ] `terraform validate` de stacks 60 y 90.
- [ ] Restauración real de una copia en Azure con consulta de datos de control (T15).
- [ ] Hash antes/después de cada transferencia coincide.

## 6. Pruebas relacionadas
T13, T14, T15. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Clave de cifrado inaccesible durante la contingencia.
- Segundo escritor por error humano durante T14.
- Tiempo de restauración de RDS Multi-AZ.

## Entrega y estado
- Actualiza `agentes/estado/08-dr-backup.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

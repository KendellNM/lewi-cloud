# Agente 04 — OCI — Red, PostgreSQL e IAM

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
OCI base: compartment, VCN, DRG, gateways, NSG, Bastion, PostgreSQL (primario + standby), Object Storage, Vault e IAM.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/oci/network/`, `modules/oci/data/`, `modules/oci/iam/`
- `03_IaC/stacks/20-oci-base/`
- Scripts de PostgreSQL de OCI en `datos/` (`subscriber.sql`, `standby.md`)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/04-oci-red-datos.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- CIDR `10.20.0.0/16` (pública `10.20.1.0/24`, app `10.20.11.0/24`, datos `10.20.21.0/24`).
- CIDR de AWS `10.10.0.0/16` como `peer_cidr`.
- `tenancy_ocid`, IP del operador para Bastion (`admin_cidrs`).

**Salidas / contrato**
- Outputs: `compartment_id`, `tenancy_ocid`, `region`, `drg_id`, `vcn_id`, subredes, NSG, `postgres_private_ip`, `postgres_standby_private_ip`, `bucket_name`, `availability_domain`, `bastion_id`.

## 4. Tareas (marca al completar)
- [ ] `terraform plan` del stack 20; resolver cuotas y disponibilidad de shape (`VM.Standard.E4.Flex` o A1 ARM) y región.
- [ ] Decidir shape con el coordinador. Con ARM (A1) las imágenes/paquetes deben ser aarch64.
- [ ] Confirmar que **no** queda la lista de seguridad predeterminada con SSH abierto (el módulo adjunta una lista sin ingreso a todas las subredes) y que solo hay NSG.
- [ ] PostgreSQL primario: verificar cloud-init (volumen `/dev/oracleoci/oraclevdb`, `postgresql:${pg_major}`), TLS y `pg_hba.conf` solo para la red privada.
- [ ] **Suscriptor lógico**: crear `datos/subscriber.sql` (a partir de `03_IaC/scripts/oci-subscriber.sql`): cargar esquema y `CREATE SUBSCRIPTION` con `sslmode=verify-full` hacia RDS. La app OCI no escribe mientras sea suscriptor.
- [ ] **Standby (nuevo)**: el módulo crea un segundo PostgreSQL en otro fault domain. Documentar y automatizar la replicación **física** primario→standby en `datos/standby.md` (pg_basebackup, `primary_conninfo`, slot). Aviso: el primario es a su vez suscriptor lógico; define cómo se conserva la suscripción tras una promoción (probar).
- [ ] IAM: el dynamic group y la política solo dan objetos del bucket y lectura de secretos. No ampliar.
- [ ] OCI Bastion: crear una sesión de prueba y documentar el acceso sin SSH público.
- [ ] Guardar `replication_password` solo vía `TF_VAR_replication_password` (se almacena en OCI Vault).

## 5. Criterios de aceptación
- [ ] `terraform validate` del stack 20.
- [ ] Desde Bastion: `psql` al primario y al standby; el standby va a otro fault domain (`oci compute instance get`).
- [ ] Inventario real de OCI para el Anexo C.

## 6. Pruebas relacionadas
T03, T04, T05, T06. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Always Free no cubre 2 nodos PostgreSQL + pool de 4 (se aceptó costo).
- La replicación física + suscripción lógica combinadas son delicadas: probar antes de la demo.

## Entrega y estado
- Actualiza `agentes/estado/04-oci-red-datos.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

# app/ — aplicación de demostración (agente 09)

Requisitos mínimos: ver `agentes/09-aplicacion.md`.

- HTTPS en **8443** (443 en Azure); `/healthz` → 200; `/whoami` muestra el origen (`aws|oci|azure`).
- Sin estado local durable; archivos en Object Storage/S3; pedidos idempotentes; reintentos tras failover.
- Configuración solo por variables de entorno; secretos desde Secrets Manager / Vault.
- Debe correr en Amazon Linux 2023, Oracle Linux 9 y Ubuntu 24.04.

Estructura sugerida: `src/`, `tests/`, `packaging/`, este README con instrucciones de construcción y arranque.

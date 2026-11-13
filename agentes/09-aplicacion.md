# Agente 09 — Aplicación web de demostración

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Aplicación web de demostración (catálogo, pedidos, panel autenticado) que corra en AWS, OCI y Azure sin cambios de código.

## 2. Alcance (lo que posees y puedes editar)
- `app/`
- `03_IaC/modules/shared/` (solo el script de arranque `nginx-origin.sh.tftpl`)

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/09-aplicacion.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Esquema de `datos/` (agente 02).
- Variables de entorno: conexión PostgreSQL, bucket de objetos, entorno (`aws|oci|azure`).

**Salidas / contrato**
- Artefacto desplegable + `app/README.md` (cómo construir, configurar y arrancar).

## 4. Tareas (marca al completar)
- [ ] Elegir lenguaje/framework (sugerido: Python FastAPI o Node) y documentarlo en `app/README.md`. Debe correr en Amazon Linux 2023, Oracle Linux 9 y Ubuntu 24.04.
- [ ] Endpoints: `GET /` (catálogo), `POST /pedidos`, `GET /pedidos/{id}`, panel autenticado, **`GET /healthz`** (200 sin datos sensibles) y `GET /whoami` que muestre el origen (`aws|oci|azure`) sin revelar secretos (T01).
- [ ] Escucha **HTTPS en 8443** (certificado autofirmado interno; el balanceador no lo valida). En Azure: 443.
- [ ] **Sin estado local durable**: sesiones con tokens firmados de vida corta o en la BD activa; archivos en Object Storage/S3 (abstracción por entorno).
- [ ] Pedidos **idempotentes** (clave de idempotencia) y transacciones atómicas pedido + inventario; reintentos acotados de conexión SQL tras failover.
- [ ] Conexión a PostgreSQL con TLS y usuario `app_rw`; la contraseña se lee de Secrets Manager (AWS) / Vault (OCI), nunca del código ni de la imagen.
- [ ] Modo solo lectura cuando la base es suscriptora (OCI antes de la activación): no intentar escribir.
- [ ] Logs sin contraseñas, tokens ni datos personales; incluir identificador de solicitud.
- [ ] Empaquetado: tarball o contenedor; coordinar con 03/05 cómo lo descargan las instancias al arrancar.
- [ ] Pruebas unitarias mínimas y un script de humo.

## 5. Criterios de aceptación
- [ ] `curl -k https://localhost:8443/healthz` → 200.
- [ ] Crear y recuperar un pedido sintético (T02).
- [ ] Matar la BD durante una petición: la app reintenta y no duplica pedidos.

## 6. Pruebas relacionadas
T01, T02, T05 (parcial), T08, T09. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Estado en disco local rompe el reemplazo de instancias.
- Escrituras accidentales contra el suscriptor.

## Entrega y estado
- Actualiza `agentes/estado/09-aplicacion.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

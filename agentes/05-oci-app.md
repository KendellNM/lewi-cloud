# Agente 05 — OCI — Aplicación, balanceadores y WAF

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
OCI aplicación: Instance Pool en dos fault domains, autoescalado, Flexible LB público, LB privado del relay, Origin CA y WAF de OCI.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/modules/oci/app/` (incluye `waf.tf`)
- `03_IaC/stacks/50-oci-app/`

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/05-oci-app.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Salidas del stack 20.
- Artefacto de aplicación y servicio *relay* (agentes 09 y 08).
- `CLOUDFLARE_API_USER_SERVICE_KEY` para Origin CA.

**Salidas / contrato**
- Outputs: `web_lb_ip`, `relay_lb_ip`, `pool_id`.

## 4. Tareas (marca al completar)
- [ ] `terraform plan` del stack 50. Verificar que Origin CA emite el certificado y que el LB lo acepta (Full strict).
- [ ] Pool `pool_min=4`, `pool_max=6` (2 por fault domain). Comprobar que el autoescalado respeta fault domains y registra miembros en **ambos** backend sets.
- [ ] **OCI no permite asociar el pool a un NLB**: el relay usa un LB privado L4 (decisión documentada en el informe §15). No migrar a NLB.
- [ ] **WAF de OCI** (`waf.tf`): hoy solo tiene límite de tasa. Añadir reglas de protección (OWASP/`protection_capabilities`) y la verificación de la cabecera `x-origin-verify`, consultando la documentación de OCI WAF para claves y condiciones JMESPATH. Validar que el WAF no bloquea `/healthz` del LB.
- [ ] Reemplazar el nginx de demostración por la aplicación real (coordinar con 09) y desplegar el **servicio relay** (con 08): recibe paquetes por 443 TCP, valida hash/manifiesto, guarda en Object Storage y copia a Azure Blob Storage.
- [ ] Instance principal: confirmar permisos del dynamic group para el bucket de copias.
- [ ] Probar que, al activarse OCI, la app escribe solo si la base está promovida (un único escritor).

## 5. Criterios de aceptación
- [ ] `terraform validate` del stack 50.
- [ ] `curl -k https://<web_lb_ip>/healthz` con `Host: abelito.me` → 200.
- [ ] Retirar un nodo del pool: el LB lo saca y el pool repone (T08).

## 6. Pruebas relacionadas
T08, T09, T14. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Sintaxis de condiciones del WAF de OCI (JMESPATH).
- Salud del backend con SSL: el health checker HTTP sobre backend SSL debe probarse.

## Entrega y estado
- Actualiza `agentes/estado/05-oci-app.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

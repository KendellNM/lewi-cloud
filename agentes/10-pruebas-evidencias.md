# Agente 10 — Pruebas T01–T17 y evidencias

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Ejecutar y documentar las 17 pruebas (T01–T17) con evidencia verificable; es lo que respalda la rúbrica y la sustentación.

## 2. Alcance (lo que posees y puedes editar)
- `pruebas/`
- `evidencias/`
- `03_IaC/scripts/teardown-check.sh`

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/10-pruebas-evidencias.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Todos los stacks desplegados; especificaciones en `pruebas/Txx_*/README.md`.

**Salidas / contrato**
- `evidencias/Txx_*/RESULTADO.md` completados + capturas/logs sin secretos.
- Tablas de §23 del informe (para el agente 11).

## 4. Tareas (marca al completar)
- [ ] Completar cada `pruebas/Txx_*/run.sh` o `procedimiento.md` con comandos reales y reproducibles (curl, psql, aws/oci CLI, `hey`/`k6`/`ab` para carga).
- [ ] Ejecutar **una prueba a la vez** y restaurar el estado base entre ellas. Orden: T01–T02, T03, T05, T06–T07, T12, T09, T08, T11, T04, T10, T13, T14, T15, T16, T17.
- [ ] Registrar en cada `RESULTADO.md`: fecha, responsable, versión de configuración (commit), resultado, medición, evidencia y observaciones. **Nunca** copiar secretos.
- [ ] T09: cargas de 25 y 50 sesiones por 10 min; p95 ≤ 2 s y errores < 1 %; registrar tamaño de datos y patrón.
- [ ] T10, T11, T13, T14, T15: medir RTO/RPO con transacciones de control y relojes sincronizados.
- [ ] T16: recrear desde Terraform en un entorno limpio; T17: destruir y revisar residuos con `teardown-check.sh` (NAT, EIP, VPN, ALB, RDS, snapshots, versiones S3, OCI y Azure: grupos `e3-abelito-recuperacion` y `e3-abelito-copias`).
- [ ] Detener una prueba si peligra la integridad o no se puede confirmar un único escritor.
- [ ] Entregar los resultados al agente 11 para el informe (§23 y anexos).

## 5. Criterios de aceptación
- [ ] Todos los `RESULTADO.md` con datos reales (o marcados "no ejecutada" con motivo).
- [ ] `teardown-check.sh` sin recursos facturables residuales.

## 6. Pruebas relacionadas
T01–T17. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Sesión de laboratorio corta: planificar **dos sesiones** (A: núcleo AWS–OCI, VPN, carga y fallas; B: restauraciones, activación OCI y Azure).
- Evidencias con secretos visibles.

## Entrega y estado
- Actualiza `agentes/estado/10-pruebas-evidencias.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

# Agente 00 — Coordinador (humano líder + su agente)

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Coordinar al grupo: orden de trabajo, integración, resolución de conflictos y control de calidad. No desarrolla una pieza; garantiza que todas encajen.

## 2. Alcance (lo que posees y puedes editar)
- `AGENTS.md`, `README.md`, `agentes/`
- `03_IaC/00-bootstrap`, `03_IaC/README.md`, `03_IaC/scripts/` (salvo los asignados)
- Integración de ramas y `.gitignore` raíz

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/00-coordinador.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Archivos de estado `agentes/estado/*.md` de todos los agentes.

**Salidas / contrato**
- Tablero de avance, decisiones registradas en `docs/decisiones.md`, repositorio Git inicializado.

## 4. Tareas (marca al completar)
- [ ] `git init` en `E:\Lewi`, `.gitignore` raíz (`*.tfstate*`, `*.tfvars`, `.terraform/`, `*.pem`, `backend.hcl`) y una rama por agente.
- [ ] Con credenciales reales: aplicar `00-bootstrap`, generar `backend.hcl` y entregarlo a todos (sin subirlo a Git).
- [ ] Verificar **hoy** permisos del Learner Lab: VPN site-to-site, WAF, RDS Multi-AZ, AWS Backup, creación de roles IAM (flow logs, backup). Registrar lo que **no** se puede y avisar a los agentes afectados (`enable_flow_logs=false`, `enable_backup=false`, etc.).
- [ ] Decidir ARM vs x86 en OCI (`shape` en stack 20/50) y confirmar región Azure (`location`).
- [ ] Orden de ejecución sugerido: 01+02 → 04 → 06 → 03 → 05 → 08 → 07 → 09/10/11 en paralelo desde el inicio. Ver `AGENTS.md` sección 4.
- [ ] Revisar cada entrega contra sus criterios de aceptación; rechazar lo que cambie contratos de salidas sin acuerdo.
- [ ] Mantener `docs/decisiones.md` (decisiones y su motivo).
- [ ] Pedir al agente 11 que alinee el informe cada vez que cambien parámetros de HA/costo.

## 5. Criterios de aceptación
- [ ] `cd 03_IaC && ./scripts/validate-all.sh` pasa en la rama integrada.
- [ ] Los 11 archivos `agentes/estado/*.md` están al día.

## 6. Pruebas relacionadas
Todas (supervisión). (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Learner Lab puede bloquear VPN, WAF, IAM o Backup: es el mayor riesgo del proyecto.
- Cambios simultáneos al mismo `outputs.tf`.

## Entrega y estado
- Actualiza `agentes/estado/00-coordinador.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

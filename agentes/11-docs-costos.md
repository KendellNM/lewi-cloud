# Agente 11 — Informe, diagrama y costos

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
Mantener el informe, el diagrama y los costos coherentes con lo realmente construido y medido.

## 2. Alcance (lo que posees y puedes editar)
- `Proyecto_Final_Cloud_Abelito_Lewista_v2.docx`
- `02_Arquitectura/`
- `costos/`, `docs/`

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/11-docs-costos.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Todo el repositorio; resultados de `evidencias/`; precios oficiales.

**Salidas / contrato**
- Informe final, diagrama actualizado, `costos/cotizacion.md`, guion de sustentación.

## 4. Tareas (marca al completar)
- [ ] **Alinear el informe v2 con los cambios de HA** (el código ya los tiene, el texto aún no): ASG **4–8** (2 por AZ) en §8.6, §10, §16, §21 y RF06 ("mantener mínimo de dos"→cuatro); pool OCI **4–6**; PostgreSQL OCI con **standby** en otro fault domain (§8.4, §12, §14, tabla de SPOF §14.1: ya no es un solo nodo); **WAF también en OCI** (§13.2, §14 y la frase "Durante recuperación en OCI, AWS WAF ya no protege…"); **GuardDuty**, **VPC Flow Logs** y **logs de acceso del ALB** (§13.4, §17); retención de RDS 14 días; Performance Insights.
- [ ] Recalcular §21.4 (costos) con los nuevos tamaños; reemplazar los valores aproximados por cotización oficial (calculadoras de AWS, OCI, Azure, GCP) y anotar la fecha de consulta.
- [ ] Actualizar el diagrama (`02_Arquitectura/arquitectura_multicloud.drawio`): 4 EC2 (2 por AZ), WAF en OCI, segundo PostgreSQL OCI, GuardDuty/Flow Logs. Re-exportar el PNG y reemplazar la Figura 1 del informe. Iconos oficiales: AWS Architecture Icons, OCI Architecture Diagram Toolkit v24.2, Azure y Google Cloud.
- [ ] Completar §1, portada (integrantes, códigos, docente, ciclo, fecha), conclusiones (§24) **solo** con resultados reales, y anexos A–J con evidencias del agente 10.
- [ ] Aclarar con el docente la discrepancia de pesos de la rúbrica (suman 18,5, no 20) y registrar la respuesta en `docs/`.
- [ ] Verificar la trazabilidad RF/RNF ↔ pruebas ↔ rúbrica (§5.4 y §27.1) y que los T01–T17 de §22–23 coincidan con `pruebas/`.
- [ ] Preparar el guion de sustentación (§27.3) y un plan B si la demo en vivo falla (capturas, grabación).
- [ ] Actualizar el índice (clic derecho → Actualizar campo) antes de exportar a PDF.

## 5. Criterios de aceptación
- [ ] El informe no contradice el código (nodos, límites, servicios).
- [ ] Cada afirmación de resultado tiene su `evidencias/Txx`.
- [ ] El índice y las figuras están actualizados.

## 6. Pruebas relacionadas
Todas (documentación). (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Informe y código desalineados tras cambios de HA.
- Citar costos no verificados.

## Entrega y estado
- Actualiza `agentes/estado/11-docs-costos.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

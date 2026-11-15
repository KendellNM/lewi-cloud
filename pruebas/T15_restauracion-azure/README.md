# T15 — Restauración Azure

| Campo | Valor |
|---|---|
| Procedimiento | Descargar la copia de Azure Blob Storage (identidad administrada de la VM), verificar hash y clave, restaurar datos y objetos, y probar la aplicación. |
| Aceptación | Servicio funcional desde una copia independiente; medir RTO/RPO y pérdida. |
| Stacks implicados | 60, 90, 08 |
| Criterios de la rúbrica | 9, 10, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T15_restauracion-azure/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

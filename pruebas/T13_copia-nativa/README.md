# T13 — Copia nativa

| Campo | Valor |
|---|---|
| Procedimiento | Restaurar un punto RDS/AWS Backup compatible en un recurso aislado. |
| Aceptación | Consultar datos de control y registrar RTO/RPO. |
| Stacks implicados | 10, 08 |
| Criterios de la rúbrica | 9, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T13_copia-nativa/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

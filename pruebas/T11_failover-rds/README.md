# T11 — Failover RDS

| Campo | Valor |
|---|---|
| Procedimiento | Provocar una conmutación administrada en ventana controlada y seguir transacciones y suscripción. |
| Aceptación | La aplicación reconecta, los datos se conservan y la replicación continúa o se recupera por procedimiento. |
| Stacks implicados | 10, 09 |
| Criterios de la rúbrica | 6, 9, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T11_failover-rds/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

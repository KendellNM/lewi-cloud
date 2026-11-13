# T10 — Redundancia VPN

| Campo | Valor |
|---|---|
| Procedimiento | Interrumpir un camino y observar BGP y tráfico; luego una caída total controlada. |
| Aceptación | El camino alterno funciona; la caída total no habilita un segundo escritor. |
| Stacks implicados | 30 |
| Criterios de la rúbrica | 3, 6, 10, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T10_redundancia-vpn/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

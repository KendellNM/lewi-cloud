# T08 — Falla de aplicación

| Campo | Valor |
|---|---|
| Procedimiento | Retirar un nodo AWS y un miembro del pool OCI durante solicitudes continuas. |
| Aceptación | El balanceador retira el destino, el servicio continúa y la capacidad se repone; registrar errores y tiempo. |
| Stacks implicados | 40, 50, 09 |
| Criterios de la rúbrica | 6, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T08_falla-aplicacion/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

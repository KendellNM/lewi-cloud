# T14 — Activación OCI

| Campo | Valor |
|---|---|
| Procedimiento | Simular la pérdida de AWS, aislar el escritor, validar OCI, habilitar la aplicación y cambiar el origen. |
| Aceptación | Un solo escritor, secuencias correctas y pedidos válidos; RTO/RPO medidos. |
| Stacks implicados | 20, 50, 80, 08 |
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
- [ ] Resultado registrado en `evidencias/T14_activacion-oci/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

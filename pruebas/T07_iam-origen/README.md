# T07 — IAM y origen

| Campo | Valor |
|---|---|
| Procedimiento | Probar una acción fuera del rol; enviar una petición que active una regla WAF; intentar el bypass del origen (sin `x-origin-verify`). |
| Aceptación | Denegación auditable, regla activada y origen protegido. Revisar OCI por separado. |
| Stacks implicados | 40, 50, 80 |
| Criterios de la rúbrica | 5, 12 |
| Responsable | agente 10 (con los agentes dueños de los stacks) |

## Antes de empezar
- [ ] Estado base verificado (sistema sano, un solo escritor).
- [ ] Datos **sintéticos** únicamente.
- [ ] Reloj sincronizado (NTP) en los equipos de medición.

## Procedimiento detallado
_(el agente 10 lo completa: comandos exactos, capturas a tomar, qué medir)_

## Después
- [ ] Estado base restaurado.
- [ ] Resultado registrado en `evidencias/T07_iam-origen/RESULTADO.md`.
- [ ] Sin secretos en capturas ni logs.

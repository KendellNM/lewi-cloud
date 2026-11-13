# Agentes

Cada integrante toma **un** archivo, se lo entrega a su agente de IA (Claude, ChatGPT, Gemini, etc.) con este prompt:

> Lee `AGENTS.md` y `agentes/NN-nombre.md` en el repositorio del proyecto. Eres ese agente. Trabaja solo en tu alcance, cumple los criterios de aceptación, no inventes resultados y actualiza `agentes/estado/NN-nombre.md`.

| N.º | Archivo | Responsabilidad |
|---|---|---|
| 00 | [`00-coordinador.md`](00-coordinador.md) | Coordinador (humano líder + su agente) |
| 01 | [`01-aws-red-seguridad.md`](01-aws-red-seguridad.md) | AWS — Red y seguridad |
| 02 | [`02-aws-datos.md`](02-aws-datos.md) | AWS — Datos (RDS, S3, KMS, Backup) |
| 03 | [`03-aws-app-edge.md`](03-aws-app-edge.md) | AWS — Aplicación, ALB, WAF y borde |
| 04 | [`04-oci-red-datos.md`](04-oci-red-datos.md) | OCI — Red, PostgreSQL e IAM |
| 05 | [`05-oci-app.md`](05-oci-app.md) | OCI — Aplicación, balanceadores y WAF |
| 06 | [`06-interconexion-vpn.md`](06-interconexion-vpn.md) | Interconexión VPN AWS–OCI |
| 07 | [`07-observabilidad.md`](07-observabilidad.md) | Observabilidad y alarmas |
| 08 | [`08-dr-backup.md`](08-dr-backup.md) | Continuidad: copias, GCP y Azure |
| 09 | [`09-aplicacion.md`](09-aplicacion.md) | Aplicación web de demostración |
| 10 | [`10-pruebas-evidencias.md`](10-pruebas-evidencias.md) | Pruebas T01–T17 y evidencias |
| 11 | [`11-docs-costos.md`](11-docs-costos.md) | Informe, diagrama y costos |

Sugerencia de reparto para un grupo de 4–5 personas: cada persona toma 2–3 agentes afines (p. ej. 01+02+03 AWS; 04+05+06 OCI y VPN; 07+08 operación y continuidad; 09+10 aplicación y pruebas; 11+00 documentación y coordinación).

# backup/ — copia portable y recuperación (agente 08)

Archivos a crear:

| Archivo | Función |
|---|---|
| `export.sh` | `pg_dump` + objetos + `manifiesto.json` (versión, corte, inventario, SHA-256); cifra antes de trasladar |
| `relay/` | Servicio en OCI (TCP 443 tras el LB privado): valida hash, guarda en Object Storage, copia a GCS; idempotente |
| `upload-gcs.sh` | Ruta alterna F05: AWS → GCS directo |
| `schedule.md` | Systems Manager Run Command + EventBridge cada hora, con bloqueo |
| `publish-metric.sh` | Publica `Abelito/Backup` · `MinutosDesdeUltimaCopiaVerificada` |
| `restore-oci.md` | Activación de OCI con un único escritor (§19.5.2) |
| `restore-azure.sh` | Restauración en Azure desde GCS (§19.5.3) |
| `retorno.md` | Retorno planificado a AWS (§19.5.4) |

La clave de cifrado debe estar disponible **fuera de AWS** durante una contingencia.

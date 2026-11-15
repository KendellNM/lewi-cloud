# backup/ — copia portable y recuperación (agente 08)

Archivos a crear:

| Archivo | Función |
|---|---|
| `export.sh` | `pg_dump` + objetos + `manifiesto.json` (versión, corte, inventario, SHA-256); cifra antes de trasladar |
| `relay/` | Servicio en OCI (TCP 443 tras el LB privado): valida hash, guarda en Object Storage, copia a Azure Blob Storage; idempotente |
| `upload-azure.sh` | Ruta alterna F05: AWS → Azure Blob directo |
| `schedule.md` | Systems Manager Run Command + EventBridge cada hora, con bloqueo |
| `publish-metric.sh` | Publica `Abelito/Backup` · `MinutosDesdeUltimaCopiaVerificada` |
| `restore-oci.md` | Activación de OCI con un único escritor (§19.5.2) |
| `restore-azure.sh` | Restauración en Azure desde Azure Blob (§19.5.3) |
| `retorno.md` | Retorno planificado a AWS (§19.5.4) |

La clave de cifrado debe estar disponible **fuera de AWS** durante una contingencia.

Almacenamiento (stack `60-backup-azure`): cuenta `e3abelito<sufijo>`, contenedor `copias-portables`, solo Entra ID (sin claves compartidas), versionado y borrado recuperable de 7 días, región `centralus`. El relay y el job escriben con un *service principal* acotado al contenedor; las VM de recuperación leen con identidad administrada.

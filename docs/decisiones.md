# Registro de decisiones

| Fecha | Decisión | Motivo | Quién |
|---|---|---|---|
| 2026-11-13 | Alta disponibilidad por encima del costo | Decisión del grupo | grupo |
| 2026-11-13 | Un NAT por AZ | Elimina SPOF de egreso y SSM; más barato que endpoints de interfaz | grupo |
| 2026-11-13 | LB privado L4 en OCI en vez de NLB | El Instance Pool solo se asocia a Load Balancer | grupo |
| 2026-11-13 | ASG 4–8, pool OCI 4–6, PostgreSQL OCI con standby, WAF en AWS y OCI | Prioridad HA | grupo |
| 2026-11-14 | Se elimina Google Cloud; proveedores AWS + OCI + Azure | Decisión del docente/grupo | grupo |
| 2026-11-14 | La copia portable independiente pasa a Azure Blob Storage (Central US, solo Entra ID, versionado); Azure sigue siendo la recuperación en frío | Mantener una copia fuera de AWS y OCI sin un cuarto proveedor; restaurar dentro de Azure evita egreso y usa identidad administrada | grupo |
| 2026-11-14 | Región de Azure: `centralus` (Iowa) | `eastus` y `eastus2` están en Virginia (misma zona geográfica que AWS/OCI) | grupo |
| | _(agregar aquí)_ | | |

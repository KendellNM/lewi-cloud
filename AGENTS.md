# AGENTS.md — Reglas comunes para todos los agentes de IA

Proyecto: **Abelito Lewista S.A.C.** — arquitectura multicloud (AWS principal, OCI recuperación, GCP copia, Azure recuperación en frío).
Curso Cloud Computing, UPeU. Lee este archivo **completo** y luego **tu archivo** en `agentes/NN-nombre.md`.

## 1. Cómo trabajar
1. Tu archivo `agentes/NN-nombre.md` define tu **alcance**, tus **entradas/salidas** y tus **tareas**. No salgas de ahí.
2. Solo edites archivos que tu agente **posee** (ver matriz de la sección 3). Si necesitas un cambio en algo ajeno, escribe una petición en `agentes/estado/NN-nombre.md` (sección "Peticiones") y avisa al coordinador. No lo edites tú.
3. Antes de dar algo por terminado, ejecuta tus **criterios de aceptación** (sección 5 de tu archivo) y pega el resultado en tu archivo de estado.
4. Actualiza `agentes/estado/NN-nombre.md` al empezar y al terminar cada sesión (qué hiciste, qué falta, bloqueos).
5. Idioma: **español** en documentación, comentarios y mensajes; identificadores de código en inglés o español sin tildes.
6. Una rama por agente si usan Git (`agente/NN-nombre`). El coordinador integra. Si aún no hay repositorio: `git init` en `E:\Lewi` antes de empezar.

## 2. Reglas técnicas obligatorias
- **Nunca** pongas secretos, claves, tokens, OCID de tenancy reales, contraseñas ni `.tfstate` en archivos versionados. Usa variables de entorno, `terraform.tfvars` (ignorado por Git) o los gestores de secretos.
- Todo Terraform: `terraform fmt -recursive` y `./scripts/validate-all.sh` (en `03_IaC/`) deben pasar **antes** de entregar. Si no puedes ejecutar Terraform, dilo explícitamente; no declares "validado".
- **No cambies nombres de salidas** (`outputs.tf`) de un stack: son un contrato (sección 5). Si hace falta, pide el cambio al coordinador.
- Versiones fijadas (`versions.tf`, `.terraform.lock.hcl`). No subas versiones de proveedor sin avisar.
- Mínimo privilegio, recursos privados por defecto, cifrado en reposo y en tránsito. **Ningún** puerto de base de datos ni SSH abierto a Internet.
- **Un solo escritor** de base de datos en todo momento (RDS en operación normal; OCI solo tras la activación manual). Nunca automatices el cambio de escritor.
- Etiquetas obligatorias en recursos: `proyecto`, `entorno`, `propietario`, `expiracion`.
- No inventes resultados: las mediciones (RTO/RPO, latencias, costos reales) salen de pruebas ejecutadas. Los campos vacíos del informe se llenan **solo** con evidencia en `evidencias/`.
- El alta disponibilidad **tiene prioridad sobre el costo** (decisión del grupo). Aun así documenta el costo de lo que añadas.

## 3. Matriz de propiedad (quién edita qué)

| Agente | Posee |
|---|---|
| 00 coordinador | `AGENTS.md`, `agentes/`, `README.md`, integración, `.gitignore` raíz |
| 01 aws-red-seguridad | `03_IaC/modules/aws/network`, `03_IaC/modules/aws/security`, `03_IaC/stacks/10-aws-base` (partes red/seguridad) |
| 02 aws-datos | `03_IaC/modules/aws/data`, parte de datos de `stacks/10-aws-base`, `datos/` |
| 03 aws-app-edge | `03_IaC/modules/aws/app`, `03_IaC/stacks/40-aws-app`, `03_IaC/stacks/80-dns` |
| 04 oci-red-datos | `03_IaC/modules/oci/network`, `modules/oci/data`, `modules/oci/iam`, `stacks/20-oci-base` |
| 05 oci-app | `03_IaC/modules/oci/app`, `03_IaC/stacks/50-oci-app` |
| 06 interconexion-vpn | `03_IaC/stacks/30-interconnect`, `03_IaC/scripts/apply-vpn.sh` |
| 07 observabilidad | `03_IaC/modules/aws/observability`, `modules/oci/observability`, `stacks/70-observability` |
| 08 dr-backup | `03_IaC/modules/gcp`, `modules/azure`, `stacks/60-backup-gcp`, `stacks/90-azure-recovery`, `backup/` |
| 09 aplicacion | `app/`, `03_IaC/modules/shared` (solo el script de arranque del origen) |
| 10 pruebas-evidencias | `pruebas/`, `evidencias/`, `03_IaC/scripts/teardown-check.sh` |
| 11 docs-costos | `Proyecto_Final_*.docx`, `02_Arquitectura/`, `docs/`, `costos/` |

`03_IaC/00-bootstrap`, `03_IaC/scripts/*.sh` (salvo los indicados) y `03_IaC/README.md`: **coordinador**.

## 4. Flujo de despliegue (orden de dependencias)
```
00-bootstrap → 10-aws-base ─┐
               20-oci-base ─┴→ 30-interconnect → 40-aws-app → 50-oci-app → 60-backup-gcp → 70-observability → 80-dns → (90-azure-recovery, solo ensayo T15)
```
Destruir en orden inverso (`03_IaC/scripts/destroy-all.sh`). `00-bootstrap` y el dominio/zona de Cloudflare **no** se destruyen.

## 5. Contrato de salidas entre stacks
| Stack | Salidas que otros stacks consumen (`terraform_remote_state`) |
|---|---|
| `10-aws-base` | `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `app_subnet_ids`, `vgw_id`, `nat_public_ips`, `alb_sg_id`, `app_sg_id`, `rds_sg_id`, `kms_key_arn`, `db_identifier`, `db_endpoint`, `db_master_secret_arn`, `allocated_storage_gb`, `objects_bucket_arn`, `exports_bucket` |
| `20-oci-base` | `compartment_id`, `tenancy_ocid`, `region`, `drg_id`, `vcn_id`, `public_subnet_id`, `app_subnet_id`, `nsg_lb_id`, `nsg_relay_lb_id`, `nsg_app_id`, `postgres_private_ip`, `postgres_standby_private_ip`, `bucket_name`, `availability_domain`, `bastion_id` |
| `30-interconnect` | `aws_tunnel_ips`, `paired_tunnel_ips`, `oci_tunnel_ips` |
| `40-aws-app` | `alb_dns_name`, `alb_arn_suffix`, `target_group_arn_suffix`, `asg_name` |
| `50-oci-app` | `web_lb_ip`, `relay_lb_ip`, `pool_id` |
| `60-backup-gcp` | `bucket_name`, `writer_sa_email`, `reader_sa_email` |
| `70-observability` | `aws_dashboard`, `aws_sns_topic_arn` |
| `80-dns` | `active_origin` |
| `90-azure-recovery` | `app_public_ip`, `db_private_ip` |

## 6. Credenciales (las pone cada humano, nunca el agente en archivos)
| Variable | Para qué |
|---|---|
| credenciales AWS (`AWS_PROFILE` o `AWS_ACCESS_KEY_ID/SECRET/SESSION_TOKEN` del Learner Lab) | stacks 00, 10, 30, 40, 70 |
| `~/.oci/config` (perfil DEFAULT) o `OCI_*` / `TF_VAR_tenancy_ocid` | stacks 20, 30, 50, 70 |
| `GOOGLE_APPLICATION_CREDENTIALS` y `TF_VAR_gcp_project_id` | stacks 00 (opcional), 60 |
| `ARM_SUBSCRIPTION_ID` / `az login` | stack 90 |
| `CLOUDFLARE_API_TOKEN` (Zone DNS, Zone Settings, Transform Rules) | stacks 40, 80 |
| `CLOUDFLARE_API_USER_SERVICE_KEY` (Origin CA Key) | stack 50 |

## 7. Mapa del repositorio
```
E:\Lewi
├── AGENTS.md                 este archivo
├── README.md                 índice para humanos
├── agentes/                  un .md por agente + estado/ (bitácora de cada uno)
├── 02_Arquitectura/          diagrama draw.io (iconos oficiales) y PNG
├── 03_IaC/                   Terraform: bootstrap, modules, stacks, scripts
├── app/                      aplicación web de demostración (agente 09)
├── datos/                    esquema SQL, datos sintéticos, roles y replicación (agentes 02/04)
├── backup/                   scripts de copia portable, relay y restauración (agente 08)
├── pruebas/                  T01–T17: especificación y scripts (agente 10)
├── evidencias/               T01–T17: resultados y capturas (agente 10)
├── costos/                   cotización y consumo real (agente 11)
├── docs/                     notas, decisiones y material de sustentación (agente 11)
├── Proyecto_Final_Cloud_Abelito_Lewista_borrador.docx   original (no tocar)
└── Proyecto_Final_Cloud_Abelito_Lewista_v2.docx          informe de trabajo (agente 11)
```

## 8. Estado actual (lo que YA existe)
- `terraform validate` **pasa** en los 10 directorios; **nunca se ejecutó plan/apply** (no hay cuentas conectadas). Lo primero que cada agente debe hacer con credenciales reales es `terraform plan` de su stack y corregir lo que falle (permisos del Learner Lab, cuotas, nombres).
- Alta disponibilidad ya parametrizada: ASG 4–8 (2 por AZ), NAT por AZ, RDS Multi-AZ, pool OCI 4–6 en 2 fault domains, **PostgreSQL OCI primario + standby** en fault domains distintos, dos caminos VPN, WAF en AWS **y** en OCI, GuardDuty, VPC Flow Logs, logs del ALB.
- El origen de demostración es un **nginx** con `/healthz` (módulo `shared`). La aplicación real y los scripts de datos/copias están **pendientes** (agentes 09, 02, 08).

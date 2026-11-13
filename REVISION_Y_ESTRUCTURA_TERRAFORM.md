# Estado tras las correcciones (actualizado)

| Entregable | Ubicación | Estado |
|---|---|---|
| Terraform | `03_IaC/` | Escrito. `terraform fmt` + `terraform validate` OK en los 10 directorios (`scripts/validate-all.sh`). **No se ejecutó plan/apply.** |
| Informe corregido | `Proyecto_Final_Cloud_Abelito_Lewista_v2.docx` | El borrador original no se modificó. Al abrir Word pide actualizar campos: aceptar para refrescar índice y paginado. |
| Diagrama | `02_Arquitectura/arquitectura_multicloud.drawio` (+ `.png`) | Iconos oficiales: AWS Architecture Icons, OCI Architecture Diagram Toolkit v24.2 (descargado de Oracle), Azure y Google Cloud de draw.io. Ya está insertado como Figura 1 en el v2. |

**Corregido en el informe:** §1 Introducción y objetivos (nueva); NAT por AZ; NLB → LB privado (un Instance Pool no se asocia a NLB); pool OCI máx. 3; alarma de copias 90 min; §13.5 análisis de amenazas; §14.1 tabla de puntos únicos de falla; §18 alineada con los stacks reales; backup de RDS sin "volúmenes"; job de copias con cómputo asignado; §21.4 costos en USD; sesiones recomendadas (2 de ~3 h); portada "S.A.C.".

**Cambio de criterio respecto a la primera versión de este documento:** se recomendaba "1 NAT + endpoints SSM". Calculado, 5 endpoints de interfaz en 2 AZ (~USD 0,10/h) cuestan más que un segundo NAT (USD 0,045/h). Se adoptó **1 NAT por AZ**.

La estructura de carpetas Terraform descrita abajo es la propuesta inicial; la real y vigente está en `03_IaC/README.md`.

---

# Revisión del proyecto Abelito Lewista S.A.C. + estructura Terraform recomendada

Archivos revisados (todos en `E:\Lewi`): descripción del proyecto, rúbrica xlsx (14 criterios), rúbricas Entregable 1 y 2, y el borrador `Proyecto_Final_Cloud_Abelito_Lewista_borrador.docx` (secciones 2–27).

**Hallazgo principal:** el borrador es un diseño teórico sólido, pero **no existe nada implementado**: no hay carpeta Terraform, ni el `.drawio` citado, ni evidencias. La descripción del proyecto exige "infraestructura operativa y demostración en vivo". La prioridad es construir, no seguir escribiendo.

---

## 1. Incoherencias detectadas en el informe

| # | Sev. | Dónde | Problema | Cambio recomendado |
|---|------|-------|----------|--------------------|
| 1 | Alta | §8.7, §9.2, §14 | NAT Gateway único en AZ A. Si cae la AZ A, las EC2 de la AZ B pierden salida a Internet y **Systems Manager** (§13.2 lo usa como único acceso admin) deja de funcionar. §14 dice "AZ caída = automática", lo cual contradice el NAT único. | Opción barata: VPC endpoints `ssm`, `ssmmessages`, `ec2messages` (+ `logs`/`monitoring`) para que SSM y CloudWatch no dependan del NAT. Opción completa: 1 NAT por AZ. Corregir el texto de §14. |
| 2 | Alta | Rúbrica criterio 6 | La rúbrica penaliza "punto único de falla evidente". Hay 3 SPOF: NAT, PostgreSQL OCI (1 nodo), cambio manual de DNS. Están admitidos, pero dispersos. | Agregar tabla explícita de SPOF (ver §2 de este documento). |
| 3 | Alta | §21 | Costos sin ningún monto total. La rúbrica pide "costos, dimensionamiento, análisis y propuestas concretas". Hoy solo hay fórmulas y un ejemplo de ALB. | Llenar la tabla con USD estimados por proveedor (AWS Pricing Calculator, OCI cost estimator). Total bruto, créditos, neto. |
| 4 | Media | §16 vs §10 | OCI Always Free = 4 OCPU / 24 GB (Ampere A1). Pool máx. 4 nodos × 1 OCPU + 1 DB = **5 OCPU**, excede lo gratuito. Además las instancias gratuitas son ARM; el texto ya avisa de compatibilidad pero no lo resuelve. | Fijar pool máx. = 3 (3+1 = 4 OCPU) o aceptar costo y documentarlo. Decidir ARM vs x86 antes de armar la imagen. |
| 5 | Media | §17 vs §19.4 | Alarma "sin copia verificada en la última hora" y backup "cada hora": la alarma saltará en el límite exacto. | Umbral de alarma 90 min. |
| 6 | Media | §22 | Orden de pruebas desordenado: T10 está en conectividad, T11 tras T09, T12 en monitoreo, T13+ al final. Dificulta seguirlas. | Reordenar numeración por orden de ejecución (el propio §22 ya define el orden recomendado). |
| 7 | Media | Índice / numeración | El índice y los títulos empiezan en **§2**. Falta §1 (Introducción, objetivo general y específicos, alcance). | Agregar §1 o renumerar. Es lo primero que revisa el docente en "Problema y requerimientos". |
| 8 | Media | Portada | Campos vacíos (integrantes, código, docente, ciclo, fecha). Título dice "S A C", el texto "S.A.C.". | Completar y unificar. |
| 9 | Media | §27.1 | Pesos de rúbrica suman 18,5 y no 20. Ya está anotado, pero sin resolver. | Consultar al docente **antes** de la sustentación; dejar la respuesta escrita. |
| 10 | Media | Entregable 2 rúbrica | Pide "Análisis de amenazas y vulnerabilidades". El informe tiene diseño de seguridad (§13) pero **no un análisis de amenazas** (activos, amenazas, riesgo, mitigación). | Agregar §13.5 con tabla amenaza → control → prueba (STRIDE simplificado). |
| 11 | Baja | §3.2 | Se define organigrama pero §3.2 y §5 no vinculan áreas con requisitos medibles. | Opcional; no recortar tiempo de implementación por esto. |
| 12 | Baja | Referencias | Cita `arquitectura_multicloud_corregida.drawio`, "Plantilla proyecto cloud", Entregables 1 y 2: ninguno está en la carpeta. | Incluirlos en `02_Arquitectura` o quitar la mención. |
| 13 | Baja | §13.2 | Rangos de Cloudflare en SG: son ~22 CIDR (IPv4+IPv6); el límite por defecto de reglas por SG es 60. | Usar *managed prefix list* (ver módulo `aws/security`). |

## 2. Qué falta frente a la rúbrica (14 criterios)

| Criterio (peso) | Estado | Falta |
|---|---|---|
| 1 Problema (1,0) | Bueno | §1 Introducción y objetivos. |
| 2 Arquitectura (2,0) | Bueno | Verificar que Figura 1 coincida con el texto (NAT, relay, Azure). |
| 3 Redes (2,0) | Diseño listo | Implementar; capturas de rutas y túneles. |
| 4 Cómputo/BD (1,5) | Diseño listo | Implementar. |
| 5 Seguridad (2,5) | Diseño listo | **Análisis de amenazas**, evidencias de denegación (T06/T07). |
| 6 HA/Escalabilidad (1,5) | Diseño listo | **Tabla de SPOF**, pruebas T08/T09/T11 con evidencia. |
| 7 Monitoreo (1,0) | Diseño listo | Dashboard real + alarma disparada. |
| 8 IaC (1,5) | **Cero código** | Todo lo de la sección 4 de este documento. |
| 9 Backup/RTO/RPO (1,5) | Diseño listo | Una restauración probada y medida (T13 mínimo). |
| 10 AWS–OCI (1,5) | Diseño listo | VPN + replicación lógica funcionando (T04, T10). |
| 11 Costos (0,5) | Sin cifras | Montos en USD. |
| 12 Pruebas (1,0) | Plan sin ejecutar | §23 vacía; T01–T17. |
| 13 Documentación (0,5) | Falta §1 y portada | Ver incoherencias 7, 8, 12. |
| 14 Sustentación (0,5) | Guion listo | Ensayar demo. |

**Tabla de SPOF sugerida (para §14 o §13.5):**

| Componente | SPOF | Mitigación actual | Estado |
|---|---|---|---|
| NAT Gateway AWS | Sí (AZ A) | VPC endpoints o 2º NAT | Corregir |
| PostgreSQL OCI | Sí (1 nodo) | Copia GCP + restauración Azure | Aceptado, documentar |
| Cambio de origen DNS | Sí (manual) | Procedimiento + prueba T14 | Aceptado |
| Cloudflare | Sí (proveedor DNS/proxy) | Bajar TTL, acceso directo documentado | Documentar |
| Par AWS–OCI misma zona geográfica | Sí | GCP Iowa + Azure | Aceptado |

## 3. Recomendación de alcance (riesgo real)

La descripción pide **AWS + OCI** como obligatorios; GCP y Azure son **opcionales**. El diseño actual usa 4 nubes + Cloudflare + un relay propio, con 17 pruebas, en una ventana de 6 h y con créditos de estudiante (AWS Learner Lab limita IAM, VPN y WAF; las sesiones expiran). Es el mayor riesgo del proyecto.

Prioridad sugerida (cortar desde abajo si el tiempo aprieta):

1. **P0 – Núcleo que da la nota:** AWS (VPC, ALB, ASG, RDS Multi-AZ) + OCI (VCN, LB, pool) + VPN + replicación lógica + monitoreo + Terraform.
2. **P1:** backup RDS/PITR + una restauración medida + RTO/RPO.
3. **P2:** GCS como copia externa (un bucket + un `gsutil cp`; el relay OCI puede reemplazarse por subida directa desde AWS, ya previsto en F05).
4. **P3:** Azure. Dejarlo en Terraform con `enabled = false` y ejecutarlo solo si sobra tiempo; si no, presentarlo como diseño con la limitación declarada.

Verificar **hoy** (§25 ya lo recomienda): permisos del Learner Lab para VPN site-to-site, WAF, RDS Multi-AZ y Backup. Si VPN está bloqueada, todo el criterio 10 cambia.

## 4. Estructura de carpetas Terraform recomendada

Principios: un *stack* (estado propio) por etapa, para poder aplicar/destruir por partes, aislar Azure y resolver la dependencia circular de la VPN; módulos reutilizables aparte; un solo `terraform.tfvars` por stack. Corresponde a la carpeta `03_IaC` de §27.2.

```
03_IaC/
├── README.md                      # requisitos, orden de apply/destroy, recuperación del estado
├── .gitignore                     # *.tfstate*, *.tfvars (salvo .example), .terraform/, *.pem
├── Makefile                       # make apply-all / destroy-all / plan STACK=20-aws-base
│
├── 00-bootstrap/                  # se aplica UNA vez, NO se destruye con el lab
│   ├── main.tf                    # bucket de estado (S3 cifrado+versionado) ; copia del estado en GCS
│   ├── variables.tf
│   └── outputs.tf
│
├── modules/
│   ├── aws/
│   │   ├── network/               # VPC, 6 subredes, IGW, NAT, rutas, endpoint S3, endpoints SSM, VGW + propagación
│   │   ├── security/              # SG (alb, app, rds), prefix list Cloudflare, IAM roles/instance profile, KMS, Secrets Manager
│   │   ├── alb-waf/               # ALB, listener 443, target group, ACM, WAF + reglas, rate limit
│   │   ├── compute-asg/           # launch template, ASG 2–4, target tracking CPU 60 %
│   │   ├── rds/                   # subnet group, parameter group (rds.logical_replication=1), RDS Multi-AZ
│   │   ├── storage-backup/        # S3 (bloqueo público, versionado), AWS Backup plan, job de export portable
│   │   └── observability/         # dashboard, alarmas (5xx, CPU, RDS, VPN, lag), CloudTrail, SNS
│   ├── oci/
│   │   ├── network/               # VCN, subredes, IGW/NAT/Service GW, DRG, rutas
│   │   ├── security/              # NSG, compartment, dynamic group, policies, Vault
│   │   ├── compute-pool/          # instance configuration, pool 2–3, autoscaling
│   │   ├── lb/                    # Flexible LB público + NLB privado (relay)
│   │   ├── postgres-vm/           # VM + block volume + cloud-init suscriptor
│   │   ├── storage/               # Object Storage bucket versionado
│   │   └── observability/         # alarms, logging, notifications
│   ├── interconnect/              # CGW, VPN conn AWS, CPE, IPsec OCI, BGP (ver nota de orden)
│   ├── gcp/backup-bucket/         # bucket us-central1, acceso uniforme, versionado, service account mínima
│   ├── azure/recovery/            # RG, VNet, NSG, 2 VM, discos (activar con enabled=true)
│   └── cloudflare/dns/            # registros abelito.me, modo Full (strict)
│
├── stacks/                        # un estado por carpeta; orden numérico = orden de apply
│   ├── 10-aws-base/               # network + security + rds + storage
│   ├── 20-oci-base/               # network + security + storage + postgres-vm
│   ├── 30-interconnect/           # VPN AWS–OCI (necesita salidas de 10 y 20)
│   ├── 40-aws-app/                # alb-waf + compute-asg
│   ├── 50-oci-app/                # compute-pool + lb
│   ├── 60-backup-gcp/             # bucket GCS (+ job export si aplica)
│   ├── 70-observability/          # dashboards y alarmas AWS + OCI
│   ├── 80-dns/                    # Cloudflare (origen activo = variable)
│   └── 90-azure-recovery/         # opcional, enabled=false por defecto
│       # cada stack contiene: main.tf, providers.tf, backend.tf, variables.tf,
│       #                       outputs.tf, versions.tf, terraform.tfvars.example
│
└── scripts/
    ├── verify-quotas.sh           # comprueba cuotas/permisos antes de aplicar
    ├── failover-oci.md            # pasos manuales de §19.5.2
    └── teardown-check.sh          # inventario de residuos (NAT, EIP, snapshots, versiones S3)
```

**Notas de diseño (derivadas de los problemas del informe):**

- **Dependencia circular de la VPN.** AWS necesita las IP públicas del lado OCI para el Customer Gateway, y OCI necesita las IP de los túneles AWS para el CPE. Terraform no admite ciclos. En `30-interconnect` usar dos fases: (1) crear CPE/IPsec OCI con IP provisional, (2) crear CGW/VPN AWS, (3) reaplicar el CPE con las IP reales de AWS. Documentarlo en el README; §18 ya avisa "no se prometerá creación ciega".
- **Estado.** `00-bootstrap` queda fuera del teardown (T17). Si AWS Learner Lab reinicia credenciales o borra el bucket, el estado se pierde: mantener copia en GCS (se menciona en §18 pero no tiene dónde vivir).
- **Versiones fijas.** `required_version` y `required_providers` con versión exacta en cada `versions.tf` (RNF06, T16).
- **Etiquetas comunes.** `proyecto`, `entorno`, `propietario`, `expiracion` vía `default_tags` (AWS) y `defined_tags`/`freeform_tags` (OCI). Prefijo `e3-abelito` (§18.1).
- **Secretos.** Nada en `.tfvars` versionado; usar `TF_VAR_*` o Secrets Manager/Vault. `sensitive = true` no evita que aparezcan en el estado.
- **Módulos pequeños, stacks delgados.** Cada stack solo instancia módulos y pasa variables; la lógica vive en `modules/`. Evita duplicar entre `lab` y futuros entornos.
- **Mapeo a requisitos:**

| Stack | Cubre |
|---|---|
| 10-aws-base | RF02, RF03, RF04, RNF03, RNF07 |
| 20-oci-base | RF07, RF08, RNF03 |
| 30-interconnect | RF07, P06, criterio 10 |
| 40-aws-app | RF01, RF05, RF06, RNF01, RNF02 |
| 50-oci-app | RF05, RF06, RF08 |
| 60-backup-gcp | RF04, RF08, RNF07 |
| 70-observability | RF09, RNF08, T12 |
| 80-dns | RF01, RF08 |
| 90-azure-recovery | RF08, T15 |

**Orden de apply:** `00 → 10 → 20 → 30 → 40 → 50 → 60 → 70 → 80 → (90)`. **Destroy:** orden inverso, y revisar con `teardown-check.sh`.

## 5. Plan de trabajo sugerido

1. Verificar cuotas/permisos (Learner Lab, OCI Ashburn, GCP, Azure) y decidir ARM vs x86 en OCI.
2. Resolver las incoherencias 1, 3, 4 y 7 en el documento (son las que más pesan en la rúbrica).
3. `00-bootstrap`, `10-aws-base`, `40-aws-app`: servicio web funcionando con HTTPS (T01, T02).
4. `20-oci-base`, `30-interconnect`: VPN y replicación (T03, T04, T10).
5. `50-oci-app`, `70-observability`: balanceo OCI, dashboard, alarma (T08, T09, T12).
6. Backup + restauración medida (T13), luego `60-backup-gcp`.
7. Activación OCI (T14), luego Azure si hay tiempo (T15).
8. Rellenar §23, anexos A–J, costos reales y teardown (T16, T17).
9. Ensayar sustentación con el guion §27.3.

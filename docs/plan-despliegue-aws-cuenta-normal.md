# Plan de despliegue en una cuenta AWS normal (no Learner Lab)

Alcance: levantar la parte AWS del proyecto —red, RDS y **EC2 detrás del ALB**— en una cuenta AWS real. El código es el de `03_IaC/` (`terraform validate` pasa; **nunca se ha ejecutado `plan`/`apply`**, así que este plan incluye cómo detectar y corregir lo que falle).

Responsables: agentes 01, 02 y 03 (`agentes/`); coordina el agente 00.

---

## 1. Qué cambia respecto al Learner Lab

| Tema | Learner Lab | Cuenta normal |
|---|---|---|
| Roles IAM | Solo `LabRole`, no se pueden crear | Terraform **sí** crea roles (instancia EC2, Backup, Flow Logs). Dejar los `enable_*` en `true`. |
| VPN, WAF, GuardDuty, Backup | Pueden estar bloqueados | Disponibles. |
| Duración | Sesiones que expiran | Permanente: **hay que destruir a mano** o sigue facturando. |
| Cuotas | Fijas del laboratorio | **Cuotas bajas en cuentas nuevas** (ver 2.3). |
| Costos | Créditos | **Dinero real**: el diseño de alta disponibilidad es caro si se deja encendido. |

Variables a dejar así en cuenta normal (ya son los valores por defecto):

```hcl
# stacks/10-aws-base/terraform.tfvars
enable_backup = true     # AWS Backup con rol creado por Terraform
nat_per_az    = true     # un NAT por AZ
# stacks/70-observability: enable_guardduty = true  (false solo si ya existe un detector)
# modules/aws/network: enable_flow_logs = true      (por defecto)
```

## 2. Prerrequisitos (hacer antes de tocar Terraform)

### 2.1 Cuenta y acceso
- [ ] Cuenta AWS con **MFA en el usuario raíz**; no usar la raíz para operar.
- [ ] Usuario/rol de operación (p. ej. IAM Identity Center o usuario IAM con MFA). Para el laboratorio académico basta `AdministratorAccess` **temporal**; reducirlo después.
- [ ] `aws configure` (o `AWS_PROFILE`) y comprobar: `aws sts get-caller-identity`.
- [ ] Región **us-east-1** (Norte de Virginia). No mezclar regiones.
- [ ] Terraform ≥ 1.10 (`terraform version`).

### 2.2 Protección de costos (obligatorio)
- [ ] AWS Budgets: presupuesto mensual con alertas al 50 %, 80 % y 100 % (correo del grupo).
- [ ] Billing alerts y Cost Explorer activados.
- [ ] Etiqueta `expiracion` en todos los recursos (ya la ponen los stacks) y fecha de destrucción acordada.

### 2.3 Cuotas (Service Quotas, región us-east-1) — **pedirlas el primer día**
Las cuentas nuevas suelen tener cuotas bajas y la solicitud puede tardar horas o días.

| Cuota | Necesario | Por qué |
|---|---|---|
| *Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances* (vCPU) | **≥ 24 vCPU** | ASG 4–8 × `t3.small` (2 vCPU) = 8–16 vCPU, más margen para reemplazos |
| Elastic IPs | ≥ 5 (por defecto) | 2 NAT (uno por AZ) |
| NAT gateways por AZ | 5 (por defecto) | basta |
| VPN connections | ≥ 2 | 2 caminos hacia OCI (por defecto 50) |
| Application Load Balancers | 1 | basta |
| RDS: instancias DB | 1 | basta |

### 2.4 Cloudflare y dominio
- [ ] `abelito.me` registrado en Namecheap con nameservers delegados a Cloudflare.
- [ ] Obtener el **Zone ID** de la zona.
- [ ] Token de API de Cloudflare (permisos: *Zone → DNS → Edit*, *Zone Settings → Edit*, *Transform Rules → Edit*) y exportarlo: `export CLOUDFLARE_API_TOKEN=...`
- [ ] Verificar los rangos de IP de Cloudflare contra <https://www.cloudflare.com/ips-v4> y actualizar `modules/aws/security/variables.tf` si cambiaron.

### 2.3 bis — Datos que se necesitan de OCI (para la VPN, más adelante)
Los stacks 30 y siguientes necesitan OCI desplegado. Para levantar solo AWS + EC2 **no hace falta**; la VPN se hace después.

---

## 3. Orden para levantar AWS + EC2

```
00-bootstrap → 10-aws-base → 40-aws-app (EC2/ALB/WAF) → 70-observability (parte AWS) → 80-dns   [después: 20-oci-base → 30-interconnect → 50-oci-app y oci_enabled=true]
```

### Paso 0 — Estado remoto (una sola vez)
```bash
cd 03_IaC/00-bootstrap
terraform init
terraform apply -var owner=<tu-nombre>
terraform output -raw backend_hcl > ../backend.hcl      # bucket y región del estado (no subir a Git)
```
Este stack **no se destruye** con el resto.

### Paso 1 — Red, seguridad y datos: `stacks/10-aws-base`
```bash
cd ../stacks/10-aws-base
cp terraform.tfvars.example terraform.tfvars   # owner, expiry
terraform init -backend-config=../../backend.hcl
terraform plan -out=plan.out                    # REVISAR antes de aplicar
terraform apply plan.out
```
Crea: VPC `10.10.0.0/16`, 6 subredes en 2 AZ, IGW, **2 NAT**, VGW, endpoint S3, grupos de seguridad (ALB solo desde Cloudflare), KMS, **RDS PostgreSQL Multi-AZ** (tarda ~15–25 min), buckets S3, AWS Backup y VPC Flow Logs.

Comprobaciones:
```bash
terraform output
aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].[NatGatewayId,SubnetId]'
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,MultiAZ,DBInstanceStatus]'
```
- [ ] Hay 2 NAT en subredes públicas distintas.
- [ ] RDS `MultiAZ = True` y `available`.
- [ ] **Reinicio de RDS**: el parámetro `rds.logical_replication` es estático; reiniciar una vez la instancia antes de configurar la replicación (`aws rds reboot-db-instance`).

### Paso 2 — EC2 con ALB, WAF y Auto Scaling: `stacks/40-aws-app`
```bash
cd ../40-aws-app
cp terraform.tfvars.example terraform.tfvars   # owner, expiry, state_bucket, cloudflare_zone_id
export TF_VAR_origin_verify_secret="$(openssl rand -hex 32)"   # guardar; el MISMO valor va al stack 80
terraform init -backend-config=../../backend.hcl
terraform plan -out=plan.out
terraform apply plan.out
```
Qué levanta (EC2 "normales", no de laboratorio):
- **Certificado ACM** validado por DNS en Cloudflare (puede tardar unos minutos).
- **ALB** público en 2 subredes públicas + **AWS WAF** (reglas comunes de AWS, límite por IP del cliente, cabecera `x-origin-verify` si definiste el secreto).
- **Launch template**: Amazon Linux 2023, `t3.small`, IMDSv2 obligatorio, disco gp3 20 GiB cifrado, **sin IP pública**, perfil IAM con SSM + CloudWatch + S3 de objetos + secreto de BD + KMS.
- **Auto Scaling Group**: mínimo 4 / máximo 8, **2 por AZ**, health check del ELB, escalado por CPU al 60 %.
- Origen de demostración: nginx HTTPS en **8443** con `/healthz` (hasta que el agente 09 entregue la aplicación real).

> Las `t3` usan créditos de CPU: en la prueba de carga (T09) vigila `CPUCreditBalance`; en modo *unlimited* se cobra el exceso.

### Paso 3 — DNS y borde: `stacks/80-dns`
```bash
cd ../80-dns
cp terraform.tfvars.example terraform.tfvars   # state_bucket, cloudflare_zone_id, active_origin = "aws"
export TF_VAR_origin_verify_secret=<el mismo valor del paso 2>
terraform init -backend-config=../../backend.hcl && terraform apply
```
Deja `abelito.me` → ALB, SSL **Full (strict)**, TLS mínimo 1.2 y Cloudflare añadiendo la cabecera secreta hacia el origen.

> Con `oci_enabled = false` (valor por defecto) el stack 80 no lee el estado de OCI: sirve solo el origen AWS. Cuando OCI exista, poner `oci_enabled = true` para poder conmutar con `active_origin = "oci"`.

### Paso 4 — Monitoreo AWS: `stacks/70-observability`
Con `oci_enabled = false` (por defecto) despliega solo la parte AWS: dashboard, alarmas de ALB/ASG/RDS/copias, SNS, CloudTrail y GuardDuty. Las alarmas de VPN y las de OCI se activan con `oci_enabled = true` cuando existan los stacks 20 y 30.
```bash
cd ../70-observability
cp terraform.tfvars.example terraform.tfvars   # owner, expiry, state_bucket, alarm_email
terraform init -backend-config=../../backend.hcl && terraform apply
```

---

## 4. Verificación de las EC2

```bash
# Instancias del ASG
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3-abelito-asg \
  --query 'AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,LifecycleState,HealthStatus]'

# Salud en el target group (deben quedar 4 "healthy": 2 por AZ)
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names e3-abelito-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# Acceso administrativo SIN SSH (Systems Manager)
aws ssm start-session --target <instance-id>
```
Checklist:
- [ ] 4 instancias `InService`, 2 por AZ, sin IP pública.
- [ ] Target group: 4 `healthy`.
- [ ] `https://abelito.me/healthz` → 200 con certificado válido (T01).
- [ ] Petición directa al DNS del ALB → **bloqueada** (el SG solo admite rangos de Cloudflare; y sin `x-origin-verify` el WAF devuelve 403) (T07).
- [ ] Puerto 22 cerrado: `nc -zv <ip> 22` falla.
- [ ] Matar una instancia: el ASG repone y el servicio no se interrumpe (T08).

> Desde tu PC no podrás llegar directo al ALB (solo Cloudflare). Prueba por `https://abelito.me` o desde dentro de la VPC vía SSM.

## 5. Endurecimiento adicional recomendado en cuenta normal
- [ ] Revocar `AdministratorAccess` y dejar permisos acotados al proyecto.
- [ ] Activar AWS Config y Security Hub si el grupo lo desea (no están en Terraform).
- [ ] Rotar el `origin_verify_secret` al terminar.
- [ ] No subir `terraform.tfvars`, `backend.hcl` ni `*.tfstate` a Git (ya están en `.gitignore`).

## 6. Costos orientativos de dejar encendido (aprox., confirmar en la calculadora)
Con el diseño de alta disponibilidad actual, la parte AWS ronda **USD 330–400 al mes** si se deja encendida (RDS Multi-AZ, 2 NAT, 2 conexiones VPN, ALB, 4–8 EC2, IPv4 públicas). Por sesión de pruebas de ~6 h: **unos USD 3–5**. Regla: **encender solo para probar y destruir después**.

## 7. Destrucción (obligatoria al terminar)
```bash
cd 03_IaC
./scripts/destroy-all.sh        # orden inverso; no toca 00-bootstrap
./scripts/teardown-check.sh     # busca NAT, EIP, VPN, ALB, RDS, snapshots, volúmenes y buckets residuales
```
- [ ] Revisar a mano: snapshots de RDS, versiones antiguas de S3, grupos de logs de CloudWatch, secretos en cuarentena de Secrets Manager.
- [ ] Verificar la factura 24–48 h después.

## 8. Problemas probables en la primera ejecución
| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `VcpuLimitExceeded` al crear el ASG | Cuota de vCPU baja | Pedir aumento (2.3); mientras tanto `asg_min=2`, `asg_max=4` |
| ACM se queda en *pending validation* | Registro DNS no creado o con proxy | Revisar el registro en Cloudflare (debe ser **sin proxy**) |
| Targets `unhealthy` | nginx no arrancó o SG | `aws ssm start-session` y revisar `journalctl -u nginx`; comprobar que el SG de la app admite 8443 desde el ALB |
| 403 en `abelito.me` | `origin_verify_secret` distinto entre stacks 40 y 80 | Usar el mismo valor y volver a aplicar ambos |
| `GuardDuty already enabled` | Ya existe el detector | `enable_guardduty = false` |
| Falla Flow Logs/Backup por IAM | Permisos insuficientes del usuario | Darle `iam:CreateRole`, `iam:PassRole` |
| RDS tarda mucho | Normal en Multi-AZ | Esperar 15–25 min |

## 9. Después de AWS
1. Agente 02: esquema, roles y datos sintéticos en RDS (`datos/`).
2. Agente 09: aplicación real; el agente 03 cambia el `user_data` para descargarla.
3. Agentes 04, 05 y 06: OCI y la VPN (stacks 20, 50 y 30).
4. Agente 07: alarmas completas; agente 10: pruebas T01–T17.

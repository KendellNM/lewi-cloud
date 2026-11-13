# Agente 06 — Interconexión VPN AWS–OCI

> Lee primero `AGENTS.md` (reglas comunes, contrato de salidas y matriz de propiedad). Este archivo es **tu** encargo.

## 1. Misión
VPN site-to-site AWS–OCI con dos caminos IPsec + BGP independientes y la regla de RDS para el suscriptor.

## 2. Alcance (lo que posees y puedes editar)
- `03_IaC/stacks/30-interconnect/`
- `03_IaC/scripts/apply-vpn.sh`

**No toques** nada fuera de esta lista. Si necesitas un cambio ajeno, pídelo en `agentes/estado/06-interconexion-vpn.md` → "Peticiones".

## 3. Entradas y salidas
**Entradas**
- Stack 10: `vgw_id`, `rds_sg_id`, `vpc_cidr`. Stack 20: `drg_id`, `compartment_id`, `postgres_private_ip`, `region`.

**Salidas / contrato**
- Outputs: `aws_tunnel_ips`, `paired_tunnel_ips` (alarmas del agente 07), `oci_tunnel_ips`.

## 4. Tareas (marca al completar)
- [ ] Leer los comentarios de `stacks/30-interconnect/main.tf`: la dependencia circular se resuelve en **dos aplicaciones** (`apply-vpn.sh`).
- [ ] Primera ejecución real: confirmar que OCI acepta la IP provisional del CPE (`cpe_placeholder_ip`) con `oracle_can_initiate = RESPONDER_ONLY`. Si la rechaza, probar otra IP pública o el flujo manual descrito en la guía AWS–OCI.
- [ ] Confirmar qué túnel de cada lado se empareja: `ip_sec_connection_tunnels[0]` no tiene orden garantizado; si es incorrecto, seleccionar por `vpn_ip`.
- [ ] Comprobar parámetros IKE/IPsec compatibles (hoy valores por defecto de ambos lados); fijarlos explícitos si hay renegociación inestable.
- [ ] Verificar BGP: AWS debe aprender `10.20.0.0/16` y OCI `10.10.0.0/16`; tablas de rutas de app y datos con rutas propagadas; MTU y simetría.
- [ ] Probar redundancia: apagar un camino y observar tráfico por el otro (T10); registrar tiempos de convergencia.
- [ ] La regla `aws_vpc_security_group_ingress_rule.rds_from_subscriber` abre 5432 solo al `/32` del suscriptor: verificar que sigue siendo el `/32` correcto tras recrear OCI.
- [ ] Los túneles sin pareja (`tunnel2` de AWS) aparecerán DOWN: es esperado; no alarmar por ellos.

## 5. Criterios de aceptación
- [ ] `terraform validate` del stack 30.
- [ ] Ambos túneles emparejados `UP` y sesiones BGP `ESTABLISHED`.
- [ ] `ping`/`nc` privado AWS↔OCI; resolución del endpoint de RDS a IP privada desde OCI (T03).

## 6. Pruebas relacionadas
T03, T04, T10. (especificaciones en `pruebas/`, resultados en `evidencias/`).

## 7. Riesgos conocidos
- Es la pieza más frágil: dependencia circular, IP del CPE, orden de túneles.
- Learner Lab podría bloquear VPN.

## Entrega y estado
- Actualiza `agentes/estado/06-interconexion-vpn.md` (hecho / pendiente / bloqueos / peticiones a otros agentes).
- Al terminar: pega la salida de tus criterios de aceptación y avisa al coordinador.
- Reglas generales: `AGENTS.md`. Si algo de aquí contradice `AGENTS.md`, manda `AGENTS.md`.

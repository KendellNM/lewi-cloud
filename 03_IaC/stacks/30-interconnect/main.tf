# VPN site-to-site AWS <-> OCI con BGP y DOS caminos independientes (a y b).
#
# Cada camino = 1 conexion AWS + 1 conexion OCI usando UN tunel de cada una. Los otros tuneles
# (tunnel2 de AWS, el segundo de OCI) quedan sin pareja: por eso las alarmas solo miran los emparejados.
#
# Dependencia circular: AWS necesita la IP publica de OCI (Customer Gateway) y OCI necesita la IP del
# tunel AWS (cpe_local_identifier). Se resuelve en DOS aplicaciones: scripts/apply-vpn.sh.
#   1) var.aws_tunnel_ips = {}  -> crea todo; OCI queda con el identificador provisional.
#   2) var.aws_tunnel_ips = output aws_tunnel_ips -> OCI actualiza el identificador (cambio in-place).

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

provider "oci" {
  region = data.terraform_remote_state.oci.outputs.region
}

locals {
  tags = {
    proyecto    = var.project
    entorno     = "lab"
    propietario = var.owner
    expiracion  = var.expiry
  }
}

data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "10-aws-base/terraform.tfstate"
    region = var.state_region
  }
}

data "terraform_remote_state" "oci" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "20-oci-base/terraform.tfstate"
    region = var.state_region
  }
}

locals {
  paths = {
    a = { inside1 = "169.254.100.0/30", inside2 = "169.254.100.4/30" }
    b = { inside1 = "169.254.101.0/30", inside2 = "169.254.101.4/30" }
  }
  compartment_id = data.terraform_remote_state.oci.outputs.compartment_id
}

resource "random_password" "psk" {
  for_each = toset(["a1", "a2", "b1", "b2"])
  length   = 32
  special  = false
}

# ---- OCI: CPE + conexion IPsec por camino ----
resource "oci_core_cpe" "this" {
  for_each       = local.paths
  compartment_id = local.compartment_id
  display_name   = "${var.project}-cpe-aws-${each.key}"
  ip_address     = var.cpe_placeholder_ip # provisional; la identidad real se fija con cpe_local_identifier
}

resource "oci_core_ipsec" "this" {
  for_each                  = local.paths
  compartment_id            = local.compartment_id
  display_name              = "${var.project}-vpn-${each.key}"
  cpe_id                    = oci_core_cpe.this[each.key].id
  drg_id                    = data.terraform_remote_state.oci.outputs.drg_id
  static_routes             = [data.terraform_remote_state.aws.outputs.vpc_cidr]
  cpe_local_identifier      = lookup(var.aws_tunnel_ips, each.key, null)
  cpe_local_identifier_type = lookup(var.aws_tunnel_ips, each.key, null) == null ? null : "IP_ADDRESS"
}

data "oci_core_ipsec_connection_tunnels" "this" {
  for_each = local.paths
  ipsec_id = oci_core_ipsec.this[each.key].id
}

# ---- AWS: Customer Gateway apuntando al tunel OCI + conexion VPN por camino ----
resource "aws_customer_gateway" "this" {
  for_each   = local.paths
  bgp_asn    = var.oci_bgp_asn
  ip_address = data.oci_core_ipsec_connection_tunnels.this[each.key].ip_sec_connection_tunnels[0].vpn_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.project}-cgw-oci-${each.key}" }
}

resource "aws_vpn_connection" "this" {
  for_each              = local.paths
  vpn_gateway_id        = data.terraform_remote_state.aws.outputs.vgw_id
  customer_gateway_id   = aws_customer_gateway.this[each.key].id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_inside_cidr   = each.value.inside1
  tunnel2_inside_cidr   = each.value.inside2
  tunnel1_preshared_key = random_password.psk["${each.key}1"].result
  tunnel2_preshared_key = random_password.psk["${each.key}2"].result
  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]
  tags                  = { Name = "${var.project}-vpn-oci-${each.key}" }
}

# ---- OCI: configuracion del tunel emparejado (BGP + clave) ----
resource "oci_core_ipsec_connection_tunnel_management" "this" {
  for_each            = local.paths
  ipsec_id            = oci_core_ipsec.this[each.key].id
  tunnel_id           = data.oci_core_ipsec_connection_tunnels.this[each.key].ip_sec_connection_tunnels[0].id
  display_name        = "${var.project}-tunel-${each.key}"
  routing             = "BGP"
  ike_version         = "V2"
  shared_secret       = random_password.psk["${each.key}1"].result
  oracle_can_initiate = "RESPONDER_ONLY" # AWS inicia (startup_action del tunel AWS)

  bgp_session_info {
    customer_bgp_asn      = tostring(var.aws_bgp_asn)
    oracle_interface_ip   = "${aws_vpn_connection.this[each.key].tunnel1_cgw_inside_address}/30"
    customer_interface_ip = "${aws_vpn_connection.this[each.key].tunnel1_vgw_inside_address}/30"
  }
}

# ---- Regla de RDS para el suscriptor OCI (IP /32 privada por VPN) ----
resource "aws_vpc_security_group_ingress_rule" "rds_from_subscriber" {
  security_group_id = data.terraform_remote_state.aws.outputs.rds_sg_id
  cidr_ipv4         = "${data.terraform_remote_state.oci.outputs.postgres_private_ip}/32"
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  description       = "Suscriptor logico OCI por VPN"
}

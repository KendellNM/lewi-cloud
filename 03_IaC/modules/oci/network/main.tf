locals {
  tags = merge(var.tags, { modulo = "oci-network" })
}

data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name}-vcn"
  dns_label      = "abelito"
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-igw"
  freeform_tags  = local.tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nat"
  freeform_tags  = local.tags
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-sgw"
  services {
    service_id = data.oci_core_services.all.services[0].id
  }
  freeform_tags = local.tags
}

resource "oci_core_drg" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-drg"
  freeform_tags  = local.tags
}

resource "oci_core_drg_attachment" "vcn" {
  drg_id       = oci_core_drg.this.id
  display_name = "${var.name}-drg-vcn"
  network_details {
    id   = oci_core_vcn.this.id
    type = "VCN"
  }
}

# --- Rutas ---
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-rt-publica"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
  freeform_tags = local.tags
}

resource "oci_core_route_table" "app" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-rt-app"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }
  route_rules {
    destination       = data.oci_core_services.all.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }
  route_rules {
    destination       = var.peer_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.this.id
  }
  freeform_tags = local.tags
}

resource "oci_core_route_table" "data" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-rt-datos"
  route_rules {
    destination       = var.peer_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.this.id
  }
  route_rules {
    destination       = data.oci_core_services.all.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }
  # NAT solo si se habilita para parches/instalacion; por defecto cerrado.
  dynamic "route_rules" {
    for_each = var.data_internet_egress ? [1] : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.this.id
    }
  }
  freeform_tags = local.tags
}

# Lista de seguridad vacia (sin ingreso): sustituye a la predeterminada, que abre SSH 22 a todo Internet.
# El control real se hace con NSG.
resource "oci_core_security_list" "deny_ingress" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-sl-sin-ingreso"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  freeform_tags = local.tags
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.public_cidr
  display_name               = "${var.name}-sn-publica"
  dns_label                  = "pub"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.deny_ingress.id]
  freeform_tags              = local.tags
}

resource "oci_core_subnet" "app" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.app_cidr
  display_name               = "${var.name}-sn-app-relay"
  dns_label                  = "app"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.app.id
  security_list_ids          = [oci_core_security_list.deny_ingress.id]
  freeform_tags              = local.tags
}

resource "oci_core_subnet" "data" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.data_cidr
  display_name               = "${var.name}-sn-datos"
  dns_label                  = "data"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.data.id
  security_list_ids          = [oci_core_security_list.deny_ingress.id]
  freeform_tags              = local.tags
}

# --- NSG por funcion ---
resource "oci_core_network_security_group" "lb" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nsg-lb-publico"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group" "relay_lb" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nsg-lb-relay"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group" "app" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nsg-app"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group" "db" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nsg-postgres"
  freeform_tags  = local.tags
}

# LB publico: 443 solo desde Cloudflare
resource "oci_core_network_security_group_security_rule" "lb_in" {
  for_each                  = toset(var.cloudflare_cidrs)
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  description               = "HTTPS desde Cloudflare"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_out" {
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.app.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Hacia la aplicacion"
  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

# LB privado del relay: 443 solo desde la VPC de AWS (por VPN)
resource "oci_core_network_security_group_security_rule" "relay_in" {
  network_security_group_id = oci_core_network_security_group.relay_lb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.peer_cidr
  source_type               = "CIDR_BLOCK"
  description               = "Job de copias desde AWS por VPN"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "relay_out" {
  network_security_group_id = oci_core_network_security_group.relay_lb.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.app.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Hacia el relay"
  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

# Aplicacion/relay
resource "oci_core_network_security_group_security_rule" "app_from_lb" {
  for_each = {
    publico = oci_core_network_security_group.lb.id
    relay   = oci_core_network_security_group.relay_lb.id
  }
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Desde balanceador ${each.key}"
  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_out" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "NAT, Service Gateway, PostgreSQL y destinos autorizados"
}

# PostgreSQL de OCI: solo la aplicacion
resource "oci_core_network_security_group_security_rule" "db_from_app" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.app.id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "PostgreSQL desde la aplicacion"
  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

# Egreso del suscriptor: RDS por VPN (5432) y servicios Oracle/NAT cuando este habilitado
resource "oci_core_network_security_group_security_rule" "db_out" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "RDS por VPN y servicios"
}

# --- Acceso administrativo privado (sin SSH publico) ---
resource "oci_bastion_bastion" "this" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_id
  target_subnet_id             = oci_core_subnet.app.id
  name                         = "${replace(var.name, "-", "")}bastion"
  client_cidr_block_allow_list = var.admin_cidrs
  max_session_ttl_in_seconds   = 3600
  freeform_tags                = local.tags
}

# Replicacion fisica entre primario y standby (mismo NSG)
resource "oci_core_network_security_group_security_rule" "db_from_db" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.db.id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Replicacion primario-standby"
  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

locals {
  tags = merge(var.tags, { Modulo = "aws-security" })
}

# Rangos publicados de Cloudflare como prefix list (evita el limite de reglas por SG).
resource "aws_ec2_managed_prefix_list" "cloudflare" {
  name           = "${var.name}-cloudflare"
  address_family = "IPv4"
  max_entries    = 30

  dynamic "entry" {
    for_each = toset(var.cloudflare_cidrs)
    content {
      cidr        = entry.value
      description = "Cloudflare"
    }
  }
  tags = local.tags
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB publico: 443 solo desde Cloudflare"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Aplicacion privada: solo desde el ALB"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-app" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "PostgreSQL: aplicacion y suscriptor OCI (regla en el stack de interconexion)"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-rds" })
}

# ALB
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = aws_ec2_managed_prefix_list.cloudflare.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS desde Cloudflare"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  description                  = "Trafico y health check hacia la aplicacion"
}

# Aplicacion
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  description                  = "Solo desde el ALB"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS: endpoints, NAT, repositorios"
}

resource "aws_vpc_security_group_egress_rule" "app_to_rds" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL"
}

# RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Aplicacion"
}

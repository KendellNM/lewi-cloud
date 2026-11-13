data "aws_region" "current" {}

locals {
  nat_count = var.nat_per_az ? length(var.azs) : 1
  tags      = merge(var.tags, { Modulo = "aws-network" })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(local.tags, { Name = "${var.name}-pub-${count.index}", Capa = "publica" })
}

resource "aws_subnet" "app" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(local.tags, { Name = "${var.name}-app-${count.index}", Capa = "aplicacion" })
}

resource "aws_subnet" "data" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(local.tags, { Name = "${var.name}-data-${count.index}", Capa = "datos" })
}

# --- Salida a Internet de la capa de aplicacion ---
resource "aws_eip" "nat" {
  count      = local.nat_count
  domain     = "vpc"
  tags       = merge(local.tags, { Name = "${var.name}-nat-eip-${count.index}" })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.tags, { Name = "${var.name}-nat-${count.index}" })
}

# --- Rutas ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "app" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-rt-app-${count.index}" })
}

resource "aws_route" "app_nat" {
  count                  = length(var.azs)
  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.nat_per_az ? count.index : 0].id
}

# La capa de datos no tiene ruta a Internet: solo local + rutas aprendidas por VPN (BGP).
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-rt-data" })
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# --- VGW para la VPN hacia OCI ---
resource "aws_vpn_gateway" "this" {
  vpc_id          = aws_vpc.this.id
  amazon_side_asn = var.amazon_side_asn
  tags            = merge(local.tags, { Name = "${var.name}-vgw" })
}

resource "aws_vpn_gateway_route_propagation" "app" {
  count          = length(var.azs)
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_vpn_gateway_route_propagation" "data" {
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = aws_route_table.data.id
}

# --- Endpoints: S3 (gateway) y SSM/CloudWatch (interface) para no depender del NAT ---
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.app[*].id, [aws_route_table.data.id])
  tags              = merge(local.tags, { Name = "${var.name}-vpce-s3" })
}

resource "aws_security_group" "vpce" {
  count       = var.enable_interface_endpoints ? 1 : 0
  name        = "${var.name}-vpce"
  description = "HTTPS desde la VPC hacia los endpoints de interfaz"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.name}-vpce" })
}

resource "aws_vpc_security_group_ingress_rule" "vpce_https" {
  count             = var.enable_interface_endpoints ? 1 : 0
  security_group_id = aws_security_group.vpce[0].id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS desde la VPC"
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = var.enable_interface_endpoints ? toset(["ssm", "ssmmessages", "ec2messages", "logs", "monitoring"]) : toset([])
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${var.name}-vpce-${each.key}" })
}

# --- VPC Flow Logs (auditoria de red) ---
resource "aws_cloudwatch_log_group" "flow" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/${var.name}/vpc-flow"
  retention_in_days = 14
  tags              = local.tags
}

data "aws_iam_policy_document" "flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow" {
  count = var.enable_flow_logs ? 1 : 0
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.flow[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow" {
  count              = var.enable_flow_logs ? 1 : 0
  name               = "${var.name}-vpc-flow"
  assume_role_policy = data.aws_iam_policy_document.flow_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "flow" {
  count  = var.enable_flow_logs ? 1 : 0
  name   = "escribir-flow-logs"
  role   = aws_iam_role.flow[0].id
  policy = data.aws_iam_policy_document.flow[0].json
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow[0].arn
  iam_role_arn         = aws_iam_role.flow[0].arn
  tags                 = local.tags
}

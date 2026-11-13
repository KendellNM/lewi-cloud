data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  tags        = merge(var.tags, { Modulo = "aws-observability" })
  alb_dims    = { LoadBalancer = var.alb_arn_suffix }
  tg_dims     = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
  db_dims     = { DBInstanceIdentifier = var.db_identifier }
  alarm_label = "${var.name}-aws"
}

resource "aws_sns_topic" "alerts" {
  name = "${local.alarm_label}-alertas"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# --- Aplicacion y balanceador ---
resource "aws_cloudwatch_metric_alarm" "alb_5xx_pct" {
  alarm_name          = "${local.alarm_label}-5xx-mayor-1pct"
  alarm_description   = "Errores 5xx > 1 % durante 5 min (seccion 17)."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "pct"
    expression  = "IF(req>0, 100*err/req, 0)"
    label       = "% 5xx"
    return_data = true
  }
  metric_query {
    id = "err"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions  = local.alb_dims
    }
  }
  metric_query {
    id = "req"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 60
      stat        = "Sum"
      dimensions  = local.alb_dims
    }
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  alarm_name          = "${local.alarm_label}-sin-destinos-saludables"
  alarm_description   = "Ningun destino saludable en el ALB."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  dimensions          = local.tg_dims
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "latency_p95" {
  alarm_name          = "${local.alarm_label}-p95-mayor-2s"
  alarm_description   = "Percentil 95 de respuesta > 2 s (RNF02)."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.alb_dims
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 5
  comparison_operator = "GreaterThanThreshold"
  threshold           = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${local.alarm_label}-cpu-mayor-70"
  alarm_description   = "CPU promedio del ASG > 70 % durante 5 min."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { AutoScalingGroupName = var.asg_name }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Datos ---
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.alarm_label}-rds-espacio-bajo"
  alarm_description   = "Espacio libre RDS < 20 %."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = local.db_dims
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "LessThanThreshold"
  threshold           = var.allocated_storage_gb * 1073741824 * 0.2
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.alarm_label}-rds-conexiones-80pct"
  alarm_description   = "Conexiones > 80 % del maximo configurado."
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  dimensions          = local.db_dims
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_max_connections * 0.8
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "slot_lag" {
  alarm_name          = "${local.alarm_label}-wal-retenido-por-slot"
  alarm_description   = "Slot de replicacion logica retrasado: el suscriptor OCI no consume WAL."
  namespace           = "AWS/RDS"
  metric_name         = "OldestReplicationSlotLag"
  dimensions          = local.db_dims
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.slot_lag_bytes
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- VPN: una alarma por tunel emparejado ---
resource "aws_cloudwatch_metric_alarm" "vpn_tunnel" {
  for_each            = toset(var.vpn_tunnel_ips)
  alarm_name          = "${local.alarm_label}-vpn-${each.value}"
  alarm_description   = "Camino VPN caido (IPsec/BGP)."
  namespace           = "AWS/VPN"
  metric_name         = "TunnelState"
  dimensions          = { TunnelIpAddress = each.value }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Copias: metrica personalizada publicada por el job de respaldo ---
# Umbral 90 min porque el respaldo es horario (evita alarma permanente en el limite).
resource "aws_cloudwatch_metric_alarm" "backup_age" {
  alarm_name          = "${local.alarm_label}-copia-verificada-antigua"
  alarm_description   = "Sin copia portable verificada en 90 min. El job publica Abelito/Backup MinutosDesdeUltimaCopiaVerificada."
  namespace           = "Abelito/Backup"
  metric_name         = "MinutosDesdeUltimaCopiaVerificada"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Dashboard ---
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-aws"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB: solicitudes y 5xx"
          region = data.aws_region.current.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Latencia p95 y destinos saludables"
          region = data.aws_region.current.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95" }],
            [".", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Minimum", yAxis = "right" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "ASG: CPU promedio"
          region  = data.aws_region.current.region
          stat    = "Average"
          period  = 60
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "RDS: conexiones, espacio y slot logico"
          region = data.aws_region.current.region
          period = 60
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier, { stat = "Maximum" }],
            [".", "FreeStorageSpace", ".", ".", { stat = "Minimum", yAxis = "right" }],
            [".", "OldestReplicationSlotLag", ".", ".", { stat = "Maximum", yAxis = "right" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title   = "VPN: estado de los tuneles emparejados"
          region  = data.aws_region.current.region
          stat    = "Maximum"
          period  = 60
          metrics = [for ip in var.vpn_tunnel_ips : ["AWS/VPN", "TunnelState", "TunnelIpAddress", ip]]
        }
      },
      {
        type = "metric", x = 12, y = 12, width = 12, height = 6
        properties = {
          title   = "Antiguedad de la ultima copia verificada (min)"
          region  = data.aws_region.current.region
          stat    = "Maximum"
          period  = 300
          metrics = [["Abelito/Backup", "MinutosDesdeUltimaCopiaVerificada"]]
        }
      },
    ]
  })
}

# --- CloudTrail (auditoria de cambios administrativos) ---
resource "aws_s3_bucket" "trail" {
  count         = var.enable_cloudtrail ? 1 : 0
  bucket        = "${var.name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "trail" {
  count                   = var.enable_cloudtrail ? 1 : 0
  bucket                  = aws_s3_bucket.trail[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "trail" {
  count = var.enable_cloudtrail ? 1 : 0
  statement {
    sid       = "AclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail[0].arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
  statement {
    sid       = "Escritura"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.trail[0].id
  policy = data.aws_iam_policy_document.trail[0].json
}

resource "aws_cloudtrail" "this" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = "${var.name}-trail"
  s3_bucket_name                = aws_s3_bucket.trail[0].id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  tags                          = local.tags
  depends_on                    = [aws_s3_bucket_policy.trail]
}

# --- Deteccion de amenazas ---
resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
  tags   = local.tags
}

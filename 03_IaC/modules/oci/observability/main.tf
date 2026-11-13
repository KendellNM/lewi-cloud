locals {
  tags = merge(var.tags, { modulo = "oci-observability" })
}

resource "oci_ons_notification_topic" "alerts" {
  compartment_id = var.compartment_id
  name           = "${var.name}-alertas"
  freeform_tags  = local.tags
}

resource "oci_ons_subscription" "email" {
  count          = var.alarm_email == "" ? 0 : 1
  compartment_id = var.compartment_id
  topic_id       = oci_ons_notification_topic.alerts.id
  protocol       = "EMAIL"
  endpoint       = var.alarm_email
}

resource "oci_monitoring_alarm" "cpu" {
  compartment_id        = var.compartment_id
  metric_compartment_id = var.compartment_id
  display_name          = "${var.name}-cpu-mayor-70"
  namespace             = "oci_computeagent"
  query                 = "CpuUtilization[1m].mean() > 70"
  severity              = "WARNING"
  destinations          = [oci_ons_notification_topic.alerts.id]
  is_enabled            = true
  pending_duration      = "PT5M"
  body                  = "CPU promedio > 70 % durante 5 min en instancias del proyecto."
  freeform_tags         = local.tags
}

resource "oci_monitoring_alarm" "lb_unhealthy" {
  compartment_id        = var.compartment_id
  metric_compartment_id = var.compartment_id
  display_name          = "${var.name}-lb-backends-no-saludables"
  namespace             = "oci_lbaas"
  query                 = "UnHealthyBackendServers[1m].max() > 0"
  severity              = "CRITICAL"
  destinations          = [oci_ons_notification_topic.alerts.id]
  is_enabled            = true
  pending_duration      = "PT2M"
  body                  = "El balanceador reporta backends no saludables."
  freeform_tags         = local.tags
}

resource "oci_monitoring_alarm" "lb_5xx" {
  compartment_id        = var.compartment_id
  metric_compartment_id = var.compartment_id
  display_name          = "${var.name}-lb-5xx"
  namespace             = "oci_lbaas"
  query                 = "HttpResponses5xx[1m].sum() > 5"
  severity              = "WARNING"
  destinations          = [oci_ons_notification_topic.alerts.id]
  is_enabled            = true
  pending_duration      = "PT5M"
  body                  = "Respuestas 5xx sostenidas en el balanceador."
  freeform_tags         = local.tags
}

resource "oci_logging_log_group" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-logs"
  freeform_tags  = local.tags
}

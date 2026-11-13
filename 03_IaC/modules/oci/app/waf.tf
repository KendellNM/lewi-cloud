# WAF de OCI delante del LB web (paridad con AWS WAF). Politica minima: limite de tasa por cliente.
# PENDIENTE (agente 05): reglas de proteccion OWASP (protection_capabilities) y verificacion de la
# cabecera x-origin-verify; las claves/condiciones se toman de la documentacion de OCI WAF.
resource "oci_waf_web_app_firewall_policy" "web" {
  count          = var.enable_waf ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.name}-waf-policy"

  actions {
    name = "permitir"
    type = "ALLOW"
  }
  actions {
    name = "limite-429"
    type = "RETURN_HTTP_RESPONSE"
    code = 429
    body {
      type = "STATIC_TEXT"
      text = "Demasiadas solicitudes"
    }
  }

  request_access_control {
    default_action_name = "permitir"
  }

  request_rate_limiting {
    rules {
      name               = "limite-por-cliente"
      type               = "REQUEST_RATE_LIMITING"
      action_name        = "limite-429"
      condition_language = "JMESPATH"
      condition          = "`true`"
      configurations {
        period_in_seconds          = 60
        requests_limit             = var.rate_limit_per_min
        action_duration_in_seconds = 60
      }
    }
  }
  freeform_tags = local.tags
}

resource "oci_waf_web_app_firewall" "web" {
  count                      = var.enable_waf ? 1 : 0
  compartment_id             = var.compartment_id
  display_name               = "${var.name}-waf"
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = oci_load_balancer_load_balancer.web.id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.web[0].id
  freeform_tags              = local.tags
}

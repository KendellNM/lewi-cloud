locals {
  tags = merge(var.tags, { modulo = "oci-app" })
}

data "oci_core_images" "ol9" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- Balanceador publico (web) ---
resource "oci_load_balancer_load_balancer" "web" {
  compartment_id             = var.compartment_id
  display_name               = "${var.name}-lb-web"
  shape                      = "flexible"
  subnet_ids                 = [var.public_subnet_id]
  network_security_group_ids = [var.nsg_lb_id]
  is_private                 = false
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
  freeform_tags = local.tags
}

resource "oci_load_balancer_backend_set" "web" {
  load_balancer_id = oci_load_balancer_load_balancer.web.id
  name             = "web"
  policy           = "ROUND_ROBIN"
  health_checker {
    protocol          = "HTTP"
    port              = var.app_port
    url_path          = "/healthz"
    return_code       = 200
    interval_ms       = 30000
    timeout_in_millis = 5000
    retries           = 2
  }
  ssl_configuration {
    verify_peer_certificate = false # el origen usa certificado autofirmado interno
  }
}

resource "oci_load_balancer_certificate" "origin" {
  load_balancer_id   = oci_load_balancer_load_balancer.web.id
  certificate_name   = "origen-cloudflare"
  public_certificate = var.origin_cert_pem
  private_key        = var.origin_key_pem
  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.web.id
  name                     = "https"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  port                     = 443
  protocol                 = "HTTP"
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.origin.certificate_name
    protocols               = ["TLSv1.2", "TLSv1.3"]
    verify_peer_certificate = false
  }
}

# --- Balanceador privado del relay (TCP; TLS termina en el servicio relay) ---
# El Instance Pool solo se asocia a Load Balancer (no a Network Load Balancer), por eso el relay usa un LB privado L4.
resource "oci_load_balancer_load_balancer" "relay" {
  compartment_id             = var.compartment_id
  display_name               = "${var.name}-lb-relay"
  shape                      = "flexible"
  subnet_ids                 = [var.app_subnet_id]
  network_security_group_ids = [var.nsg_relay_lb_id]
  is_private                 = true
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
  freeform_tags = local.tags
}

resource "oci_load_balancer_backend_set" "relay" {
  load_balancer_id = oci_load_balancer_load_balancer.relay.id
  name             = "relay"
  policy           = "ROUND_ROBIN"
  health_checker {
    protocol          = "TCP"
    port              = var.app_port
    interval_ms       = 30000
    timeout_in_millis = 5000
    retries           = 2
  }
}

resource "oci_load_balancer_listener" "relay" {
  load_balancer_id         = oci_load_balancer_load_balancer.relay.id
  name                     = "relay-tcp-443"
  default_backend_set_name = oci_load_balancer_backend_set.relay.name
  port                     = 443
  protocol                 = "TCP"
}

# --- Pool de aplicacion y relay en dos fault domains ---
resource "oci_core_instance_configuration" "app" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-app-config"
  instance_details {
    instance_type = "compute"
    launch_details {
      compartment_id = var.compartment_id
      shape          = var.shape
      shape_config {
        ocpus         = var.ocpus
        memory_in_gbs = var.memory_gb
      }
      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.ol9.images[0].id
        boot_volume_size_in_gbs = 50
      }
      create_vnic_details {
        subnet_id        = var.app_subnet_id
        assign_public_ip = false
        nsg_ids          = [var.nsg_app_id]
      }
      metadata = {
        user_data = base64encode(templatefile("${path.module}/../../shared/nginx-origin.sh.tftpl", { provider = "oci" }))
      }
      agent_config {
        plugins_config {
          name          = "Bastion"
          desired_state = "ENABLED"
        }
        plugins_config {
          name          = "Compute Instance Monitoring"
          desired_state = "ENABLED"
        }
      }
      is_pv_encryption_in_transit_enabled = true
    }
  }
  freeform_tags = local.tags
}

resource "oci_core_instance_pool" "app" {
  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.app.id
  display_name              = "${var.name}-pool"
  size                      = var.pool_min

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = var.app_subnet_id
    fault_domains       = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2"]
  }
  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.web.id
    backend_set_name = oci_load_balancer_backend_set.web.name
    port             = var.app_port
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.relay.id
    backend_set_name = oci_load_balancer_backend_set.relay.name
    port             = var.app_port
    vnic_selection   = "PrimaryVnic"
  }
  freeform_tags = local.tags

  lifecycle {
    ignore_changes = [size] # lo gobierna el autoscaling
  }
}

resource "oci_autoscaling_auto_scaling_configuration" "app" {
  compartment_id       = var.compartment_id
  display_name         = "${var.name}-autoscaling"
  cool_down_in_seconds = 300
  is_enabled           = true

  auto_scaling_resources {
    id   = oci_core_instance_pool.app.id
    type = "instancePool"
  }
  policies {
    display_name = "cpu-umbral"
    policy_type  = "threshold"
    capacity {
      initial = var.pool_min
      min     = var.pool_min
      max     = var.pool_max
    }
    rules {
      display_name = "escalar-hacia-arriba"
      action {
        type  = "CHANGE_COUNT_BY"
        value = 1
      }
      metric {
        metric_type = "CPU_UTILIZATION"
        threshold {
          operator = "GT"
          value    = 65
        }
      }
    }
    rules {
      display_name = "escalar-hacia-abajo"
      action {
        type  = "CHANGE_COUNT_BY"
        value = -1
      }
      metric {
        metric_type = "CPU_UTILIZATION"
        threshold {
          operator = "LT"
          value    = 30
        }
      }
    }
  }
  freeform_tags = local.tags
}

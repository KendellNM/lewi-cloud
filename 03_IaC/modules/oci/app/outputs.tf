output "web_lb_ip" {
  value = oci_load_balancer_load_balancer.web.ip_address_details[0].ip_address
}

output "web_lb_id" {
  value = oci_load_balancer_load_balancer.web.id
}

output "relay_lb_ip" {
  value = oci_load_balancer_load_balancer.relay.ip_address_details[0].ip_address
}

output "pool_id" {
  value = oci_core_instance_pool.app.id
}

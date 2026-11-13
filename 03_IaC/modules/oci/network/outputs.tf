output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "drg_id" {
  value = oci_core_drg.this.id
}

output "public_subnet_id" {
  value = oci_core_subnet.public.id
}

output "app_subnet_id" {
  value = oci_core_subnet.app.id
}

output "data_subnet_id" {
  value = oci_core_subnet.data.id
}

output "nsg_lb_id" {
  value = oci_core_network_security_group.lb.id
}

output "nsg_relay_lb_id" {
  value = oci_core_network_security_group.relay_lb.id
}

output "nsg_app_id" {
  value = oci_core_network_security_group.app.id
}

output "nsg_db_id" {
  value = oci_core_network_security_group.db.id
}

output "bastion_id" {
  value = oci_bastion_bastion.this.id
}

output "postgres_private_ip" {
  description = "IP del nodo primario (suscriptor logico de RDS)."
  value       = oci_core_instance.postgres["primary"].private_ip
}

output "postgres_standby_private_ip" {
  description = "IP del nodo standby (replicacion fisica, a configurar por el agente 04)."
  value       = try(oci_core_instance.postgres["standby"].private_ip, null)
}

output "bucket_name" {
  value = oci_objectstorage_bucket.backups.name
}

output "availability_domain" {
  value = local.availability_domain
}

output "vault_id" {
  value = oci_kms_vault.this.id
}

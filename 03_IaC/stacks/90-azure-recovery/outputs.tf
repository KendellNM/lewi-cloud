output "app_public_ip" { value = try(module.recovery[0].app_public_ip, null) }
output "db_private_ip" { value = try(module.recovery[0].db_private_ip, null) }

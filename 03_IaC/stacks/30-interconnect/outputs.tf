output "aws_tunnel_ips" {
  description = "IP publicas de los tuneles AWS emparejados con OCI."
  value       = { for k, c in aws_vpn_connection.this : k => c.tunnel1_address }
}

output "paired_tunnel_ips" {
  description = "Lista para las alarmas de CloudWatch (stack 70)."
  value       = [for c in aws_vpn_connection.this : c.tunnel1_address]
}

output "oci_tunnel_ips" {
  value = { for k, t in data.oci_core_ipsec_connection_tunnels.this : k => t.ip_sec_connection_tunnels[0].vpn_ip }
}

output "vm_ips" {
  value = [for server in hcloud_server.monitoring : server.ipv4_address]
}

output "floating_ips" {
  description = "Floating IP addresses"
  value = [for ip in data.hcloud_floating_ip.existing : ip.ip_address]
}


# Data source for existing floating IPs (if they exist)
data "hcloud_floating_ip" "existing" {
  count      = var.use_existing_floating_ip ? length(var.locations) : 0
  ip_address = var.existing_floating_ips[count.index]
}


# Primary network for consistent private IPs
resource "hcloud_network" "monitoring_network" {
  name     = "monitoring-network"
  ip_range = var.network_ip_range
  
  labels = {
    environment = var.environment
  }
}

resource "hcloud_network_subnet" "monitoring_subnet" {
  count        = length(var.locations)
  network_id   = hcloud_network.monitoring_network.id
  type         = "cloud"
  network_zone = var.network_zones[count.index]
  ip_range     = var.subnet_ip_ranges[count.index]
}

# SSH key data source
data "hcloud_ssh_key" "existing" {
  name = var.ssh_key_name
}

# Cloud-init template data source
data "template_file" "cloud_init" {
  count    = length(var.locations)
  template = file("${path.module}/../cloud-init/app.yaml")

  vars = {
    # Use existing or new floating IP
    floating_ip = data.hcloud_floating_ip.existing[count.index].ip_address
    private_ip              = var.server_private_ips[count.index]
    GIT_HUB_SSH_PRIVATE_KEY = indent(6, var.GIT_HUB_SSH_PRIVATE_KEY)
    smtp_host              = var.smtp_host
    smtp_user_email        = var.smtp_user_email
    smtp_password          = var.smtp_password
    smtp_form_address_email = var.smtp_form_address_email
  }
}

# Monitoring server resource with consistent IPs
resource "hcloud_server" "monitoring" {
  count        = length(var.locations)
  name         = "monitoring-${var.locations[count.index]}"
  server_type  = var.server_type
  image        = "ubuntu-22.04"
  location     = var.locations[count.index]
  ssh_keys     = [data.hcloud_ssh_key.existing.id]
  user_data    = data.template_file.cloud_init[count.index].rendered
  firewall_ids = [hcloud_firewall.monitoring.id]

  # Attach to network for consistent private IP
  network {
    network_id = hcloud_network.monitoring_network.id
    ip         = var.server_private_ips[count.index]  # Fixed private IP
  }

  labels = {
    environment = var.environment
    type        = "monitoring"
    location    = var.locations[count.index]
  }

  # Prevent server replacement for minor changes
  lifecycle {
    ignore_changes = [
      ssh_keys,  # SSH keys changes won't recreate server
      user_data, # User data changes won't recreate server (use with caution)
    ]
  }

  depends_on = [
    hcloud_network_subnet.monitoring_subnet
  ]
}

# Firewall resource for monitoring
resource "hcloud_firewall" "monitoring" {
  name = "allow-http-ssh-monitoring-vm"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9090"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3100"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Floating IP assignment resource
resource "hcloud_floating_ip_assignment" "assign" {
  count          = length(var.locations)
  # Use existing or new floating IP ID
  floating_ip_id = data.hcloud_floating_ip.existing[count.index].id
  server_id      = hcloud_server.monitoring[count.index].id
}

# Hetzner DNS zone data source
data "hetznerdns_zone" "main" {
  name = "falktron.com"
}

# DNS record for Grafana
resource "hetznerdns_record" "grafana-falktron" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "grafana"
  type    = "A"
  # Use existing or new floating IP
  value = data.hcloud_floating_ip.existing[0].ip_address
  ttl     = 300
}

# DNS record for Prometheus
resource "hetznerdns_record" "prometheus-falktron" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "prometheus"
  type    = "A"
  # Use existing or new floating IP
  value = data.hcloud_floating_ip.existing[0].ip_address
  ttl     = 300
}

# DNS record for Loki
resource "hetznerdns_record" "loki-falktron" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "loki"
  type    = "A"
  # Use existing or new floating IP
  value = data.hcloud_floating_ip.existing[0].ip_address
  ttl     = 300
}




 
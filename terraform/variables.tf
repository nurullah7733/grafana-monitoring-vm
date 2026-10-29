variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key_name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "domain" {
  type = string
  default = "example.com"
}

variable "locations" {
  type = list(string)
  default = ["fsn1", "hel1", "nbg1", "sgp1"]
}

 

variable "hetznerdns_token" {
  type      = string
  sensitive = true
}

variable "smtp_host" {
  type      = string
  sensitive = true
}
variable "smtp_user_email" {
  type      = string
  sensitive = true
}
 
 
# variable "monitoring_targets" {
#  description = "List of monitoring targets with names and IPs"
#  type = list(object({
#    name = string
#    ip   = string
#  }))
# }
# motitoring_targets variable not working its need to manually in cloud-init/app.yml then prometheus.yml

 

 

 

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

 

variable "smtp_password" {
  type = string
}

variable "smtp_form_address_email" {
  type = string
}

variable "GIT_HUB_SSH_PRIVATE_KEY" {
  type = string
}

# New variables for IP persistence
variable "use_existing_floating_ip" {
  description = "Whether to use existing floating IPs"
  type        = bool
  default     = true  # Set to true to use existing IPs
}

variable "existing_floating_ips" {
  description = "List of existing floating IP addresses (in same order as locations)"
  type        = list(string)
  default     = []
}

variable "server_private_ips" {
  description = "List of fixed private IP addresses for servers (in same order as locations)"
  type        = list(string)
  default     = ["10.0.1.10", "10.0.2.10"]  # Adjust as needed
}

variable "network_ip_range" {
  description = "IP range for the main network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ip_ranges" {
  description = "IP ranges for subnets (in same order as locations)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]  # Adjust as needed
}

variable "network_zones" {
  description = "Network zones for subnets (in same order as locations)"
  type        = list(string)
  default     = ["eu-central", "us-east"]  # Adjust based on your locations
}



 
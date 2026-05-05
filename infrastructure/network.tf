# Network segmentation and firewall rules for log server
# UFW-based allowlist — only permitted sources can reach services

variable "log_server_ip" {
  description = "Log server fixed IP for reference"
  type        = string
  default     = "192.168.1.12"
}

variable "allowed_sources" {
  description = "CIDR ranges allowed to access log server services"
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

variable "enable_firewall" {
  description = "Enable UFW firewall"
  type        = bool
  default     = true
}

locals {
  firewall_script = <<-EOT
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y ufw
    
    ufw --force disable
    ufw default deny incoming
    ufw default allow outgoing
    
    # SSH — rate-limited to prevent brute force
    ufw limit 22/tcp comment 'SSH rate-limited'
    
    # Loki HTTP — Vector agents only
    ufw allow from 192.168.1.0/24 to any port 3100 proto tcp comment 'Loki HTTP'
    
    # Grafana — management network only
    ufw allow from 192.168.1.0/24 to any port 3001 proto tcp comment 'Grafana'
    
    # Prometheus — internal only
    ufw allow from 192.168.1.0/24 to any port 9090 proto tcp comment 'Prometheus'
    
    ufw --force enable
    ufw status numbered
    
    echo "[+] Firewall configured"
  EOT
}

resource "null_resource" "network_hardening" {
  count = var.enable_firewall ? 1 : 0

  triggers = {
    allowed_sources = join(",", var.allowed_sources)
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = var.proxmox_host
      private_key = file("~/.ssh/id_rsa")
    }

    inline = [
      "bash -c '${replace(local.firewall_script, "'", "'\\''")}'",
    ]
  }
}

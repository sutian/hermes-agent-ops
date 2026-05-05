output "log_server_url" {
  description = "Log server Loki HTTP endpoint"
  value       = "http://${var.log_server_ip}:3100"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${var.log_server_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${var.log_server_ip}:9090"
}

output "deployment_guide" {
  description = "Post-terraform deployment steps"
  value = <<-EOT
    1. terraform apply -target=null_resource.log_server_vm
    2. Note VM IP from Proxmox console (DHCP)
    3. terraform apply to configure firewall + hardening
    4. On log server: git clone && docker compose up -d
    5. On each hermes host: ./agent/install-agent.sh <LOG_SERVER_IP> <AGENT_ID> <PLATFORM>
  EOT
}

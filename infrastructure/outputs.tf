output "log_server_ip" {
  description = "Log server VM IP address"
  value       = proxmox_vm_qemu.log_server[0].default_ipv4
}

output "log_server_vmid" {
  description = "Log server VM ID"
  value       = proxmox_vm_qemu.log_server[0].vmid
}

output "log_server_name" {
  description = "Log server VM name"
  value       = proxmox_vm_qemu.log_server[0].name
}

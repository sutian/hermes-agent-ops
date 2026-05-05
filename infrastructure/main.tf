variable "proxmox_host" {
  description = "Proxmox host IP"
  type        = string
  default     = "192.168.1.1"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "vm_template" {
  description = "VM template ID to clone"
  type        = string
  default     = "9000"
}

variable "vm_storage" {
  description = "Storage for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "log_server_vm" {
  description = "Log server VM configuration"
  type = object({
    name       = string
    memory     = number
    cores      = number
    disk_size  = string
    ip         = string
    net_bridge = string
  })
  default = {
    name       = "hermes-log-server"
    memory     = 8192
    cores      = 4
    disk_size  = "100G"
    ip         = "dhcp"
    net_bridge = "vmbr0"
  }
}

variable "ssh_user" {
  description = "SSH user for post-provision"
  type        = string
  default     = "root"
}

locals {
  vm_name = var.log_server_vm.name
}

resource "null_resource" "log_server_vm" {
  triggers = {
    template  = var.vm_template
    memory    = var.log_server_vm.memory
    cores     = var.log_server_vm.cores
    disk_size = var.log_server_vm.disk_size
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[+] Creating VM '${local.vm_name}' on ${var.proxmox_host}"
      qm clone ${var.vm_template} 9001 \
        --name ${local.vm_name} \
        --description "Hermes Log Server - provisioned by terraform" \
        --pool hermes-ops \
        || echo "VM may already exist, trying to start..."
      
      qm resize ${local.vm_name} scsi0 ${var.log_server_vm.disk_size}
      qm set ${local.vm_name} \
        --memory ${var.log_server_vm.memory} \
        --cores ${var.log_server_vm.cores} \
        --cpu host \
        --onboot 1 \
        --ostype l26 || true
      qm set ${local.vm_name} \
        --net0 virtio,bridge=${var.log_server_vm.net_bridge} || true
      qm start ${local.vm_name}
      echo "[+] VM ${local.vm_name} started"
    EOT
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = var.proxmox_host
      private_key = file("~/.ssh/id_rsa")
    }

    inline = [
      "sleep 60",
      "apt-get update && apt-get install -y curl git docker.io docker-compose",
      "systemctl enable docker",
      "hostnamectl set-hostname ${local.vm_name}",
      "echo '[+] VM provisioned'",
    ]
  }
}

output "vm_id" {
  description = "Proxmox VM ID"
  value       = 9001
}

output "vm_name" {
  description = "VM name"
  value       = local.vm_name
}

output "vm_ip" {
  description = "VM IP address (set static after DHCP lease)"
  value       = var.log_server_vm.ip
}

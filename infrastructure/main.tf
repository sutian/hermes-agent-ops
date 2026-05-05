terraform {
  required_version = ">= 1.9.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }

  backend "local" {}
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "log_server" {
  count = 1

  name        = "log-server-${count.index + 1}"
  target_node = var.proxmox_node
  vmid        = var.start_vmid + count.index

  clone = var.vm_template
  full   = true

  os_type    = "cloud-init"
  disk {
    type       = "virtio"
    storage    = var.proxmox_storage
    size       = var.vm_disk_size
    iothread   = true
  }

  memory      = var.vm_memory
  cores       = var.vm_cores
  sockets     = 1
  cpu        = "host"

  network {
    bridge  = "vmbr0"
    model   = "virtio"
  }

  ipconfig0 = "ip=dhcp"

  sshkeys = var.ssh_keys

  provisioner "remote-exec" {
    inline = [
      "apt-get update && apt-get upgrade -y",
      "apt-get install -y ufw docker.io docker-compose",
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow 22/tcp",
      "ufw allow 3100/tcp",
      "ufw allow 3001/tcp",
      "ufw allow 9090/tcp",
      "ufw --force enable",
    ]
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = var.vm_root_password
    host     = self.default_ipv4
  }
}

# VM hardening configuration — CIS Benchmarks aligned
# Applied via cloud-init or remote-exec provisioner after VM creation

variable "enable_hardening" {
  description = "Enable VM hardening controls"
  type        = bool
  default     = true
}

locals {
  hardening_script = <<-EOT
    # === VM Hardening (CIS Benchmarks) ===

    # 1. Disable unused filesystems
    echo 'install usb-storage /bin/true' > /etc/modprobe.d/disable-usb-storage.conf

    # 2. Kernel sysctl hardening
    cat >> /etc/sysctl.d/99-hermes-ops.conf << 'SYSCTL'
    kernel.dmesg_restrict = 1
    kernel.kptr_restrict = 2
    kernel.yama.ptrace_scope = 1
    net.ipv4.conf.all.rp_filter = 1
    net.ipv4.conf.default.rp_filter = 1
    net.ipv6.conf.all.accept_ra = 0
    net.ipv6.conf.default.accept_ra = 0
    net.ipv4.icmp_ignore_bogus_error_responses = 1
    net.ipv4.conf.all.log_martians = 1
    net.ipv4.conf.default.log_martians = 1
    SYSCTL
    sysctl -p /etc/sysctl.d/99-hermes-ops.conf

    # 3. Install and configure auditd
    apt-get install -y auditd
    cat >> /etc/audit/rules.d/hermes-ops.rules << 'AUDIT'
    -w /etc/passwd -p wa -k identity
    -w /etc/shadow -p wa -k identity
    -w /var/log/hermes/ -p wa -k hermes-logs
    -w /etc/ssh/sshd_config -p wa -k sshd_config
    AUDIT
    systemctl enable auditd

    # 4. Set secure umask
    echo 'umask 027' > /etc/profile.d/umask.sh

    # 5. Configure fail2ban
    apt-get install -y fail2ban
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
    [sshd]
    enabled = true
    port = 22
    maxretry = 3
    bantime = 3600
    findtime = 600
    FAIL2BAN
    systemctl enable fail2ban

    echo "[+] Hardening complete"
  EOT
}

resource "null_resource" "hardening" {
  count = var.enable_hardening ? 1 : 0

  triggers = {
    always = timestamp()
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = var.proxmox_host
      private_key = file("~/.ssh/id_rsa")
    }

    inline = [
      "bash -c '${replace(local.hardening_script, "'", "'\\''")}'",
    ]
  }
}

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  sensitive   = true
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node to deploy VM"
  type        = string
  default     = "pve12"
}

variable "proxmox_storage" {
  description = "Proxmox storage pool"
  type        = string
  default     = "local-lvm"
}

variable "vm_template" {
  description = "VM template to clone"
  type        = string
  default     = "debian-12-cloudinit-template"
}

variable "vm_memory" {
  description = "VM memory in MB"
  type        = number
  default     = 8192
}

variable "vm_cores" {
  description = "VM CPU cores"
  type        = number
  default     = 4
}

variable "vm_disk_size" {
  description = "VM disk size in GB"
  type        = string
  default     = "100"
}

variable "start_vmid" {
  description = "Starting VM ID"
  type        = number
  default     = 9000
}

variable "ssh_keys" {
  description = "SSH public keys for cloud-init"
  type        = string
  default     = ""
}

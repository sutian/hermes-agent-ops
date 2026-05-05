variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "dev"], var.environment)
    error_message = "Environment must be one of: production, staging, dev"
  }
}

variable "log_retention_days" {
  description = "Loki log retention period in days"
  type        = number
  default     = 30
}

variable "loki_resource_limits" {
  description = "Loki container resource limits"
  type = object({
    cpu_limit    = string
    memory_limit = string
  })
  default = {
    cpu_limit    = "2.0"
    memory_limit = "4G"
  }
}

variable "prometheus_retention_days" {
  description = "Prometheus TSDB retention period"
  type        = number
  default     = 15
}

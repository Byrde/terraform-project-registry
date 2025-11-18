variable "project_id" {
  description = "GCP Project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "northamerica-northeast1"
}

variable "timezone" {
  description = "Timezone for n8n"
  type        = string
  default     = "America/Toronto"
}

variable "n8n_version" {
  description = "n8n Docker image version"
  type        = string
  default     = "latest"
}

variable "webhook_url" {
  description = "Webhook URL for n8n (set this to the Cloud Run URL after first apply)"
  type        = string
  default     = ""
}

variable "wif_project_id" {
  description = "Workload Identity Federation project ID (required if enabling WIF project APIs)"
  type        = string
  default     = null
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run container (e.g., '1', '2', '1000m')"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run container (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "512Mi"
}

variable "cloud_run_deletion_protection" {
  description = "Enable deletion protection for Cloud Run service"
  type        = bool
  default     = false
}

variable "cloud_run_timeout_seconds" {
  description = "Timeout in seconds for Cloud Run service startup. Should be longer than ib_gateway_health_check_timeout_seconds to allow time for health check and n8n startup"
  type        = number
  default     = 600
}

# Cloud SQL configuration
variable "db_disk_size" {
  description = "Disk size for Cloud SQL instance in GB"
  type        = number
  default     = 10
}

variable "db_disk_type" {
  description = "Disk type for Cloud SQL instance (PD_SSD or PD_STANDARD)"
  type        = string
  default     = "PD_SSD"
}

variable "db_availability_type" {
  description = "Availability type for Cloud SQL instance (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "db_backup_enabled" {
  description = "Enable automated backups for Cloud SQL"
  type        = bool
  default     = true
}

variable "db_backup_start_time" {
  description = "Start time for Cloud SQL backups (HH:MM format in UTC)"
  type        = string
  default     = "03:00"
}

variable "db_point_in_time_recovery" {
  description = "Enable point-in-time recovery for Cloud SQL"
  type        = bool
  default     = true
}

variable "db_maintenance_day" {
  description = "Day of week for Cloud SQL maintenance (1-7, where 1=Monday, 7=Sunday)"
  type        = number
  default     = 7
}

variable "db_maintenance_hour" {
  description = "Hour of day for Cloud SQL maintenance (0-23)"
  type        = number
  default     = 3
}

variable "db_update_track" {
  description = "Update track for Cloud SQL (stable or canary)"
  type        = string
  default     = "stable"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL instance"
  type        = bool
  default     = false
}

variable "db_version" {
  description = "PostgreSQL version for Cloud SQL instance"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "n8n_debug_logs" {
  description = "Enable debug logs for n8n (sets N8N_LOG_LEVEL=debug)"
  type        = bool
  default     = false
}

# IB Gateway Docker image configuration
variable "ib_gateway_version" {
  description = "IB Gateway Docker image version/tag"
  type        = string
  default     = "latest"
}

variable "ib_gateway_tws_userid" {
  description = "Interactive Brokers TWS user ID"
  type        = string
  sensitive   = true
}

variable "ib_gateway_tws_password" {
  description = "Interactive Brokers TWS password"
  type        = string
  sensitive   = true
}

variable "ib_gateway_read_only_api" {
  description = "Enable read-only API mode"
  type        = bool
  default     = false
}

variable "ib_gateway_trading_mode" {
  description = "Trading mode: 'paper' or 'live'"
  type        = string
  default     = "paper"
  validation {
    condition     = contains(["paper", "live"], var.ib_gateway_trading_mode)
    error_message = "Trading mode must be either 'paper' or 'live'."
  }
}

variable "ib_gateway_cpu" {
  description = "CPU allocation for IB Gateway container (e.g., '1', '2', '1000m')"
  type        = string
  default     = "1"
}

variable "ib_gateway_memory" {
  description = "Memory allocation for IB Gateway container (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "1Gi"
}

variable "ib_gateway_second_factor_device" {
  description = "Device identifier for 2FA (e.g., 'IB Key' or device ID from IB account settings)"
  type        = string
  default     = ""
}

variable "ib_gateway_relogin_after_2fa_timeout" {
  description = "Whether to attempt relogin after 2FA timeout (yes/no)"
  type        = string
  default     = "yes"
  validation {
    condition     = contains(["yes", "no"], var.ib_gateway_relogin_after_2fa_timeout)
    error_message = "Value must be either 'yes' or 'no'."
  }
}

variable "ib_gateway_2fa_timeout_seconds" {
  description = "Seconds to wait for 2FA authentication before timing out"
  type        = number
  default     = 300
}

variable "ib_gateway_health_check_timeout_seconds" {
  description = "Maximum time in seconds to wait for IB Gateway to become healthy before starting n8n"
  type        = number
  default     = 300
}

variable "ib_gateway_health_check_interval_seconds" {
  description = "Interval in seconds between IB Gateway health check attempts"
  type        = number
  default     = 5
}

variable "ib_gateway_debug_logs" {
  description = "Enable debug logs for IB Gateway (sets LOG_LEVEL=DEBUG)"
  type        = bool
  default     = false
}
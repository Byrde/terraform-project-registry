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

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "wif_project_id" {
  description = "Workload Identity Federation project ID (required if enabling WIF project APIs)"
  type        = string
  default     = null
}

# Cloud Run configuration
variable "cloud_run_min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
}

variable "cloud_run_max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 1
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

# IBKR Bridge sidecar configuration
variable "ibkr_bridge_enabled" {
  description = "Enable IBKR Bridge sidecar container"
  type        = bool
  default     = false
}

variable "ibkr_bridge_version" {
  description = "IBKR Bridge Docker image version"
  type        = string
  default     = "0.2.3"
}

variable "ibkr_username" {
  description = "Interactive Brokers username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ibkr_password" {
  description = "Interactive Brokers password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ibkr_totp_secret" {
  description = "TOTP secret for IBKR 2FA (base32 encoded, required for live trading)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ibkr_paper_trading" {
  description = "Enable paper trading mode (disables 2FA requirement)"
  type        = bool
  default     = true
}

variable "bridge_username" {
  description = "Basic auth username for IBKR Bridge API access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "bridge_password" {
  description = "Basic auth password for IBKR Bridge API access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ibkr_bridge_cpu" {
  description = "CPU allocation for IBKR Bridge container"
  type        = string
  default     = "1"
}

variable "ibkr_bridge_memory" {
  description = "Memory allocation for IBKR Bridge container"
  type        = string
  default     = "512Mi"
}

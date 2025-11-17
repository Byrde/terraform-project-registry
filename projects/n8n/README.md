# n8n Project

Deploys n8n workflow automation platform on GCP using Cloud Run and Cloud SQL PostgreSQL.

## Usage

### Basic Usage

```hcl
module "n8n" {
  source = "github.com/byrde/terraform-project-registry//projects/n8n?ref=v1.0.0"

  project_id = "prj-n8n-example-001"
  region     = "northamerica-northeast1"
  timezone   = "America/Toronto"
  
  n8n_version = "latest"
  db_tier     = "db-f1-micro"
}
```

### Customized Configuration

```hcl
module "n8n" {
  source = "github.com/byrde/terraform-project-registry//projects/n8n?ref=v1.0.0"

  project_id = "prj-n8n-production-001"
  region     = "us-central1"
  timezone   = "America/New_York"
  
  # n8n configuration
  n8n_version = "1.45.0"
  
  # Cloud Run scaling and resources
  cloud_run_min_instances = 2
  cloud_run_max_instances = 10
  cloud_run_cpu          = "2"
  cloud_run_memory        = "2Gi"
  
  # Cloud SQL configuration
  db_tier              = "db-n1-standard-2"
  db_disk_size         = 100
  db_disk_type         = "PD_SSD"
  db_availability_type = "REGIONAL"
  db_deletion_protection = true
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| project_id | GCP Project ID where resources will be deployed | string | yes | - |
| region | GCP region for resources | string | no | `northamerica-northeast1` |
| timezone | Timezone for n8n | string | no | `America/Toronto` |
| n8n_version | n8n Docker image version | string | no | `latest` |
| webhook_url | Webhook URL for n8n (set this to the Cloud Run URL after first apply) | string | no | `""` |
| wif_project_id | Workload Identity Federation project ID (required if enabling WIF project APIs) | string | no | `null` |

### Cloud Run Configuration

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| cloud_run_min_instances | Minimum number of Cloud Run instances | number | no | `1` |
| cloud_run_max_instances | Maximum number of Cloud Run instances | number | no | `1` |
| cloud_run_cpu | CPU allocation for Cloud Run container (e.g., '1', '2', '1000m') | string | no | `"1"` |
| cloud_run_memory | Memory allocation for Cloud Run container (e.g., '512Mi', '1Gi', '2Gi') | string | no | `"512Mi"` |

### Cloud SQL Configuration

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| db_tier | Cloud SQL instance tier | string | no | `db-f1-micro` |
| db_version | PostgreSQL version for Cloud SQL instance | string | no | `POSTGRES_15` |
| db_disk_size | Disk size for Cloud SQL instance in GB | number | no | `10` |
| db_disk_type | Disk type for Cloud SQL instance (PD_SSD or PD_STANDARD) | string | no | `PD_SSD` |
| db_availability_type | Availability type for Cloud SQL instance (ZONAL or REGIONAL) | string | no | `ZONAL` |
| db_backup_enabled | Enable automated backups for Cloud SQL | bool | no | `true` |
| db_backup_start_time | Start time for Cloud SQL backups (HH:MM format in UTC) | string | no | `"03:00"` |
| db_point_in_time_recovery | Enable point-in-time recovery for Cloud SQL | bool | no | `true` |
| db_maintenance_day | Day of week for Cloud SQL maintenance (1-7, where 1=Monday, 7=Sunday) | number | no | `7` |
| db_maintenance_hour | Hour of day for Cloud SQL maintenance (0-23) | number | no | `3` |
| db_update_track | Update track for Cloud SQL (stable or canary) | string | no | `stable` |
| db_deletion_protection | Enable deletion protection for Cloud SQL instance | bool | no | `false` |

## Outputs

| Name | Description |
|------|-------------|
| project_id | GCP Project ID |
| cloud_run_url | URL of the n8n Cloud Run service |
| database_instance_name | Name of the Cloud SQL instance |
| database_private_ip | Private IP address of the Cloud SQL instance |
| database_connection_name | Connection name for the Cloud SQL instance |
| service_account_email | Email of the service account used by Cloud Run |
| n8n_basic_auth_user | Username for n8n basic authentication |
| n8n_basic_auth_password | Instructions for retrieving password from Secret Manager |
| oauth_redirect_uri | OAuth redirect URI for n8n Google integration |
| webhook_url_setup | Instructions for setting up WEBHOOK_URL |
| oauth_setup_instructions | Instructions for setting up OAuth credentials manually |


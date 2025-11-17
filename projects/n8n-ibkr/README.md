# n8n-IBKR Project

Deploys n8n workflow automation platform on GCP using Cloud Run and Cloud SQL PostgreSQL, with an IB Gateway Docker sidecar container for Interactive Brokers integration.

This module includes all the infrastructure from the `n8n` module (database, secrets, APIs, service account) and extends it with an IB Gateway sidecar container running in the same Cloud Run service. Only one Cloud Run service is created with both containers.

## Usage

### Basic Usage

```hcl
module "n8n_ibkr" {
  source = "github.com/byrde/terraform-project-registry//projects/n8n-ibkr?ref=v1.0.0"

  project_id = "prj-n8n-ibkr-example-001"
  region     = "northamerica-northeast1"
  timezone   = "America/Toronto"
  
  n8n_version = "latest"
  db_tier     = "db-f1-micro"
  
  # IB Gateway credentials
  ib_gateway_tws_userid   = "your_ibkr_username"
  ib_gateway_tws_password = "your_ibkr_password"
  ib_gateway_trading_mode = "paper"
}
```

### Customized Configuration

```hcl
module "n8n_ibkr" {
  source = "github.com/byrde/terraform-project-registry//projects/n8n-ibkr?ref=v1.0.0"

  project_id = "prj-n8n-ibkr-production-001"
  region     = "us-central1"
  timezone   = "America/New_York"
  
  # n8n configuration
  n8n_version = "1.45.0"
  
  # Cloud Run resources
  # Note: Instance count is fixed at 1 (min=1, max=1) for consistent IB Gateway connection
  cloud_run_cpu          = "2"
  cloud_run_memory        = "2Gi"
  
  # Cloud SQL configuration
  db_tier              = "db-n1-standard-2"
  db_disk_size         = 100
  db_disk_type         = "PD_SSD"
  db_availability_type = "REGIONAL"
  db_deletion_protection = true
  
  # IB Gateway configuration
  ib_gateway_tws_userid   = "your_ibkr_username"
  ib_gateway_tws_password = "your_ibkr_password"
  ib_gateway_trading_mode = "live"
  ib_gateway_tws_port     = 7497
  ib_gateway_read_only_api = false
  
  # IB Gateway container resources
  ib_gateway_cpu    = "1"
  ib_gateway_memory = "1Gi"
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
| ib_gateway_tws_userid | Interactive Brokers TWS user ID | string | yes | - |
| ib_gateway_tws_password | Interactive Brokers TWS password | string | yes | - |

### Cloud Run Configuration

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| cloud_run_cpu | CPU allocation for Cloud Run container (e.g., '1', '2', '1000m') | string | no | `"1"` |
| cloud_run_memory | Memory allocation for Cloud Run container (e.g., '512Mi', '1Gi', '2Gi') | string | no | `"512Mi"` |
| cloud_run_deletion_protection | Enable deletion protection for Cloud Run service | bool | no | `false` |

**Note**: Instance count is fixed at 1 (min=1, max=1) to ensure consistent IB Gateway connection. IB Gateway requires a persistent connection, and scaling would disrupt this connection.

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

### IB Gateway Configuration

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| ib_gateway_version | IB Gateway Docker image version/tag | string | no | `latest` |
| ib_gateway_tws_userid | Interactive Brokers TWS user ID | string | yes | - |
| ib_gateway_tws_password | Interactive Brokers TWS password | string | yes | - |
| ib_gateway_tws_port | TWS port (4001 for paper trading, 7497 for live) | number | no | `4001` |
| ib_gateway_read_only_api | Enable read-only API mode | bool | no | `false` |
| ib_gateway_trading_mode | Trading mode: 'paper' or 'live' | string | no | `paper` |
| ib_gateway_cpu | CPU allocation for IB Gateway container (e.g., '1', '2', '1000m') | string | no | `"1"` |
| ib_gateway_memory | Memory allocation for IB Gateway container (e.g., '512Mi', '1Gi', '2Gi') | string | no | `"1Gi"` |
| ib_gateway_container_port | Container port for IB Gateway API | number | no | `4001` |
| ib_gateway_second_factor_device | Device identifier for 2FA (e.g., 'IB Key' or device ID) | string | no | `""` |
| ib_gateway_relogin_after_2fa_timeout | Whether to attempt relogin after 2FA timeout (yes/no) | string | no | `"yes"` |
| ib_gateway_2fa_timeout_seconds | Seconds to wait for 2FA authentication before timing out | number | no | `300` |

## Outputs

| Name | Description |
|------|-------------|
| project_id | GCP Project ID |
| cloud_run_url | URL of the n8n-ibkr Cloud Run service |
| database_instance_name | Name of the Cloud SQL instance |
| database_private_ip | Private IP address of the Cloud SQL instance |
| database_connection_name | Connection name for the Cloud SQL instance |
| service_account_email | Email of the service account used by Cloud Run |
| n8n_basic_auth_user | Username for n8n basic authentication |
| n8n_basic_auth_password | Instructions for retrieving password from Secret Manager |
| ib_gateway_api_url | IB Gateway API URL (accessible from within the Cloud Run service) |
| ib_gateway_container_port | Container port for IB Gateway API |
| oauth_redirect_uri | OAuth redirect URI for n8n Google integration |
| webhook_url_setup | Instructions for setting up WEBHOOK_URL |
| oauth_setup_instructions | Instructions for setting up OAuth credentials manually |
| ib_gateway_connection_info | Information about connecting to IB Gateway from n8n |

## IB Gateway Configuration

### Connecting to IB Gateway from n8n

The IB Gateway container runs as a sidecar in the same Cloud Run service as n8n. Both containers share the same network namespace, allowing n8n workflows to connect to IB Gateway via `localhost`.

From within n8n workflows, connect to IB Gateway at:
- **URL**: `http://localhost:4001` (or the port specified in `ib_gateway_container_port`)
- **Port**: Default is `4001` for paper trading, `7497` for live trading

The IB Gateway API is only accessible from within the Cloud Run service and is not exposed externally for security reasons.

### Authentication

IB Gateway credentials are configured via Terraform variables and stored securely in Google Secret Manager:

- **`ib_gateway_tws_userid`**: Your Interactive Brokers account username (required)
- **`ib_gateway_tws_password`**: Your Interactive Brokers account password (required)

These credentials are automatically stored in Secret Manager and injected into the IB Gateway container at runtime. Never hardcode credentials in your Terraform files - use variables or environment variables.

### Two-Factor Authentication (2FA)

**Important**: As of February 2025, Interactive Brokers requires 2FA for all accounts, including paper trading accounts. 2FA cannot be disabled.

**2FA Reality**: 2FA approval must be done manually through the IB Key mobile app. There is no fully automated way to bypass this requirement. When the container starts or reconnects, you must manually approve the 2FA request through the IB Key mobile app.

**2FA Configuration Variables**:
- `ib_gateway_second_factor_device`: Device identifier for 2FA (optional, if supported by Docker image)
- `ib_gateway_relogin_after_2fa_timeout`: Whether to attempt relogin after 2FA timeout (`yes` or `no`, default: `yes`)
- `ib_gateway_2fa_timeout_seconds`: Seconds to wait for 2FA authentication before timing out (default: `300`)

These environment variables help with retry logic and timeout handling, but manual approval is still required.

**Workflow Impact**: Manual 2FA approval will disrupt fully automated workflows. Plan for this in your automation design - workflows that require continuous IB Gateway connectivity may need manual intervention when the container restarts or reconnects.

### Resource Allocation

Configure IB Gateway container resources:

- **`ib_gateway_cpu`**: CPU allocation (default: `"1"`)
- **`ib_gateway_memory`**: Memory allocation (default: `"1Gi"`)

Increase these if you experience performance issues or timeouts.

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to IB Gateway from n8n workflows

**Solutions**:
- Verify the container port matches your connection URL: `http://localhost:${ib_gateway_container_port}`
- Check that both containers are running in the same Cloud Run service
- Review Cloud Run logs for the `ib-gateway` container to see connection errors

**Problem**: IB Gateway authentication fails

**Solutions**:
- Verify credentials are correct in Secret Manager:
  ```bash
  gcloud secrets versions access latest --secret=ib-gateway-tws-userid --project=<project_id>
  gcloud secrets versions access latest --secret=ib-gateway-tws-password --project=<project_id>
  ```
- Check Cloud Run logs for authentication errors
- Ensure your IB account is not locked or restricted
- Verify the trading mode (`paper` vs `live`) matches your account type
- For 2FA issues, ensure you approve the 2FA request through the IB Key mobile app when the container starts
- Check that `ib_gateway_second_factor_device` is correctly configured (if using)
- Review 2FA timeout settings if authentication is timing out

### Port Conflicts

**Problem**: Port already in use or connection refused

**Solutions**:
- Ensure `ib_gateway_container_port` doesn't conflict with the n8n port (5678)
- Verify the port is correctly configured in your n8n workflow HTTP requests
- Check Cloud Run service logs for port binding errors

### Container Startup Issues

**Problem**: IB Gateway container fails to start or crashes

**Solutions**:
- Check Cloud Run logs for the `ib-gateway` container:
  ```bash
  gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n-ibkr" --limit=50 --project=<project_id>
  ```
- Verify environment variables are correctly set (check `main.tf`)
- Increase container memory if you see out-of-memory errors
- Check if the IB Gateway Docker image version is compatible

### API Timeouts

**Problem**: API requests timeout or hang

**Solutions**:
- Increase `ib_gateway_memory` and `ib_gateway_cpu` if resources are constrained
- Check Cloud Run instance CPU and memory utilization
- Verify network connectivity between containers (should be automatic via localhost)
- Review IB Gateway logs for slow response times

### Checking Container Status

To check if both containers are running:

```bash
gcloud run services describe n8n-ibkr --region=<region> --project=<project_id>
```

Look for container status in the output. Both `n8n` and `ib-gateway` containers should be listed.

### Viewing Logs

View IB Gateway container logs:

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n-ibkr AND jsonPayload.container=ib-gateway" --limit=100 --project=<project_id>
```

View n8n container logs:

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n-ibkr AND jsonPayload.container=n8n" --limit=100 --project=<project_id>
```

### Updating Credentials

To update IB Gateway credentials without recreating the service:

1. Update the secrets in Secret Manager:
   ```bash
   echo -n "new_username" | gcloud secrets versions add ib-gateway-tws-userid --data-file=- --project=<project_id>
   echo -n "new_password" | gcloud secrets versions add ib-gateway-tws-password --data-file=- --project=<project_id>
   ```

2. Restart the Cloud Run service to pick up new secret versions:
   ```bash
   gcloud run services update n8n-ibkr --region=<region> --project=<project_id>
   ```

Or update via Terraform by changing the variable values and running `terraform apply`.


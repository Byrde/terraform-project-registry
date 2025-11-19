# Local variables
locals {
  # APIs required for this project
  project_apis = [
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "calendar-json.googleapis.com",
    "people.googleapis.com",
    "drive.googleapis.com",
    "gmail.googleapis.com",
    "sheets.googleapis.com",
    "tasks.googleapis.com",
    "compute.googleapis.com", # Required for some networking features
  ]

  # Python bridge script to expose IB Gateway (TCP) via HTTP
  ib_bridge_script = <<-EOT
import asyncio
import os
import logging
from fastapi import FastAPI, HTTPException
from ib_insync import IB, util

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ib-bridge")

app = FastAPI()
ib = IB()

HOST = '127.0.0.1'
PORTS = [4001, 4002] # Try both live (4001) and paper (4002) ports
CLIENT_ID = 0  # 0 is usually the master client

@app.on_event("startup")
async def startup():
    logger.info("Starting IB Bridge...")
    # Start connection loop in background
    asyncio.create_task(connect_loop())

async def connect_loop():
    while True:
        try:
            if not ib.isConnected():
                for port in PORTS:
                    try:
                        logger.info(f"Connecting to IB Gateway at {HOST}:{port}...")
                        await ib.connectAsync(HOST, port, clientId=CLIENT_ID)
                        logger.info(f"Connected to IB Gateway on port {port}")
                        break # Connected successfully
                    except Exception as e:
                        logger.warning(f"Failed to connect to port {port}: {e}")
                
                if not ib.isConnected():
                    logger.error("Could not connect to any IB Gateway port. Retrying in 5s...")
        except Exception as e:
            logger.error(f"Connection loop error: {e}")
        
        await asyncio.sleep(5)

@app.get("/")
def root():
    return {"status": "IB Bridge Running", "connected": ib.isConnected()}

@app.get("/health")
async def health():
    # Simple retry logic for health check
    for _ in range(3):
        if ib.isConnected():
            return {"status": "healthy", "connected": True}
        await asyncio.sleep(1)
    
    raise HTTPException(status_code=503, detail="Not connected to IB Gateway")

@app.get("/positions")
def get_positions():
    if not ib.isConnected():
        raise HTTPException(status_code=503, detail="Not connected to IB Gateway")
    return ib.positions()

@app.get("/account")
def get_account():
    if not ib.isConnected():
        raise HTTPException(status_code=503, detail="Not connected to IB Gateway")
    return ib.accountSummary()

# Generic endpoint to execute flex queries or other logic can be added here
EOT
}

# Enable required APIs in project
resource "google_project_service" "apis" {
  for_each = toset(local.project_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Enable required APIs in WIF project (for cross-project operations)
resource "google_project_service" "wif_apis" {
  for_each = var.wif_project_id != null ? toset(local.project_apis) : toset([])

  project            = var.wif_project_id
  service            = each.value
  disable_on_destroy = false
}

# Wait for APIs to propagate
resource "time_sleep" "wait_for_apis" {
  depends_on = [
    google_project_service.apis,
    google_project_service.wif_apis
  ]

  create_duration = "60s"
}

# Generate random password for PostgreSQL
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Generate random encryption key for n8n
resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = false
}

# Generate random password for n8n basic auth
resource "random_password" "n8n_basic_auth_password" {
  length  = 32
  special = true
}

# Store secrets in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "n8n-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "n8n_encryption_key" {
  secret_id = "n8n-encryption-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_secret_manager_secret_version" "n8n_encryption_key" {
  secret      = google_secret_manager_secret.n8n_encryption_key.id
  secret_data = random_password.n8n_encryption_key.result
}

resource "google_secret_manager_secret" "n8n_basic_auth_password" {
  secret_id = "n8n-basic-auth-password"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_secret_manager_secret_version" "n8n_basic_auth_password" {
  secret      = google_secret_manager_secret.n8n_basic_auth_password.id
  secret_data = random_password.n8n_basic_auth_password.result
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "n8n_db" {
  name             = "n8n-db-instance"
  project          = var.project_id
  database_version = var.db_version
  region           = var.region

  settings {
    tier              = var.db_tier
    availability_type = var.db_availability_type
    disk_size         = var.db_disk_size
    disk_type         = var.db_disk_type

    backup_configuration {
      enabled                        = var.db_backup_enabled
      start_time                     = var.db_backup_start_time
      point_in_time_recovery_enabled = var.db_point_in_time_recovery
    }

    ip_configuration {
      ipv4_enabled = true
      # No authorized networks - only accessible via Cloud SQL Proxy from Cloud Run
    }

    maintenance_window {
      day          = var.db_maintenance_day
      hour         = var.db_maintenance_hour
      update_track = var.db_update_track
    }
  }

  deletion_protection = var.db_deletion_protection

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_sql_database" "n8n_database" {
  name     = "n8n"
  project  = var.project_id
  instance = google_sql_database_instance.n8n_db.name
}

resource "google_sql_user" "n8n_user" {
  name     = "n8n"
  project  = var.project_id
  instance = google_sql_database_instance.n8n_db.name
  password = random_password.db_password.result
}

# Service account for Cloud Run
resource "google_service_account" "n8n_service_account" {
  account_id   = "n8n-cloud-run"
  project      = var.project_id
  display_name = "n8n Cloud Run Service Account"
}

# Grant Cloud Run service account access to secrets
resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "encryption_key_access" {
  secret_id = google_secret_manager_secret.n8n_encryption_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "basic_auth_password_access" {
  secret_id = google_secret_manager_secret.n8n_basic_auth_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

# Grant Cloud Run service account access to Cloud SQL
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

# Store IB Gateway credentials in Secret Manager
resource "google_secret_manager_secret" "ib_gateway_tws_userid" {
  secret_id = "ib-gateway-tws-userid"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_secret_manager_secret_version" "ib_gateway_tws_userid" {
  secret      = google_secret_manager_secret.ib_gateway_tws_userid.id
  secret_data = var.ib_gateway_tws_userid
}

resource "google_secret_manager_secret" "ib_gateway_tws_password" {
  secret_id = "ib-gateway-tws-password"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    time_sleep.wait_for_apis
  ]
}

resource "google_secret_manager_secret_version" "ib_gateway_tws_password" {
  secret      = google_secret_manager_secret.ib_gateway_tws_password.id
  secret_data = var.ib_gateway_tws_password
}

# Grant Cloud Run service account access to IB Gateway secrets
resource "google_secret_manager_secret_iam_member" "ib_gateway_userid_access" {
  secret_id = google_secret_manager_secret.ib_gateway_tws_userid.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "ib_gateway_password_access" {
  secret_id = google_secret_manager_secret.ib_gateway_tws_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_service_account.email}"
}

# Cloud Run service with n8n and IB Gateway sidecar
resource "google_cloud_run_v2_service" "n8n_ibkr" {
  name               = "n8n-ibkr"
  project            = var.project_id
  location           = var.region
  ingress            = "INGRESS_TRAFFIC_ALL"
  deletion_protection = var.cloud_run_deletion_protection

  template {
    service_account = google_service_account.n8n_service_account.email
    timeout         = "${var.cloud_run_timeout_seconds}s"

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.n8n_db.connection_name]
      }
    }

    # n8n container
    containers {
      name  = "n8n"
      image = "n8nio/n8n:${var.n8n_version}"

      ports {
        container_port = 5678
      }

      startup_probe {
        tcp_socket {
          port = 5678
        }
        initial_delay_seconds = 0
        timeout_seconds      = 1
        period_seconds       = 3
        failure_threshold    = 200
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
      }

      env {
        name  = "GENERIC_TIMEZONE"
        value = var.timezone
      }

      env {
        name  = "TZ"
        value = var.timezone
      }

      env {
        name  = "N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS"
        value = "true"
      }

      env {
        name  = "N8N_RUNNERS_ENABLED"
        value = "true"
      }

      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }

      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = "n8n"
      }

      env {
        name  = "DB_POSTGRESDB_HOST"
        value = "/cloudsql/${google_sql_database_instance.n8n_db.connection_name}"
      }

      env {
        name  = "DB_POSTGRESDB_USER"
        value = "n8n"
      }

      env {
        name  = "DB_POSTGRESDB_SCHEMA"
        value = "public"
      }

      env {
        name = "DB_POSTGRESDB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "N8N_ENCRYPTION_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.n8n_encryption_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "N8N_BASIC_AUTH_ACTIVE"
        value = "true"
      }

      env {
        name  = "N8N_BASIC_AUTH_USER"
        value = "admin"
      }

      env {
        name = "N8N_BASIC_AUTH_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.n8n_basic_auth_password.secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = var.webhook_url != "" ? [1] : []
        content {
          name  = "WEBHOOK_URL"
          value = var.webhook_url
        }
      }

      dynamic "env" {
        for_each = var.n8n_debug_logs ? [1] : []
        content {
          name  = "N8N_LOG_LEVEL"
          value = "debug"
        }
      }
    }

    # IB Gateway container (gnzsnz/ib-gateway)
    containers {
      name  = "ib-gateway"
      image = "gnzsnz/ib-gateway:latest"

      # No exposed ports for sidecar - only accessible via localhost
      
      resources {
        limits = {
          cpu    = var.ib_gateway_cpu
          memory = var.ib_gateway_memory
        }
      }

      env {
        name = "TWS_USERID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ib_gateway_tws_userid.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "TWS_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ib_gateway_tws_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "TRADING_MODE"
        value = "live" # Default to paper, can be parameterized if needed
      }

      env {
        name  = "IBC_INI"
        value = "/root/ibc/config.ini"
      }

      env {
        name  = "TWS_SETTINGS_PATH"
        value = "/root/Jts"
      }

      env {
        name  = "READ_ONLY_API"
        value = var.ib_gateway_read_only_api ? "yes" : "no"
      }

      # Disable VNC to save resources if not needed, or keep it for debugging
      # env {
      #   name  = "XVFB_IGNORE_XAUTH"
      #   value = "1"
      # }
    }

    # HTTP Bridge container (Python + ib_insync)
    containers {
      name  = "ib-http-bridge"
      image = "python:3.11-slim"

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      env {
        name  = "BRIDGE_SCRIPT_CONTENT"
        value = local.ib_bridge_script
      }

      # Install dependencies and run the bridge script
      command = ["/bin/sh", "-c"]
      args    = ["pip install fastapi uvicorn ib_insync && echo \"$BRIDGE_SCRIPT_CONTENT\" > bridge.py && uvicorn bridge:app --host 127.0.0.1 --port 5000"]
    }
  }

  depends_on = [
    time_sleep.wait_for_apis,
    google_sql_database_instance.n8n_db,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.n8n_encryption_key,
    google_secret_manager_secret_version.n8n_basic_auth_password,
    google_secret_manager_secret_version.ib_gateway_tws_userid,
    google_secret_manager_secret_version.ib_gateway_tws_password,
    google_secret_manager_secret_iam_member.ib_gateway_userid_access,
    google_secret_manager_secret_iam_member.ib_gateway_password_access,
  ]
}

# Allow unauthenticated access to Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.n8n_ibkr.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Note: OAuth 2.0 client credentials for Google APIs must be created manually
# in the Google Cloud Console. Terraform's Google provider does not support
# creating standard OAuth clients outside of IAP context.
#
# After applying this configuration, run: terraform output oauth_setup_instructions
# for complete setup instructions including the correct OAuth redirect URI.

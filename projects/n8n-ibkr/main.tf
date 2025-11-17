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
  ]

  # APIs required in WIF project for cross-project operations
  # When using a service account from another project, certain APIs must be enabled there too
  wif_project_apis = [
    "sqladmin.googleapis.com", # Required for Cloud SQL operations
  ]
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
  for_each = var.wif_project_id != null ? toset(local.wif_project_apis) : toset([])

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
  name     = "n8n-ibkr"
  project  = var.project_id
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.n8n_service_account.email

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
    }

    # IB Gateway sidecar container
    containers {
      name  = "ib-gateway"
      image = var.ib_gateway_image

      ports {
        container_port = var.ib_gateway_container_port
      }

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
        name  = "TWS_PORT"
        value = tostring(var.ib_gateway_tws_port)
      }

      env {
        name  = "READ_ONLY_API"
        value = tostring(var.ib_gateway_read_only_api)
      }

      env {
        name  = "TRADING_MODE"
        value = var.ib_gateway_trading_mode
      }

      dynamic "env" {
        for_each = var.ib_gateway_second_factor_device != "" ? [1] : []
        content {
          name  = "SecondFactorDevice"
          value = var.ib_gateway_second_factor_device
        }
      }

      env {
        name  = "ReloginAfterSecondFactorAuthenticationTimeout"
        value = var.ib_gateway_relogin_after_2fa_timeout
      }

      env {
        name  = "SecondFactorAuthenticationExitInterval"
        value = tostring(var.ib_gateway_2fa_timeout_seconds)
      }
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

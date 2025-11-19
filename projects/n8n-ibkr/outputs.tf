output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "cloud_run_url" {
  description = "URL of the n8n-ibkr Cloud Run service"
  value       = google_cloud_run_v2_service.n8n_ibkr.uri
}

output "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.n8n_db.name
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.n8n_db.private_ip_address
  sensitive   = true
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.n8n_db.connection_name
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Run"
  value       = google_service_account.n8n_service_account.email
}

output "n8n_basic_auth_user" {
  description = "Username for n8n basic authentication"
  value       = "admin"
}

output "n8n_basic_auth_password" {
  description = "Password for n8n basic authentication (retrieve from Secret Manager)"
  value       = "Use: gcloud secrets versions access latest --secret=n8n-basic-auth-password --project=${var.project_id}"
}

output "ib_gateway_api_url" {
  description = "IB Gateway API URL (accessible from within the Cloud Run service)"
  value       = "http://localhost:5000"
}

output "ib_gateway_port" {
  description = "IB Gateway API port (default: 5000)"
  value       = 5000
}

output "oauth_redirect_uri" {
  description = "OAuth redirect URI for n8n Google integration (use when creating OAuth credentials)"
  value       = "${google_cloud_run_v2_service.n8n_ibkr.uri}/rest/oauth2-credential/callback"
}

output "webhook_url_setup" {
  description = "Instructions for setting up WEBHOOK_URL"
  value       = <<-EOT
    IMPORTANT: After first apply, you need to set the webhook_url variable.
    
    1. Note the cloud_run_url output above: ${google_cloud_run_v2_service.n8n_ibkr.uri}
    2. Add to your terraform.tfvars:
       webhook_url = "${google_cloud_run_v2_service.n8n_ibkr.uri}"
    3. Run: terraform apply
    
    This will update the WEBHOOK_URL environment variable in Cloud Run.
  EOT
}

output "oauth_setup_instructions" {
  description = "Instructions for setting up OAuth credentials manually"
  value       = <<-EOT
    OAuth credentials must be created manually in Google Cloud Console:
    
    1. Go to: https://console.cloud.google.com/apis/credentials?project=${var.project_id}
    2. Configure OAuth consent screen:
       - User type: Internal (for byrde.io organization only)
       - App name: n8n Workflow Automation
       - Support email: martin@byrde.io
    3. Create OAuth 2.0 Client ID:
       - Application type: Web application
       - Name: n8n OAuth Client
       - Authorized redirect URIs: ${google_cloud_run_v2_service.n8n_ibkr.uri}/rest/oauth2-credential/callback
    4. Download or copy the Client ID and Client Secret
    5. Configure in n8n credentials settings
  EOT
}

output "ib_gateway_connection_info" {
  description = "Information about connecting to IB Gateway from n8n"
  value       = <<-EOT
    IB Gateway (Client Portal API) is running as a sidecar container in the same Cloud Run service.
    
    From within n8n workflows, you can connect to IB Gateway at:
    - URL: http://localhost:5000
    - Port: 5000
    - Trading Mode: Controlled by IB credentials (paper vs live user)
    - Read-Only API: ${var.ib_gateway_read_only_api}
    
    Note: The IB Gateway API is only accessible from within the Cloud Run service.
    Both containers share the same network namespace, so localhost connections work.
  EOT
}


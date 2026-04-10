# ═══════════════════════════════════════════════════════════════
# Compute
# ═══════════════════════════════════════════════════════════════
output "instance_name" {
  description = "Compute Engine instance name"
  value       = google_compute_instance.main.name
}

output "instance_id" {
  description = "Compute Engine instance ID"
  value       = google_compute_instance.main.instance_id
}

output "external_ip" {
  description = "External IP address"
  value       = try(
    var.enable_static_ip ? google_compute_address.main[0].address : google_compute_instance.main.network_interface[0].access_config[0].nat_ip,
    null
  )
}

output "internal_ip" {
  description = "Internal VPC IP"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "service_account_email" {
  description = "VM service account email"
  value       = google_service_account.vm.email
}

# ═══════════════════════════════════════════════════════════════
# Access
# ═══════════════════════════════════════════════════════════════
output "ssh_command" {
  description = "SSH via gcloud"
  value       = "gcloud compute ssh ${google_compute_instance.main.name} --zone=${var.zone} --project=${var.project_id}"
}

output "ssh_iap_command" {
  description = "SSH via IAP tunnel (no public IP needed)"
  value       = "gcloud compute ssh ${google_compute_instance.main.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "n8n_url" {
  description = "n8n workflow editor"
  value       = try("http://${var.enable_static_ip ? google_compute_address.main[0].address : google_compute_instance.main.network_interface[0].access_config[0].nat_ip}:5678", null)
}

output "health_url" {
  description = "Health check endpoint"
  value       = try("http://${var.enable_static_ip ? google_compute_address.main[0].address : google_compute_instance.main.network_interface[0].access_config[0].nat_ip}/health", null)
}

output "console_url" {
  description = "GCP Console link"
  value       = "https://console.cloud.google.com/compute/instancesDetail/zones/${var.zone}/instances/${google_compute_instance.main.name}?project=${var.project_id}"
}

# ═══════════════════════════════════════════════════════════════
# Network
# ═══════════════════════════════════════════════════════════════
output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.main.id
}

# ═══════════════════════════════════════════════════════════════
# Storage
# ═══════════════════════════════════════════════════════════════
output "gcs_bucket" {
  description = "GCS artifact bucket"
  value       = var.enable_gcs_bucket ? google_storage_bucket.artifacts[0].name : null
}

output "secret_id" {
  description = "Secret Manager secret ID"
  value       = google_secret_manager_secret.workflow_config.secret_id
}

# ═══════════════════════════════════════════════════════════════
# AI Orchestration
# ═══════════════════════════════════════════════════════════════
output "dialogflow_agent_id" {
  description = "Dialogflow CX Agent ID"
  value       = var.enable_vertex ? google_dialogflow_cx_agent.main[0].id : ""
}

output "dialogflow_agent_name" {
  description = "Dialogflow CX Agent display name"
  value       = var.enable_vertex ? google_dialogflow_cx_agent.main[0].display_name : ""
}

output "vertex_console_url" {
  description = "Vertex AI console link"
  value       = var.enable_vertex ? "https://dialogflow.cloud.google.com/cx/projects/${var.project_id}/locations/${var.region}/agents/${google_dialogflow_cx_agent.main[0].id}" : ""
}

# ═══════════════════════════════════════════════════════════════
# Load Balancer
# ═══════════════════════════════════════════════════════════════
output "lb_ip" {
  description = "Load balancer IP"
  value       = var.enable_load_balancer ? google_compute_global_forwarding_rule.main[0].ip_address : null
}

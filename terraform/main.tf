terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.10"
    }
  }

  # Remote state in Google Cloud Storage
  backend "gcs" {
    bucket = "agentbridge-tfstate-${var.project_id}"
    prefix = "deployments/reconciliation-engine---collateral--corp"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ═══════════════════════════════════════════════════════════════
# API ENABLEMENT — Required Google Cloud APIs
# ═══════════════════════════════════════════════════════════════
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

# ═══════════════════════════════════════════════════════════════
# IAM — Dedicated service account with least-privilege roles
# ═══════════════════════════════════════════════════════════════
resource "google_service_account" "vm" {
  account_id   = "ab-reconciliation-engine---collateral--corp"
  display_name = "AgentBridge Reconciliation Engine • Collateral (Corporate Banking) Runtime"
  description  = "Service account for AgentBridge workflow VM - least privilege"
  project      = var.project_id

  depends_on = [google_project_service.iam]
}

# Logging: write logs to Cloud Logging
resource "google_project_iam_member" "vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Monitoring: write metrics to Cloud Monitoring
resource "google_project_iam_member" "vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Secret Manager: access own secrets
resource "google_project_iam_member" "vm_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Cloud Storage: read/write artifacts bucket
resource "google_storage_bucket_iam_member" "vm_storage" {
  count  = var.enable_gcs_bucket ? 1 : 0
  bucket = google_storage_bucket.artifacts[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm.email}"
}

# ═══════════════════════════════════════════════════════════════
# NETWORK — Dedicated VPC + subnet per deployment
# ═══════════════════════════════════════════════════════════════
resource "google_compute_network" "main" {
  name                    = "ab-reconciliation-engine---collateral--corp-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "main" {
  name          = "ab-reconciliation-engine---collateral--corp-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

# Cloud NAT for outbound without public IP (if desired)
resource "google_compute_router" "main" {
  name    = "ab-reconciliation-engine---collateral--corp-router"
  network = google_compute_network.main.id
  region  = var.region
}

resource "google_compute_router_nat" "main" {
  name                               = "ab-reconciliation-engine---collateral--corp-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ═══════════════════════════════════════════════════════════════
# FIREWALL — Least-privilege rules with priority ordering
# ═══════════════════════════════════════════════════════════════
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "ab-reconciliation-engine---collateral--corp-deny-all"
  network   = google_compute_network.main.name
  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh" {
  name      = "ab-reconciliation-engine---collateral--corp-allow-ssh"
  network   = google_compute_network.main.name
  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ab-reconciliation-engine---collateral--corp"]
}

resource "google_compute_firewall" "allow_http" {
  name      = "ab-reconciliation-engine---collateral--corp-allow-http"
  network   = google_compute_network.main.name
  priority  = 1001
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ab-reconciliation-engine---collateral--corp"]
}

resource "google_compute_firewall" "allow_n8n" {
  name      = "ab-reconciliation-engine---collateral--corp-allow-n8n"
  network   = google_compute_network.main.name
  priority  = 1002
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5678"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ab-reconciliation-engine---collateral--corp"]
}

resource "google_compute_firewall" "allow_health_check" {
  name      = "ab-reconciliation-engine---collateral--corp-allow-hc"
  network   = google_compute_network.main.name
  priority  = 999
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Google Cloud health check probe ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["ab-reconciliation-engine---collateral--corp"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "ab-reconciliation-engine---collateral--corp-allow-iap"
  network   = google_compute_network.main.name
  priority  = 998
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP tunnel IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ab-reconciliation-engine---collateral--corp"]
}

# ═══════════════════════════════════════════════════════════════
# STATIC IP
# ═══════════════════════════════════════════════════════════════
resource "google_compute_address" "main" {
  count        = var.enable_static_ip ? 1 : 0
  name         = "ab-reconciliation-engine---collateral--corp-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# ═══════════════════════════════════════════════════════════════
# COMPUTE ENGINE VM — Single-tenant workflow runtime
# ═══════════════════════════════════════════════════════════════
resource "google_compute_instance" "main" {
  name         = "ab-reconciliation-engine---collateral--corp"
  machine_type = var.instance_type
  zone         = var.zone

  tags = ["ab-reconciliation-engine---collateral--corp", var.environment, "agentbridge"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
    auto_delete = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    dynamic "access_config" {
      for_each = var.enable_static_ip ? [1] : (var.enable_public_ip ? [1] : [])
      content {
        nat_ip       = var.enable_static_ip ? google_compute_address.main[0].address : null
        network_tier = "PREMIUM"
      }
    }
  }

  metadata = {
    ssh-keys                = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : null
    enable-oslogin          = var.enable_os_login ? "TRUE" : "FALSE"
    block-project-ssh-keys  = "TRUE"
    startup-script          = file("${path.module}/scripts/cloud-init.yml")
  }

  labels = {
    environment  = var.environment
    blueprint    = "reconciliation-engine---collateral--corp"
    managed_by   = "terraform"
    workflow_id  = var.workflow_id
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [metadata["startup-script"]]
  }

  depends_on = [
    google_project_service.compute,
    google_project_iam_member.vm_log_writer,
    google_project_iam_member.vm_metric_writer,
  ]
}

# ═══════════════════════════════════════════════════════════════
# PERSISTENT DISK — Additional data volume
# ═══════════════════════════════════════════════════════════════
resource "google_compute_disk" "data" {
  count = var.additional_storage_gb > 0 ? 1 : 0
  name  = "ab-reconciliation-engine---collateral--corp-data"
  type  = "pd-ssd"
  zone  = var.zone
  size  = var.additional_storage_gb

  labels = {
    environment = var.environment
    blueprint   = "reconciliation-engine---collateral--corp"
  }
}

resource "google_compute_attached_disk" "data" {
  count    = var.additional_storage_gb > 0 ? 1 : 0
  disk     = google_compute_disk.data[0].id
  instance = google_compute_instance.main.id
  mode     = "READ_WRITE"
}

# ═══════════════════════════════════════════════════════════════
# CLOUD STORAGE — Artifact storage + log export
# ═══════════════════════════════════════════════════════════════
resource "google_storage_bucket" "artifacts" {
  count         = var.enable_gcs_bucket ? 1 : 0
  name          = "ab-reconciliation-engine---collateral--corp-artifacts-${var.project_id}"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 3
    }
  }

  labels = {
    environment = var.environment
    blueprint   = "reconciliation-engine---collateral--corp"
  }

  depends_on = [google_project_service.storage]
}

# ═══════════════════════════════════════════════════════════════
# SECRET MANAGER — Secrets injection for workflow runtime
# ═══════════════════════════════════════════════════════════════
resource "google_secret_manager_secret" "workflow_config" {
  secret_id = "ab-reconciliation-engine---collateral--corp-config"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    blueprint   = "reconciliation-engine---collateral--corp"
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "workflow_config" {
  secret      = google_secret_manager_secret.workflow_config.id
  secret_data = jsonencode({
    blueprint_name = "Reconciliation Engine • Collateral (Corporate Banking)"
    environment    = var.environment
    workflow_id    = var.workflow_id
  })
}

# ═══════════════════════════════════════════════════════════════
# CLOUD MONITORING — Uptime checks + alert policies
# ═══════════════════════════════════════════════════════════════
resource "google_monitoring_uptime_check_config" "health" {
  display_name = "ab-reconciliation-engine---collateral--corp-health"
  timeout      = "10s"
  period       = "60s"
  project      = var.project_id

  http_check {
    path         = "/health"
    port         = 80
    use_ssl      = false
    validate_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.enable_static_ip ? google_compute_address.main[0].address : google_compute_instance.main.network_interface[0].access_config[0].nat_ip
    }
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_notification_channel" "email" {
  count        = length(var.alert_emails) > 0 ? 1 : 0
  display_name = "ab-reconciliation-engine---collateral--corp-alerts"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.alert_emails[0]
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "health_check" {
  count        = length(var.alert_emails) > 0 ? 1 : 0
  display_name = "ab-reconciliation-engine---collateral--corp: Health Check Failed"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failed"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email[0].id]

  alert_strategy {
    auto_close = "604800s"
  }
}

# ═══════════════════════════════════════════════════════════════
# OPTIONAL HTTPS LOAD BALANCER
# ═══════════════════════════════════════════════════════════════
resource "google_compute_health_check" "main" {
  count               = var.enable_load_balancer ? 1 : 0
  name                = "ab-reconciliation-engine---collateral--corp-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

resource "google_compute_instance_group" "main" {
  count     = var.enable_load_balancer ? 1 : 0
  name      = "ab-reconciliation-engine---collateral--corp-ig"
  zone      = var.zone
  instances = [google_compute_instance.main.self_link]

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_backend_service" "main" {
  count                 = var.enable_load_balancer ? 1 : 0
  name                  = "ab-reconciliation-engine---collateral--corp-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.main[0].id]
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_instance_group.main[0].self_link
  }
}

resource "google_compute_url_map" "main" {
  count           = var.enable_load_balancer ? 1 : 0
  name            = "ab-reconciliation-engine---collateral--corp-urlmap"
  default_service = google_compute_backend_service.main[0].id
}

resource "google_compute_target_http_proxy" "main" {
  count   = var.enable_load_balancer ? 1 : 0
  name    = "ab-reconciliation-engine---collateral--corp-proxy"
  url_map = google_compute_url_map.main[0].id
}

resource "google_compute_global_forwarding_rule" "main" {
  count      = var.enable_load_balancer ? 1 : 0
  name       = "ab-reconciliation-engine---collateral--corp-fwd"
  target     = google_compute_target_http_proxy.main[0].id
  port_range = "80"
}

# ═══════════════════════════════════════════════════════════════
# VERTEX AI / DIALOGFLOW CX — AI Orchestration
# ═══════════════════════════════════════════════════════════════

resource "google_project_service" "aiplatform" {
  count   = var.enable_vertex ? 1 : 0
  project = var.project_id
  service = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dialogflow" {
  count   = var.enable_vertex ? 1 : 0
  project = var.project_id
  service = "dialogflow.googleapis.com"
  disable_on_destroy = false
}

# Service account roles for Vertex AI
resource "google_project_iam_member" "vm_dialogflow" {
  count   = var.enable_vertex ? 1 : 0
  project = var.project_id
  role    = "roles/dialogflow.client"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_aiplatform" {
  count   = var.enable_vertex ? 1 : 0
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Dialogflow CX Agent
resource "google_dialogflow_cx_agent" "main" {
  count                 = var.enable_vertex ? 1 : 0
  display_name          = "ab-Reconciliation Engine • Collateral (Corporate Banking)"
  location              = var.region
  default_language_code = "en"
  time_zone             = "America/New_York"

  depends_on = [google_project_service.dialogflow]
}

# Dialogflow CX Pages — one per workflow step


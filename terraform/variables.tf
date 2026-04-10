# ═══════════════════════════════════════════════════════════════
# Project
# ═══════════════════════════════════════════════════════════════
variable "project_id" {
  description = "Google Cloud project ID (customer-owned)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "workflow_id" {
  description = "Unique workflow identifier"
  type        = string
  default     = ""
}

# ═══════════════════════════════════════════════════════════════
# Compute
# ═══════════════════════════════════════════════════════════════
variable "instance_type" {
  description = "GCP machine type (e.g., e2-medium, n2-standard-4)"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "VM image (project/family or project/image)"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 65536
    error_message = "Boot disk must be 10-65536 GB."
  }
}

# ═══════════════════════════════════════════════════════════════
# Networking
# ═══════════════════════════════════════════════════════════════
variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed for SSH and n8n access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_static_ip" {
  description = "Reserve a static external IP"
  type        = bool
  default     = false
}

variable "enable_public_ip" {
  description = "Attach a public IP (ephemeral if static not enabled)"
  type        = bool
  default     = true
}

variable "enable_os_login" {
  description = "Enable OS Login for SSH (uses IAM instead of SSH keys)"
  type        = bool
  default     = false
}

# ═══════════════════════════════════════════════════════════════
# Storage
# ═══════════════════════════════════════════════════════════════
variable "additional_storage_gb" {
  description = "Additional persistent disk in GB (0 to skip)"
  type        = number
  default     = 0
}

variable "enable_gcs_bucket" {
  description = "Create a GCS bucket for artifacts"
  type        = bool
  default     = false
}

# ═══════════════════════════════════════════════════════════════
# Operations
# ═══════════════════════════════════════════════════════════════
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Must be development, staging, or production."
  }
}

variable "enable_load_balancer" {
  description = "Create an HTTP(S) load balancer"
  type        = bool
  default     = false
}

variable "alert_emails" {
  description = "Email addresses for monitoring alerts"
  type        = list(string)
  default     = []
}

# ═══════════════════════════════════════════════════════════════
# AI Orchestration
# ═══════════════════════════════════════════════════════════════
variable "enable_vertex" {
  description = "Enable Vertex AI / Dialogflow CX"
  type        = bool
  default     = false
}

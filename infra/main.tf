terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast2"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "storage" {
  service = "storage.googleapis.com"
}

resource "null_resource" "deploy" {
  depends_on = [
    google_project_service.cloud_run,
    google_project_service.cloud_build,
    google_project_service.storage
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cd ..
      gcloud builds submit --tag gcr.io/${var.project_id}/yumegatari .
      gcloud run deploy yumegatari \
        --image gcr.io/${var.project_id}/yumegatari \
        --platform managed \
        --region ${var.region} \
        --allow-unauthenticated \
        --port 4000 \
        --set-env-vars "SECRET_KEY_BASE=$(openssl rand -base64 32),PHX_SERVER=true" \
        --quiet
    EOT
  }
}

data "google_cloud_run_service" "yumegatari" {
  depends_on = [null_resource.deploy]
  name       = "yumegatari"
  location   = var.region
}

output "service_url" {
  value = data.google_cloud_run_service.yumegatari.status[0].url
}

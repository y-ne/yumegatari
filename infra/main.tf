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

resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com"
  ])
  service = each.key

  disable_on_destroy = false
}

resource "google_compute_network" "custom_vpc" {
  name                    = "yumegatari-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.required_apis]
}

resource "google_compute_subnetwork" "main_subnet" {
  name          = "yumegatari-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.custom_vpc.id

  private_ip_google_access = true
}

resource "google_vpc_access_connector" "cloud_run_connector" {
  name          = "yumegatari-connector"
  region        = var.region
  network       = google_compute_network.custom_vpc.name
  ip_cidr_range = "10.1.0.0/28"

  depends_on = [google_project_service.required_apis, google_compute_subnetwork.main_subnet]
}

resource "google_compute_address" "nat_external_ip" {
  name   = "yumegatari-nat-ip"
  region = var.region
}

resource "google_compute_router" "nat_router" {
  name    = "yumegatari-router"
  region  = var.region
  network = google_compute_network.custom_vpc.id
}

resource "google_compute_router_nat" "nat_gateway" {
  name   = "yumegatari-nat"
  router = google_compute_router.nat_router.name
  region = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat_external_ip.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "null_resource" "deploy_with_vpc" {
  depends_on = [
    google_vpc_access_connector.cloud_run_connector,
    google_compute_router_nat.nat_gateway
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
        --vpc-connector ${google_vpc_access_connector.cloud_run_connector.name} \
        --vpc-egress all-traffic \
        --set-env-vars "SECRET_KEY_BASE=$(openssl rand -base64 32),PHX_SERVER=true" \
        --quiet
    EOT
  }
}

data "google_cloud_run_service" "yumegatari" {
  depends_on = [null_resource.deploy_with_vpc]
  name       = "yumegatari"
  location   = var.region
}

output "service_url" {
  value       = data.google_cloud_run_service.yumegatari.status[0].url
}

output "static_outbound_ip" {
  value       = google_compute_address.nat_external_ip.address
}

output "vpc_name" {
  value       = google_compute_network.custom_vpc.name
}

output "subnet_cidr" {
  value       = google_compute_subnetwork.main_subnet.ip_cidr_range
}

output "connector_cidr" {
  value       = google_vpc_access_connector.cloud_run_connector.ip_cidr_range
}

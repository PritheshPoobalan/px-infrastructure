# Terraform module: Google Kubernetes Engine (GKE)
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13"
    }
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "px-gke"
}

variable "location" {
  description = "GCP region/zone"
  type        = string
  default     = "us-central1"
}

variable "network" {
  description = "VPC network self_link or name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self_link or name"
  type        = string
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-medium"
}

variable "tags" {
  description = "Common labels/tags"
  type        = map(string)
  default     = {}
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  network  = var.network
  subnetwork = var.subnetwork

  removal_protection = false

  enable_autopilot = false

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "px-services"
    services_secondary_range_name = "px-services"
  }

  workload_identity_config {
    identity_namespace = var.location
  }

  labels = var.tags
}

resource "google_container_node_pool" "primary" {
  name       = "${var.cluster_name}-nodes"
  location   = var.location
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    labels       = var.tags
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "ca_certificate" {
  value     = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive = true
}

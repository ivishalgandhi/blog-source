# LAB-08-B GCP Module — 3-node Patroni cluster + Cloud Storage backup bucket

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "region" {
  description = "GCP region for primary cluster"
  type        = string
}

variable "zone" {
  description = "GCP zone for instances"
  type        = string
  default     = "us-central1-a"
}

variable "instance_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-medium"
}

variable "ssh_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "lab-08-b"
}

variable "node_count" {
  description = "Number of Patroni nodes"
  type        = number
  default     = 3
}

# VPC
resource "google_compute_network" "main" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.main.id
}

# Firewall — SSH from anywhere
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.cluster_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.cluster_name]
}

# Firewall — internal cluster traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5432", "8008", "2379", "2380"]
  }

  source_ranges = [google_compute_subnetwork.main.ip_cidr_range]
  target_tags   = [var.cluster_name]
}

# Compute Engine Instances
resource "google_compute_instance" "patroni" {
  count        = var.node_count
  name         = "${var.cluster_name}-node-${count.index + 1}"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }

  tags = [var.cluster_name]
}

# Cloud Storage Bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "backups" {
  name          = "${var.cluster_name}-backups-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
  labels = {
    name = var.cluster_name
  }
}

output "instance_ips" {
  description = "External IPs of Patroni cluster nodes"
  value       = google_compute_instance.patroni[*].network_interface[0].access_config[0].nat_ip
}

output "backup_bucket" {
  description = "Cloud Storage bucket name for pgBackRest backups"
  value       = google_storage_bucket.backups.name
}

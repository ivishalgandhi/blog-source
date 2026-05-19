# LAB-08-B — Cross-Region Disaster Recovery
# Top-level Terraform entry point. Delegates to AWS or GCP module based on var.provider.

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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

# ---------------------------------------------------------------------------
# AWS
# ---------------------------------------------------------------------------
module "aws" {
  count = var.provider == "aws" ? 1 : 0

  source        = "./modules/aws"
  region        = var.region
  instance_type = var.instance_type
  key_name      = var.key_name
  cluster_name  = var.cluster_name
  node_count    = var.node_count
}

# ---------------------------------------------------------------------------
# GCP
# ---------------------------------------------------------------------------
module "gcp" {
  count = var.provider == "gcp" ? 1 : 0

  source        = "./modules/gcp"
  region        = var.region
  zone          = var.zone
  instance_type = var.instance_type
  ssh_key       = var.ssh_key
  cluster_name  = var.cluster_name
  node_count    = var.node_count
}

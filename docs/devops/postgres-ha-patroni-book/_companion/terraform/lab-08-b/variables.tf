# LAB-08-B — Variables

variable "provider" {
  description = "Cloud provider to deploy into: aws or gcp"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "gcp"], var.provider)
    error_message = "Provider must be 'aws' or 'gcp'."
  }
}

variable "region" {
  description = "Primary region for the Patroni cluster"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Instance / machine type for Patroni nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS EC2 key pair name (AWS only)"
  type        = string
  default     = ""
}

variable "ssh_key" {
  description = "GCP SSH public key string, e.g. contents of ~/.ssh/id_rsa.pub (GCP only)"
  type        = string
  default     = ""
}

variable "zone" {
  description = "GCP zone (GCP only)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name prefix for all cluster resources"
  type        = string
  default     = "lab-08-b"
}

variable "node_count" {
  description = "Number of Patroni nodes to provision"
  type        = number
  default     = 3
}

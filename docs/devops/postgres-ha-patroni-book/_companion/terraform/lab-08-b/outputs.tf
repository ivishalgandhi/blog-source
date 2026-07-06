# LAB-08-B — Outputs

output "cluster_endpoints" {
  description = "Public IPs of the Patroni cluster nodes"
  value       = try(module.aws[0].instance_ips, module.gcp[0].instance_ips, [])
}

output "backup_bucket_name" {
  description = "Name of the backup storage bucket (S3 or Cloud Storage)"
  value       = try(module.aws[0].backup_bucket, module.gcp[0].backup_bucket, null)
}

output "cloud_provider_used" {
  description = "The cloud provider that was selected"
  value       = var.cloud_provider
}

output "gke_cluster_name" {
  value       = google_container_cluster.hardened_cluster.name
  description = "Name of the hardened GKE cluster"
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.hardened_cluster.endpoint
  description = "Kubernetes API Server endpoint"
  sensitive   = false
}

output "gke_cluster_location" {
  value       = google_container_cluster.hardened_cluster.location
  description = "Location (zone or region) of the GKE cluster"
}

output "gke_connect_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.hardened_cluster.name} --zone ${google_container_cluster.hardened_cluster.location} --project ${var.project_id}"
  description = "Command to authenticate and configure kubectl for the hardened GKE cluster"
}

output "vpc_network_name" {
  value       = google_compute_network.vpc_network.name
  description = "VPC network name hosting GKE"
}

output "gke_subnetwork_name" {
  value       = google_compute_subnetwork.gke_subnet.name
  description = "Subnetwork name hosting GKE nodes"
}

output "cloud_armor_policy_name" {
  value       = google_compute_security_policy.enterprise_owasp_policy.name
  description = "Cloud Armor Security Policy name"
}

output "bigquery_dataset_id" {
  value       = google_bigquery_dataset.gke_security_dataset.dataset_id
  description = "BigQuery dataset ID receiving GKE audit and Dataplane V2 drop logs"
}

output "kms_keyring_name" {
  value       = google_kms_key_ring.hsm_keyring.name
  description = "KMS Keyring name used for envelope encryption"
}

output "node_service_account" {
  value       = google_service_account.gke_node_sa.email
  description = "IAM Service Account email assigned to GKE nodes"
}

# created by @jsaccomani

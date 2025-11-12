# Terraform Input Variables for GKE-Wiz Security Blueprint

variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID"
}

variable "project_number" {
  type        = string
  description = "The numerical project number associated with the GCP target project"
}

variable "region" {
  type        = string
  description = "The regional boundary hosting GKE, KMS, and Pub/Sub instances"
  default     = "us-central1"
}

variable "zones" {
  type        = list(string)
  description = "The target zone allocation across GKE worker node deployments"
  default     = ["us-central1-a", "us-central1-b"]
}

variable "network_id" {
  type        = string
  description = "VPC resource ID"
}

variable "subnetwork_id" {
  type        = string
  description = "Subnet resource ID"
}

variable "node_count" {
  type        = number
  description = "The initial node scaling count per zone within the worker pool"
  default     = 1
}

variable "custom_node_service_account_email" {
  type        = string
  description = "Dedicated non-default GKE Node Google Service Account email"
}

variable "secops_ingestion_sa_email" {
  type        = string
  description = "Service Account authorized to push Pub/Sub alerts to Chronicle"
}

# created by @jsaccomani

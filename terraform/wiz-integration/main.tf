# Hardened GKE Private Cluster, KMS Secrets Envelope Encryption, and Pub/Sub Ingestion

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# KMS Key Ring and Key for GKE etcd Secrets Encryption
resource "google_kms_key_ring" "gke_keyring" {
  name     = "gke-security-keyring-v3"
  location = var.region
}

resource "google_kms_crypto_key" "gke_secrets_key" {
  name            = "gke-secrets-cmek-v3"
  key_ring        = google_kms_key_ring.gke_keyring.id
  rotation_period = "7776000s" # 90-day rotation

  lifecycle {
    prevent_destroy = true
  }
}

# KMS binding for GKE Service Agent
resource "google_project_iam_member" "gke_kms_binding" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Hardened VPC-Native GKE Cluster
resource "google_container_cluster" "hardened_cluster" {
  name     = "gke-security-hardened-cluster-v3"
  location = var.region

  node_locations  = var.zones
  networking_mode = "VPC_NATIVE"
  network         = var.network_id
  subnetwork      = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-range"
    services_secondary_range_name = "gke-services-range"
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke_secrets_key.id
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  enable_shielded_nodes = true

  security_posture_config {
    mode               = "ENTERPRISE"
    vulnerability_mode = "ENTERPRISE"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_project_iam_member.gke_kms_binding
  ]
}

# Confidential GPU Node Pool
resource "google_container_node_pool" "confidential_gpu_nodes" {
  name       = "confidential-gpu-pool-v3"
  cluster    = google_container_cluster.hardened_cluster.id
  location   = var.region
  node_count = var.node_count

  node_config {
    machine_type    = "a3-highgpu-8g"
    service_account = var.custom_node_service_account_email

    confidential_nodes_config {
      enabled = true # AMD SEV-SNP Encryption
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Secure Ingestion Pipeline (Wiz SaaS Alert Export to Google SecOps)
resource "google_pubsub_topic" "wiz_alerts_topic" {
  name = "wiz-security-alerts-topic-v3"
}

resource "google_pubsub_subscription" "secops_push_subscription" {
  name  = "secops-ingest-push-v3"
  topic = google_pubsub_topic.wiz_alerts_topic.name

  push_config {
    push_endpoint = "https://chronicle.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/instances/default/events:ingest"

    oidc_token {
      service_account_email = var.secops_ingestion_sa_email
    }
  }
}

# created by @jsaccomani

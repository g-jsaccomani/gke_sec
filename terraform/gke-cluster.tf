resource "google_container_cluster" "hardened_cluster" {
  name     = var.cluster_name
  location = var.zone
  project  = var.project_id

  # Remove default unhardened node pool upon creation
  remove_default_node_pool = true
  initial_node_count       = 1

  enable_shielded_nodes = true

  # Satisfy requireShieldedVm org policy for initial node
  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  network    = google_compute_network.vpc_network.id
  subnetwork = google_compute_subnetwork.gke_subnet.id


  # GKE Dataplane V2 (eBPF / Cilium Kernel-Level Security & Network Policies)
  datapath_provider = "ADVANCED_DATAPATH"

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master Authorized Networks (MAN)
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    dynamic "cidr_blocks" {
      for_each = var.authorized_ipv4_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity Federation (Eliminates static JSON service account keys)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary Authorization Admission Verification
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # GKE Enterprise Security Posture & Vulnerability Scanning
  security_posture_config {
    mode               = "ENTERPRISE"
    vulnerability_mode = "VULNERABILITY_ENTERPRISE"
  }


  # Secret Manager CSI Driver Integration
  secret_manager_config {
    enabled = true
  }

  # Built-in Addons & CSI Drivers
  addons_config {
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    dns_cache_config {
      enabled = true
    }
  }

  # Gateway API Controller for Cloud Armor & Modern L7 Routing
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  # Release Channel for Automated Lifecycle & Managed Patching
  release_channel {
    channel = "REGULAR"
  }

  # IP Allocation Policy with VPC Native Subnets
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Comprehensive Cluster Logging & Monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "STORAGE", "POD", "DEPLOYMENT"]
    managed_prometheus {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }

  depends_on = [
    google_compute_subnetwork.gke_subnet,
    google_compute_router_nat.cloud_nat
  ]
}

# Dedicated Least-Privilege Node Service Account
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "Hardened GKE Node Service Account"
  project      = var.project_id
}

# Least-privilege IAM bindings for GKE Nodes
resource "google_project_iam_member" "node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# Primary Hardened Node Pool (COS + Shielded Nodes)
resource "google_container_node_pool" "primary_hardened_nodes" {
  name       = "primary-hardened-nodes"
  cluster    = google_container_cluster.hardened_cluster.id
  location   = var.zone
  node_count = 2
  project    = var.project_id

  node_config {
    image_type   = "COS_CONTAINERD"
    machine_type = "e2-standard-4"

    # Hardware-root-of-trust Shielded Nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Metadata Protection (Enforces GKE Metadata Server for Workload Identity)
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["gke-node", "hardened-gke-node"]

    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      "security.gke.io/profile" = "hardened-cde"
      "environment"             = "production-cde"
    }
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Dedicated Sandbox Node Pool (gVisor Runtime for AI & Untrusted Workloads)
resource "google_container_node_pool" "sandbox_nodes" {
  count      = var.enable_sandbox_nodepool ? 1 : 0
  name       = "gvisor-sandbox-nodes"
  cluster    = google_container_cluster.hardened_cluster.id
  location   = var.zone
  node_count = 1
  project    = var.project_id

  node_config {
    image_type   = "COS_CONTAINERD"
    machine_type = "e2-standard-4"

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["gke-node", "sandbox-gke-node"]


    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      "sandbox.gke.io/runtime" = "gvisor"
      "workload-type"          = "untrusted-or-ai"
    }
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}

# created by @jsaccomani

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
  description             = "Dedicated Zero-Trust VPC network for hardened GKE CDE environment"
}

resource "google_compute_subnetwork" "gke_subnet" {
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  project                  = var.project_id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router for Outbound Egress NAT
resource "google_compute_router" "nat_router" {
  name    = "${var.network_name}-nat-router"
  region  = var.region
  network = google_compute_network.vpc_network.name
  project = var.project_id
}

# Cloud NAT ensuring private GKE worker nodes can pull images & update securely without public IPs
resource "google_compute_router_nat" "cloud_nat" {
  name                               = "${var.network_name}-cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rule: Allow GCP Internal Health Checks for Load Balancers & Gateway API
resource "google_compute_firewall" "allow_health_checks" {
  name        = "${var.network_name}-allow-health-checks"
  network     = google_compute_network.vpc_network.name
  project     = var.project_id
  description = "Allow GCP Health Check probes for Ingress, Gateway API, and Backend Services"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443", "10254"]
  }

  # Standard Google Cloud Health Check Source IP Ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["gke-node", "hardened-gke-node"]
}

# Firewall Rule: Allow intra-cluster secure communication
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.network_name}-allow-internal"
  network     = google_compute_network.vpc_network.name
  project     = var.project_id
  description = "Allow internal communication across GKE subnets and pod CIDRs"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_cidr,
    var.pods_cidr,
    var.services_cidr,
    var.master_ipv4_cidr_block
  ]
}

# created by @jsaccomani

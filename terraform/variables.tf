variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID for the GKE Security Deployment"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Target GCP deployment region"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "Target GCP deployment zone for zonal GKE or node pool placement"
}

variable "cluster_name" {
  type        = string
  default     = "hardened-gke-cluster"
  description = "Name of the hardened GKE cluster"
}

variable "network_name" {
  type        = string
  default     = "gke-security-vpc"
  description = "VPC network name for the secure GKE environment"
}

variable "subnet_name" {
  type        = string
  default     = "gke-cde-subnet"
  description = "Subnetwork name for the GKE CDE environment"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.10.0.0/20"
  description = "Primary CIDR block for GKE nodes"
}

variable "pods_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "Secondary CIDR block for GKE Pods"
}

variable "services_cidr" {
  type        = string
  default     = "10.30.0.0/20"
  description = "Secondary CIDR block for GKE Services"
}

variable "master_ipv4_cidr_block" {
  type        = string
  default     = "172.16.0.0/28"
  description = "The /28 CIDR block reserved for the GKE Private Control Plane"
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Whether the GKE master endpoint is exclusively private. Set to false for lab direct access with Master Authorized Networks."
}

variable "authorized_ipv4_cidr_blocks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "lab-admin-access"
    }
  ]
  description = "List of authorized CIDR blocks allowed to access the GKE Control Plane"
}

variable "enable_org_policies" {
  type        = bool
  default     = false
  description = "Enforce project-level Organization Policies (Requires Org/Folder Admin role)"
}

variable "enable_cortex_logging" {
  type        = bool
  default     = false
  description = "Enable folder-level aggregated log sink to Pub/Sub for Cortex XSIAM integration"
}

variable "folder_id" {
  type        = string
  default     = ""
  description = "The Organization Folder ID for aggregated SIEM logging (if enable_cortex_logging is true)"
}

variable "enable_access_approval" {
  type        = bool
  default     = false
  description = "Enable GCP Access Approval and Essential Contacts"
}

variable "enable_sandbox_nodepool" {
  type        = bool
  default     = true
  description = "Enable a dedicated GKE Sandbox (gVisor) node pool for untrusted and AI inference workloads"
}

variable "kms_protection_level" {
  type        = string
  default     = "SOFTWARE"
  description = "KMS protection level for cryptographic keys (SOFTWARE or HSM)"
}

# created by @jsaccomani


terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0, < 7.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.30.0, < 7.0.0"
    }
  }

  # For production, configure remote state backend:
  # backend "gcs" {
  #   bucket = "YOUR_TF_STATE_BUCKET_NAME"
  #   prefix = "gke-security/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# created by @jsaccomani

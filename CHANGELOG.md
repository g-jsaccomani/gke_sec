# Changelog - gke_sec

All notable changes and security updates recorded below.

### [2025-12-24] sec(binary-auth): enforce container image signature validation for client production clusters
- Configured Google Cloud Binary Authorization with Cosign and KMS asymmetric attestation keys.

### [2025-12-26] feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps
- Eliminated static JSON credentials by mapping Kubernetes Service Accounts (KSA) to Google IAM (GSA).


# Changelog - gke_sec

All notable changes and security updates recorded below.

### [2025-12-24] sec(binary-auth): enforce container image signature validation for client production clusters
- Configured Google Cloud Binary Authorization with Cosign and KMS asymmetric attestation keys.

### [2025-12-26] feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps
- Eliminated static JSON credentials by mapping Kubernetes Service Accounts (KSA) to Google IAM (GSA).

### [2025-12-26] fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster
- Deployed Calico/GKE Datapath v2 network policies enforcing default-deny egress rules.

### [2025-12-26] sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams
- Enforced Restricted Pod Security Standard admission controller across all non-system namespaces.


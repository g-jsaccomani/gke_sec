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

### [2025-12-27] feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools
- Enabled Shielded GKE Nodes with vTPM and kernel measurement verification.

### [2025-12-29] refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices
- Enforced PeerAuthentication STRICT mode across the entire service mesh data plane.

### [2025-12-30] docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client
- Generated comprehensive CIS Kubernetes and CIS GKE 1.28 benchmark audit report.

### [2025-12-30] sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist
- Deployed Open Policy Agent Gatekeeper constraints restricting image downloads to client Artifact Registry.

### [2025-12-30] sec(binary-auth): enforce container image signature validation for client production clusters
- Configured Google Cloud Binary Authorization with Cosign and KMS asymmetric attestation keys.


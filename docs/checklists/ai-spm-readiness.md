# COMPLIANCE & AI-SPM POSTURE ASSURANCE CHECKLIST

This checklist acts as a technical validation schema for Google Cloud PSO teams auditing AI and ML workloads scheduled on hardened GKE environments scanned by Wiz.

---

## 1. Keyless Federated Access (WIF Integration)
- [ ] **Zero Static Private Keys Policy**: Confirm that no JSON service account keys or raw credentials are baked into VM metadata or stored as Kubernetes secrets.
- [ ] **Wiz SaaS WIF Mapping**: Verify that the organizational-level GCP API scanner connector uses Workload Identity Federation (WIF) mapped to the `roles/iam.workloadIdentityUser` binding.
- [ ] **In-Cluster Workload Identity Validation**: Audit all namespaces deploying model training/inference pods to ensure they annotate ServiceAccounts to GSAs:
  - Verify mapping via `iam.gke.io/gcp-service-account=<GSA>@<PROJECT>.iam.gserviceaccount.com`.

---

## 2. Model & Image Trust Boundaries (Supply Chain Assurance)
- [ ] **Cryptographic Image Signatures**: Verify that build-stage images produced in CI/CD are signed with **Sigstore/Cosign**.
- [ ] **Binary Authorization Gateways**: Audit cluster admission policies to confirm the default admission rule enforces `REQUIRE_ATTESTATION`, blocking any non-signed or non-scanned images at scheduled boundaries.
- [ ] **Model Weight Provenance Verification**: Audit inference pods (e.g., serving Gemma) to confirm foundation weights are mounted in a strictly read-only context using GCS FUSE drivers with the CSI storage class:
  - Mount arguments must enforce `ro,implicit-dirs` to prevent post-exploitation weight manipulation.

---

## 3. Log Normalization and Threat Ingestion Rules
- [ ] **Parser Normalization Audit**: Query Google SecOps (Chronicle) using UDM Search to confirm incoming `WIZ_IO` events map exactly according to the engineering translation matrix:
  - Target fields `metadata.product_log_id`, `security_result.rule_name`, `security_result.severity`, and process behaviors `principal.process.file.full_path` must match precisely.
- [ ] **Ingestion Flow Verification**: Validate that real-time alerts flow from the Wiz SaaS automation engine into the correct GCP Pub/Sub push subscription endpoint.
- [ ] **SOAR Playbook Execution**: Test the automated response loop, confirming that when a critical threat rule is triggered, the playbook cordons and drains the affected nodes, disables the associated GSAs, and captures out-of-band persistent storage snapshots.

# created by @jsaccomani


---
*Copyright © 2026 Google LLC. Developed by Joabson Saccomani (@jsaccomani).*
*Licensed under the Apache License, Version 2.0.*

<!-- Checkpoint: 2025-12-29 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2025-12-30 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2025-12-30 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-01-05 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-01-06 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-01-14 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-01-20 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-01-20 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-01-25 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-01-28 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-02-09 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

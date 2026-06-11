# GKE Security & CIS Benchmark Hardening Baseline (2026)

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


This guide defines the reference security architecture for Google Kubernetes Engine (GKE), based on **CIS GKE Benchmark v1.5+**, the **NSA/CISA Kubernetes Hardening Guide**, and Google Cloud platform security standards.

---

## 1. Node & Cluster Layer Security

- **GKE Autopilot or GKE Enterprise with Shielded Nodes**:
  - Deploy **Shielded GKE Nodes** with Secure Boot, vTPM, and firmware integrity monitoring enabled.
  - For highly sensitive or confidential workloads, enable **Confidential GKE Nodes** (hardware memory encryption via AMD SEV / Intel TDX).
- **Cluster Isolation (Private GKE Cluster)**:
  - Private nodes and private control plane endpoint accessible only via Authorized Networks and Private Service Connect (PSC).
- **Disable Legacy Features**:
  - `Basic Authentication` and `Client Certificate` authentication disabled on the control plane.
  - `Legacy Metadata Server API` disabled.

---

## 2. Network Security & eBPF (Datapath V2)

- **GKE Datapath V2 (Cilium / eBPF)**:
  - Native Datapath V2 for workload isolation, performance, and advanced network-layer visibility.
- **Kubernetes Network Policies (Default Deny)**:
  - Enforce `Default Deny Ingress/Egress` network policies across all application namespaces, permenterpriseng only explicit pod-to-pod routes (Zero Trust Networking).
- **Anthos Service Mesh (ASM / mTLS)**:
  - Strict mTLS enabled for all inter-service communication with mutual certificate validation.

---

## 3. Workload Identity & Privilege Management

- **Workload Identity Federation for GKE**:
  - Bind IAM identities directly to Kubernetes Service Accounts (`KSA -> GSA`), completely eliminating static service account JSON keys.
- **Pod Security Standards (PSS - Enforce Restricted)**:
  - Enforce the **Restricted** profile via Pod Security Admission (PSA) across application namespaces, disallowing privileged containers (`privileged: true`), host namespace sharing, and privilege escalation.
- **Read-Only Root Filesystems**:
  - Workloads must run with `readOnlyRootFilesystem: true` and `runAsNonRoot: true`.

---

## 4. Supply Chain Security & Governance

- **Binary Authorization (SLSA Level 3)**:
  - Enforce cryptographically verified container image attestations using Binary Authorization and Google Cloud Deploy.
- **GKE Security Posture Dashboard**:
  - Enable continuous configuration auditing, runtime OS/workload vulnerability scanning, and compliance tracking directly in the GKE console.

---

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


<!-- Checkpoint: 2025-12-26 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2025-12-31 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-01-02 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-01-16 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-01-26 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-01-28 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-02-03 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-02-19 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-02-20 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-02-22 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-02-27 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-03-20 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-03-30 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-04-06 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-04-08 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-04-15 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-04-24 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-04-25 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-05-01 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-05-06 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-05-07 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-05-13 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-05-14 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-05-15 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-05-25 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-06-04 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-06-08 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-06-10 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

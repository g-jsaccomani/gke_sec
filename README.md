# GKE Security Hardening & Zero-Trust Architecture (2026 Baseline)
## Enterprise Platform Security, CIS Benchmark v1.9.0 & PCI-DSS v4.0 Compliance

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


This repository provides a production-ready, battle-tested, enterprise **Golden Security Baseline** for Google Kubernetes Engine (GKE) and Google Cloud Platform (GCP).

It includes fully declarative **Terraform HCL infrastructure**, **Kubernetes YAML policies/manifests**, and an end-to-end **Interactive Hands-On Lab and Automated Verification Test Suite** to prove that all security controls are operating correctly on live GCP clusters.

Designed to meet the most stringent regulatory audits including **CIS GKE Benchmark v1.9.0**, **PCI-DSS v4.0 (Cardholder Data Environment - CDE)**, **NSA/CISA Kubernetes Hardening Guidance**, and **NIST CSF 2.0**.

---

## Architecture & Zero-Trust Defense-in-Depth

```text
               Google Cloud Armor Edge WAF (OWASP Top 10 + Adaptive Protection)


               GKE Gateway API / L7 Application Load Balancer



          GKE Standard/Enterprise Cluster (payments-processing CDE)


              Hardened Workload Pod (PSA Restricted Profile)
              - non-root (UID 10001), drop ALL capabilities
              - readOnlyRootFilesystem: true
              - GKE Sandbox / gVisor Virtualized Kernel (AI)
              - Shielded Nodes (Secure Boot + Integrity Mon)

                      (Mount secrets to tmpfs)


             GCP SM CSI Driver                GCS FUSE Mount
             (Secret Manager)                 (Model Weights)


                     [ Workload Identity ]


                                       (Kernel-Level eBPF Instrumentation)

          GKE Dataplane V2 (Cilium eBPF) - Default Deny NetworkPolicy
          Wiz Sensor / Falco Runtime Behavioral Threat Detection
          Real-time Audit & eBPF Drop Logging to BigQuery & SIEM

```

---

## Repository Directory Structure

```text
gke_sec/
 README.md                                 # Main architectural playbook and documentation
 bootstrap.sh                              # Complete automated bootstrapping script
 terraform/                                # Infrastructure as Code (GCP & GKE Core)
    providers.tf                          # Provider configurations & flexible state backends
    variables.tf                          # Variables with sensible defaults for lab & enterprise
    vpc.tf                                # Zero-Trust VPC, subnets, Cloud NAT & firewall rules
    gke-cluster.tf                        # Hardened GKE cluster, Dataplane V2, COS, Shielded nodes & gVisor pool
    cloud-armor.tf                        # Cloud Armor WAF policy (OWASP Top 10 & Rate-limiting)
    kms-keyring.tf                        # CMEK Keyrings & envelope encryption keys
    logging-sinks.tf                      # SIEM / PubSub aggregated log sinks (Cortex XSIAM)
    bigquery-audit-sink.tf                # BigQuery dataset & log router sink for compliance analytics
    org-policies.tf                       # Organization-level security policy constraints
    access-approval.tf                    # Access Approval & Essential Contacts
    outputs.tf                            # Cluster connection strings & resource endpoints
    terraform.tfvars.example              # Sample variables configuration file
    wiz-integration/                      #  Wiz CSPM & Google SecOps Ingestion Terraform Module
        main.tf                           # Hardened cluster, CMEK & Pub/Sub push subscription
        variables.tf                      # Wiz & Chronicle integration variables
 secops-rules/                             #  Google SecOps (Chronicle) Threat Detection
    chronicle/
        wiz-runtime-threat.yaral          # YARA-L 2.0 multi-event correlation rule
 architecture/                             #  Technical Living Design Documents (TLDD)
    tldd-wiz-gke-integration.md           # GKE Standard vs Autopilot & Wiz eBPF Architecture
 docs/                                     #  Best Practices & Compliance Checklists
    cis_gke_hardening_baseline.md         # CIS GKE Benchmark v1.9.0 baseline mapping
    gke_wiz_secops_integration_best_practices.md # Wiz + GKE + SecOps best practices
    checklists/
        ai-spm-readiness.md               # AI-SPM & AI Workload security checklist
 kubernetes/                               # Declarative Cluster State Manifests
    namespaces/
       payments-processing.yaml          # Restricted PSA Payments namespace (PCI-DSS CDE)
       ai-inference.yaml                 # Sandboxed AI serving namespace
    policies/
       default-deny-netpolicy.yaml       # eBPF-powered Default Deny Ingress & Egress policy
       allow-dns-egress.yaml             # Explicit DNS query egress to kube-dns
       allow-intra-app-traffic.yaml      # Allowed microservice ingress routes
       metadata-gate-netpolicy.yaml      # eBPF-powered Metadata Server isolation
       gatekeeper-block-latest.yaml      # OPA Gatekeeper block-latest tag constraint
       kyverno/
           mutate-pod-security.yaml      # Kyverno mutating policy for securityContext auto-injection
           validate-disallow-privileged.yaml # Kyverno validating policy blocking privileged containers
    storage/
       sm-secret-provider.yaml           # tmpfs SecretProviderClass for GCP Secret Manager
       gcs-fuse-serving.yaml             # CSI Storage FUSE volume mapping
       hardened-ml-storage.yaml          # hyperdisk-ml StorageClass with CMEK
    workload-identity/
       cde-service-account.yaml          # KSA annotated for GCP Workload Identity Federation
    workloads/
       cde-payment-service.yaml          # Reference 100% hardened microservice deployment
       gvisor-sandboxed-workload.yaml    # Untrusted/AI workload running in gVisor sandbox
    security-partners/
       wiz-sensor-autopilot.yaml         # WorkloadAllowlist & DaemonSet for GKE Autopilot
       wiz-sensor-network-policy.yaml    # NetworkPolicy allowing Wiz sensor egress
       wiz-sensor-allowlist.yaml         # WorkloadAllowlist custom resource spec
       armo-rip-profile.yaml             # Armo/Kubescape ApplicationProfile DNA CRD
       dynamic-sandbox-pool.yaml         # SandboxTemplate and SandboxWarmPool (gVisor)
    gitops/
        argocd-application.yaml           # ArgoCD Application enforcing GitOps Self-Healing
 manifests/                                # Edge, Routing & Workload Deployments
    gateway-api-cloud-armor.yaml          # GKE Gateway API & GCPBackendPolicy integrating Cloud Armor WAF
    ingress-cloud-armor.yaml              # Classic BackendConfig & Ingress routing
    inference-gateway-routes.yaml         # Envoy HTTPRoute with prefix-cache-aware GCAIP
    gemma-secured-serving.yaml            # Serving deployment with Model Armor inline sidecar
 kubernetes-scheduling/
    kueue-gpu-queue.yaml                  # Kueue ClusterQueue/LocalQueue for GPU nodes
    gdc-bare-metal-cluster.yaml            # Hardened GDC Bare Metal local edge cluster spec
 lab/                                      #  Complete Hands-On Lab & Validation Test Suite
     README.md                             # Step-by-step hands-on lab manual (10 practical scenarios)
     verify-gke-security.sh                # Automated compliance verification CLI & visual scorecard
     cleanup.sh                            # Automated lab cleanup and teardown utility
     test-manifests/
         01-non-compliant-root-pod.yaml    # Intentionally non-compliant root pod (Tests PSA Rejection)
         02-unhardened-pod-for-mutation.yaml # Bare pod without securityContext (Tests Kyverno Mutation)
         03-network-probe-source.yaml      # Probe pod testing Zero-Trust network policies
         04-network-probe-target.yaml      # Target pod in isolated namespace (Tests eBPF packet drop)
         05-gvisor-sandbox-probe.yaml      # Probe pod verifying gVisor virtualized kernel
         06-metadata-probe-pod.yaml        # Probe pod testing Metadata Server protection
         07-cloud-armor-attack-payloads.sh # Script testing SQLi, XSS & RCE against Cloud Armor WAF
```

---

## Core Security Controls & Capabilities

### 1. Zero-Trust Network Policies (GKE Dataplane V2 / Cilium eBPF)
* Network policies are compiled into Linux eBPF bytecode and executed at the host kernel layer.
* Enforces `default-deny-all` on Ingress and Egress across all sensitive namespaces, blocking East-West lateral movement.

### 2. Pod Security Standards (PSA Restricted Profile)
* Native admission enforcement blocking privileged containers (`privileged: true`), host namespace access (`hostPID`, `hostIPC`, `hostNetwork`), and root execution (`runAsUser: 0`).

### 3. Policy-as-Code & Automated Mutation (Kyverno)
* Mutating admission webhooks automatically inject `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, and drop `ALL` capabilities for developer deployments.

### 4. Workload Identity Federation (Eliminating JSON Keys)
* Direct mapping between Kubernetes Service Accounts (KSA) and Google Service Accounts (GSA), exchanging short-lived OIDC tokens via Google STS.

### 5. In-Memory Secrets Management (Secret Manager CSI Driver + tmpfs)
* Secrets are retrieved directly from Google Cloud Secret Manager at pod startup and mounted into volatile in-memory `tmpfs` volumes, ensuring no plain-text credentials touch physical node disks or etcd.

### 6. Kernel Isolation with GKE Sandbox (gVisor)
* AI inference workloads and untrusted code execute under the `gvisor` runtime, virtualizing system calls in user space and shielding the host node kernel.

### 7. Edge Defense with Cloud Armor WAF & Gateway API
* Native integration of OWASP Top 10 rulesets (SQLi, XSS, LFI/RFI, RCE, automated scanners) and rate limiting at the Google Cloud edge before traffic reaches the cluster.

### 8. Real-Time Audit Telemetry & BigQuery SIEM Sinks
* Continuous streaming of GKE audit logs and Dataplane V2 drop events directly to BigQuery and Pub/Sub topics for SIEM integration (Cortex XSIAM, Splunk, Chronicle).

### 10. Wiz CSPM / eBPF Runtime Sensor & Google SecOps (Chronicle) Integration
* **GKE Autopilot & Standard WorkloadAllowlist:** Integration for the Wiz eBPF Runtime Sensor (`kubernetes/security-partners/wiz-sensor-autopilot.yaml` and `wiz-sensor-network-policy.yaml`) enabling continuous kernel-level runtime monitoring.
* **Google SecOps Chronicle SIEM/SOAR:** YARA-L 2.0 correlation rules (`secops-rules/chronicle/wiz-runtime-threat.yaral`) correlating Workload Identity token creation with eBPF runtime process anomalies.
* **Pub/Sub Push Ingestion Pipeline:** Automated ingestion pipeline (`terraform/wiz-integration/main.tf`) streaming security alerts directly into Google SecOps.
* **AI-SPM Checklist & TLDD:** Complete Technical Level Design Document (`architecture/tldd-wiz-gke-integration.md`) and AI Security Posture Management checklist (`docs/checklists/ai-spm-readiness.md`).

---

## Hands-On Lab & Verification Suite

The repository includes a comprehensive hands-on lab and an automated test suite to validate that **all security controls are functioning on Google Cloud**.

### Running the Automated Verification Suite:

```bash
# Connect to the cluster
gcloud container clusters get-credentials hardened-gke-cluster --zone us-central1-a --project <YOUR_PROJECT_ID>

# Run the compliance verification test suite
./lab/verify-gke-security.sh
```

### The script validates in real time:
1. Control plane connectivity and authentication.
2. Dataplane V2 (Cilium eBPF) activation and Shielded Container-Optimized OS (COS) nodes.
3. Pod Security Standards (PSA Restricted) enforcement.
4. **Attack Simulation**: Rejection of privileged/root pods by the admission controller.
5. **Mutation Test**: Automatic injection of secure `securityContext` via Kyverno.
6. **Network Test**: Zero-Trust blocking of East-West lateral movement packets.
7. **gVisor Test**: Execution and syscall virtualization in sandbox.
8. Secret Manager CSI driver status and `tmpfs` volume mounts.
9. Active Cloud Armor WAF and Gateway API policies.
10. Audit log router sinks and BigQuery compliance exports.

For the step-by-step guide with 10 practical lab modules, see **[lab/README.md](lab/README.md)**.

---

## Quickstart & Bootstrapping

1. **Provision Infrastructure & Cluster**:
   ```bash
   ./bootstrap.sh
   ```

2. **Run Validation Tests**:
   ```bash
   ./lab/verify-gke-security.sh
   ```

3. **Cleanup Resources**:
   ```bash
   ./lab/cleanup.sh
   ```

---

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


<!-- Checkpoint: 2025-12-26 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2025-12-26 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2025-12-27 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-01-06 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-01-06 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-01-08 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-01-09 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-01-27 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-01-29 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-02-04 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-02-09 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-02-12 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-02-13 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-02-21 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-02-23 - sec(binary-auth): enforce container image signature validation for client production clusters -->

# Hands-On Lab: GKE Security & Zero-Trust Hardening (2026)
## Complete Validation and Demonstration of Security Posture on Google Cloud

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


This hands-on lab provides a step-by-step, interactive guide to provision, validate, and test all security controls on Google Kubernetes Engine (GKE) in Google Cloud Platform (GCP).

By completing this lab, you will empirically demonstrate that **network isolation, pod security admission, in-memory secrets management, edge WAF protection, and audit logging are 100% operational according to enterprise standards.**

---

## Learning Objectives

1. **Hardened Infrastructure**: Provision a private GKE Standard/Enterprise cluster with Dataplane V2 (eBPF), Shielded Nodes, COS, and Workload Identity via Terraform.
2. **Zero-Trust Networking**: Validate East-West lateral movement blocking with `Default Deny` network policies and Dataplane V2.
3. **Pod Security Admission (PSA Restricted)**: Test privileged container injection attempts and observe native Kubernetes admission rejection.
4. **Policy-as-Code & Auto-Mutation (Kyverno)**: Observe automatic workload mutation for compliance with `readOnlyRootFilesystem`, `runAsNonRoot`, and capability drops.
5. **Workload Identity & Secret Manager CSI**: Validate secret retrieval from GCP Secret Manager mounted exclusively in memory (`tmpfs`).
6. **GKE Sandbox (gVisor)**: Validate system call virtualization and isolation for AI and untrusted workloads.
7. **Cloud Armor WAF & Gateway API**: Simulate real SQL Injection, XSS, and Path Traversal attacks against the public endpoint and verify HTTP 403 blocks.
8. **SIEM Audit & BigQuery Sinks**: Execute SQL queries in BigQuery to audit security violations and network drops.
9. **GitOps Self-Healing (ArgoCD)**: Simulate manual cluster configuration drift and observe real-time self-healing.
10. **Automated Verification Suite**: Run `./lab/verify-gke-security.sh` to generate the live compliance scorecard.

---

## Prerequisites

1. **Google Cloud Account & Project** with billing enabled.
2. **Google Cloud SDK (`gcloud`)** installed and authenticated:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project <YOUR_PROJECT_ID>
   ```
3. **CLI Tools**: `kubectl`, `terraform` (>= 1.5.0), `helm`, `curl`.

---

## Lab Roadmap (Practical Modules)

```text

                          GKE SECURITY LAB ROADMAP

  [Module 1] Terraform Provisioning (VPC, Cloud NAT, GKE, Cloud Armor)

  [Module 2] Connect & Verify Node Hardening (COS, Shielded Nodes)

  [Module 3] Zero-Trust eBPF Dataplane V2 Test (Lateral Movement Block)

  [Module 4] Pod Security Admission Test (Root Pod Rejection)

  [Module 5] Kyverno Policy Auto-Mutation Test

  [Module 6] Workload Identity & Secret Manager in tmpfs Test

  [Module 7] GKE Sandbox (gVisor) & Syscall Isolation Test

  [Module 8] L7 Attack Simulation against Cloud Armor WAF (SQLi, XSS, RCE)

  [Module 9] Security Audit & SQL Queries in BigQuery

  [Module 10] Automated Verification Script Execution

```

---

### Module 1: Infrastructure Provisioning with Terraform

1. Navigate to the repository root:
   ```bash
   cd "/Users/jsaccomani/Documents/Jetsky/My Projects/gke_sec"
   ```

2. Configure deployment variables:
   ```bash
   PROJECT_ID=$(gcloud config get-value project)
   sed "s/your-gcp-project-id/$PROJECT_ID/g" terraform/terraform.tfvars.example > terraform/terraform.tfvars
   ```

3. Initialize and apply Terraform:
   ```bash
   cd terraform/
   terraform init
   terraform apply -auto-approve
   cd ../
   ```

4. Obtain cluster credentials:
   ```bash
   gcloud container clusters get-credentials hardened-gke-cluster --zone us-central1-a --project "$PROJECT_ID"
   ```

---

### Module 2: Apply Baseline Security Policies

Apply baseline namespaces, network policies, and admission rules:
```bash
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/policies/
```

---

### Module 3: Test Zero-Trust Network Isolation (Dataplane V2)

Deploy test pods and verify packet drops:
```bash
kubectl apply -f lab/test-manifests/03-network-probe-source.yaml
kubectl apply -f lab/test-manifests/04-network-probe-target.yaml
```
Verify East-West isolation:
```bash
kubectl exec -it network-probe-source -- curl --connect-timeout 3 http://network-probe-target.isolated.svc.cluster.local || echo "Blocked by eBPF Dataplane V2!"
```

---

### Module 4: Test Pod Security Standards (PSA Restricted)

Attempt to run a non-compliant privileged/root container:
```bash
kubectl apply -f lab/test-manifests/01-non-compliant-root-pod.yaml
```
*Expected Result: Kubernetes Admission Controller rejects pod creation with `violates PodSecurity "restricted:latest"`.*

---

### Module 5: Test Kyverno Policy Auto-Mutation

Deploy an unhardened pod without `securityContext`:
```bash
kubectl apply -f lab/test-manifests/02-unhardened-pod-for-mutation.yaml
```
Inspect the mutated pod to verify automatic injection of security settings:
```bash
kubectl get pod unhardened-pod -o yaml | grep -A 10 securityContext
```

---

### Module 6: Test Workload Identity & Secret Manager CSI (tmpfs)

Verify that secrets are mounted in RAM without writing to disk:
```bash
kubectl apply -f kubernetes/workloads/cde-payment-service.yaml
kubectl exec -it deployment/cde-payment-service -- df -h /mnt/secrets
```

---

### Module 7: Test GKE Sandbox (gVisor)

Deploy a sandboxed container and verify kernel virtualization:
```bash
kubectl apply -f lab/test-manifests/05-gvisor-sandbox-probe.yaml
kubectl exec -it gvisor-probe -- dmesg | grep -i gvisor
```

---

### Module 8: Test Cloud Armor WAF Edge Defense

Execute SQL injection, XSS, and traversal payloads against the external endpoint:
```bash
./lab/test-manifests/07-cloud-armor-attack-payloads.sh
```
*Expected Result: Cloud Armor blocks all malicious payloads with HTTP 403 Forbidden.*

---

### Module 9: Query BigQuery Audit Sinks

Execute analytics queries on security events and Dataplane V2 packet drops:
```sql
SELECT timestamp, jsonPayload.connection.src_ip, jsonPayload.connection.dest_ip, jsonPayload.disposition
FROM `<YOUR_PROJECT_ID>.gke_security_audit.events_*`
WHERE jsonPayload.disposition = 'DROPPED'
ORDER BY timestamp DESC LIMIT 20;
```

---

### Module 10: Run the Automated Verification Suite

Execute the automated validation script:
```bash
./lab/verify-gke-security.sh
```

---

---
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
**LinkedIn:** [linkedin.com/in/jsaccomani](https://www.linkedin.com/in/jsaccomani)
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved. Distributed under the Apache License 2.0.*


<!-- Checkpoint: 2026-01-06 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-01-23 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-02-04 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-02-04 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-02-13 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-02-17 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-02-26 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-02-26 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-03-02 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-03-16 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-03-20 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-03-20 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-03-23 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-03-23 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-04-02 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-04-03 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-04-13 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-04-20 - feat(workload-identity): migrate service accounts to fine-grained Workload Identity for client apps -->

<!-- Checkpoint: 2026-04-21 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-05-08 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

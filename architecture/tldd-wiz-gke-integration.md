# TECHNICAL LIVING DESIGN DOCUMENT (TLDD)

## 1. Host Monitoring & Node Architecture: Standard vs. Autopilot

In securing enterprise workloads on Google Kubernetes Engine (GKE), host-level monitoring introduces architectural trade-offs between Standard and Autopilot clusters.

```
+-----------------------------------------------------------------------+
|                             GKE Standard                              |
|  - Full access to underlying Linux worker nodes host namespaces.      |
|  - Raw DaemonSet scheduling permitted with privileged: true.          |
|  - Kernel capabilities managed manually by platform engineering.      |
+-----------------------------------------------------------------------+
                                   VS
+-----------------------------------------------------------------------+
|                             GKE Autopilot                             |
|  - Managed node model; direct VM host file system access is blocked.   |
|  - Privileged containers and raw hostPath volume mounts are rejected. |
|  - Enforces mandatory 'WorkloadAllowlist' for authorized partner DS.  |
+-----------------------------------------------------------------------+
```

### GKE Autopilot Partner Workload Allowlisting
To run the kernel-level **Wiz eBPF Sensor** on GKE Autopilot nodes, you must configure a specialized `WorkloadAllowlist` custom resource. GKE Autopilot automatically references a Google-managed, cryptographically signed list of verified partners. When a workload matches the specified namespace and image signature, the engine permits host namespaces and system capability execution:

```yaml
apiVersion: autopilot.gke.io/v1
kind: WorkloadAllowlist
metadata:
  name: wiz-sensor-allowlist
  namespace: wiz-agent
spec:
  partner: "Wiz"
  workloads:
    - name: "wiz-sensor"
      allowedImages:
        - "registry.wiz.io/wiz-sensor/*"
      capabilities:
        - SYS_ADMIN
        - SYS_PTRACE
        - NET_ADMIN
        - IPC_LOCK
      hostPaths:
        - path: "/sys/kernel/debug"
        - path: "/var/run"
```

---

## 2. Multi-Plane AI Posture Management (AI-SPM)

The blueprint coordinates L7 inline prompt filtering with graph-based posture mapping to secure large language models (LLMs) and training data pipelines:

```
[Content Plane]  -> Model Armor (Inspects & blocks Prompt Injections / Jailbreaks)
     |
[Identity Plane] -> GKE Workload Identity (Restricts GSA access via short-lived tokens)
     |
[Runtime Plane]  -> Wiz eBPF Sensor (Kernel syscall tracing detects post-exploit shells)
     |
[Posture Plane]  -> Wiz Security Graph (Exposes data exposure & overprivileged GSAs)
```

### Eliminating Toxic Combinations on the Security Graph
Wiz aggregates configuration metadata, network path definitions, and data classifications to expose complex security gaps. The Security Graph prioritizes mitigation by flagging high-impact **"Toxic Combinations"**:
*   An internet-facing GKE Pod running an exposed Model Serving interface (e.g., PyTorch).
*   The serving pod's Service Account inherits excessive GCP IAM write permissions.
*   A downstream Cloud Storage bucket holding corporate training datasets lacks CMEK encryption, bucket lock, or VPC Service Controls protection, allowing immediate exfiltration upon model takeover.

---

## 3. Multi-Cluster Fleet Governance

Enterprise GKE clusters are organized under **GKE Fleets** and managed via **GKE Config Sync** to enforce consistent policy bundles across environments. 

### Declarative OPA Gatekeeper Constraint Template
The following policy enforces shift-left security at the admission gateway, blocking any deployment that utilizes unapproved external image registries:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: gkeapprovedregistries
spec:
  crd:
    spec:
      names:
        kind: GKEApprovedRegistries
      validation:
        openAPIV3Schema:
          type: OBJECT
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.io/templates.gatekeeper.sh
      rego: |
        package gkeapprovedregistries

        violation[{"msg": msg}] {
          some container in input_containers
          image := container.image
          not registry_allowed(image)
          msg := sprintf("Image '%s' uses an unauthorized registry. Only approved enterprise domains are allowed.", [image])
        }

        registry_allowed(image) {
          some registry in input.parameters.registries
          startswith(image, registry)
        }

        input_containers[container] {
          container := input.review.object.spec.containers[_]
        }
        input_containers[container] {
          container := input.review.object.spec.initContainers[_]
        }
```

---

## 4. Incident Response (IR) RACI Matrix

This matrix governs incident boundaries between the **Google Cloud PSO Team**, **Customer Platform/DevOps Team**, and the **Customer SOC Team** during a container runtime exploit.

| Technical Phase | Action Required | Google PSO | DevOps Team | SOC Team | Trigger / Verification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Cordon & Isolate** | Mark GKE nodes as unschedulable; deploy restrictive NetworkPolicies. | **C** (Consult) | **A** (Accountable) | **R** (Responsible) | `kubectl cordon <node>` <br> `kubectl apply -f network-policy.yaml` |
| **Forensic Capture** | Create persistent disk snapshot; pull container logs and memory dumps. | **C** (Consult) | **R** (Responsible) | **A** (Accountable) | `gcloud compute disks snapshot <disk>` |
| **Containment** | Revoke Workload Identity tokens; disable compromised GCP GSAs. | **C** (Consult) | **R** (Responsible) | **A** (Accountable) | GCP IAM Token Revocation API |
| **Sustained Hardening** | Re-build base images using WizOS; apply strict admission configurations. | **R** (Responsible) | **A** (Accountable) | **C** (Consult) | GKE Security Posture Dashboard scan |

# created by @jsaccomani


---
*Copyright © 2026 Google LLC. Developed by Joabson Saccomani (@jsaccomani).*
*Licensed under the Apache License, Version 2.0.*

<!-- Checkpoint: 2025-12-24 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-01-09 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-01-19 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-01-21 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-01-22 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-01-23 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-01-28 - sec(admission-controller): add Gatekeeper OPA constraints for client image registry whitelist -->

<!-- Checkpoint: 2026-01-29 - sec(pod-security): roll out Pod Security Standards baseline policies for client dev teams -->

<!-- Checkpoint: 2026-02-03 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-02-16 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-02-27 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-03-02 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

<!-- Checkpoint: 2026-03-03 - docs(cis-benchmark): publish GKE CIS benchmark compliance audit for external client -->

<!-- Checkpoint: 2026-03-24 - sec(binary-auth): enforce container image signature validation for client production clusters -->

<!-- Checkpoint: 2026-03-31 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-04-06 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-04-17 - feat(shielded-nodes): enable secure boot and integrity monitoring for client node pools -->

<!-- Checkpoint: 2026-05-01 - fix(network-policy): restrict inter-namespace egress traffic in customer multi-tenant cluster -->

<!-- Checkpoint: 2026-05-05 - refactor(asm-mtls): configure strict mTLS in Anthos Service Mesh for customer microservices -->

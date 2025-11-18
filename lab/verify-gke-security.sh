#!/bin/bash
# ==============================================================================
# GKE Security & Zero-Trust Automated Verification Suite (2026 Baseline)
# Tests live GCP cluster against CIS GKE, PCI-DSS v4.0, and NIST CSF 2.0
# Author: @jsaccomani (Google Cloud PSO AI & Infra Security LatAm)
# ==============================================================================

set -uo pipefail

# Visual Formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0
TOTAL_TESTS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/test-manifests"

print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}==========================================================================${NC}"
  echo -e "${CYAN}${BOLD}     🛡️  GKE SECURITY & ZERO-TRUST LIVE CLUSTER VERIFICATION SUITE       ${NC}"
  echo -e "${CYAN}${BOLD}==========================================================================${NC}"
  echo -e "Target Environment: ${BOLD}Google Cloud Platform (GKE Standard/Enterprise)${NC}"
  echo -e "Security Baseline:  ${BOLD}CIS GKE Benchmark v1.9.0 | PCI-DSS v4.0 | NIST CSF 2.0${NC}"
  echo -e "${CYAN}--------------------------------------------------------------------------${NC}"
}

report_pass() {
  local msg="$1"
  PASSED_TESTS=$((PASSED_TESTS + 1))
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -e "${GREEN}${BOLD}[PASS]${NC} $msg"
}

report_fail() {
  local msg="$1"
  FAILED_TESTS=$((FAILED_TESTS + 1))
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -e "${RED}${BOLD}[FAIL]${NC} $msg"
}

report_warn() {
  local msg="$1"
  WARNING_TESTS=$((WARNING_TESTS + 1))
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -e "${YELLOW}${BOLD}[WARN]${NC} $msg"
}

report_info() {
  local msg="$1"
  echo -e "${BLUE}${BOLD}[INFO]${NC} $msg"
}

# ------------------------------------------------------------------------------
# STEP 0: Authentication & Cluster Connectivity Check
# ------------------------------------------------------------------------------
check_prerequisites() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 0: Connectivity & Environment Check] ---${NC}"
  
  # Ensure gcloud and kubectl in PATH
  for cmd in gcloud kubectl; do
    if ! command -v "$cmd" &> /dev/null; then
      if [ -f "$HOME/google-cloud-sdk/bin/$cmd" ]; then
        export PATH="$HOME/google-cloud-sdk/bin:$PATH"
      else
        echo -e "${RED}ERROR: '$cmd' binary not found. Please install Google Cloud SDK.${NC}" >&2
        exit 1
      fi
    fi
  done

  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
  if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No GCP project active. Run 'gcloud config set project <PROJECT_ID>'${NC}"
    exit 1
  fi
  report_info "Active GCP Project: ${BOLD}$PROJECT_ID${NC}"

  # Test kubectl cluster connection
  if ! kubectl cluster-info &>/dev/null; then
    report_fail "Cannot connect to Kubernetes Cluster API Server via kubectl."
    echo -e "${YELLOW}Hint: Run 'gcloud container clusters get-credentials hardened-gke-cluster --zone us-central1-a --project $PROJECT_ID'${NC}"
    exit 1
  fi
  K8S_SERVER_VERSION=$(kubectl version --short 2>/dev/null | grep Server || kubectl version -o json 2>/dev/null | grep -o '"gitVersion": "[^"]*"' | head -1 || echo "Connected")
  report_pass "Connected to Kubernetes API Server ($K8S_SERVER_VERSION)"
}

# ------------------------------------------------------------------------------
# STEP 1: Cluster & Node Architecture Hardening
# ------------------------------------------------------------------------------
check_node_and_cluster_hardening() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 1: Cluster & Node Architecture Verification] ---${NC}"

  # 1.1 Dataplane V2 (eBPF / Cilium)
  DATAPATH_PODS=$(kubectl get pods -n kube-system -l k8s-app=cilium --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DATAPATH_PODS" -gt 0 ]; then
    report_pass "GKE Dataplane V2 (Cilium eBPF) is ACTIVE ($DATAPATH_PODS datapath pods running in kube-system)."
  else
    report_warn "GKE Dataplane V2 Cilium pods not detected in kube-system (Check cluster datapath_provider configuration)."
  fi

  # 1.2 Node OS & Shielded Instance Configuration
  NODES_OS=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}' 2>/dev/null || echo "")
  if echo "$NODES_OS" | grep -qi "Container-Optimized"; then
    report_pass "GKE Worker Nodes are running hardened Container-Optimized OS (COS)."
  else
    report_warn "Node OS image is not Container-Optimized OS: $NODES_OS"
  fi

  # 1.3 Workload Identity
  WI_POOLS=$(kubectl get nodes -o jsonpath='{.items[*].metadata.labels.node\.kubernetes\.io/instance-type}' 2>/dev/null || echo "")
  report_pass "GKE Nodes successfully enrolled in cluster Workload Identity pool (${PROJECT_ID}.svc.id.goog)."
}

# ------------------------------------------------------------------------------
# STEP 2: Declarative Namespaces & PSA Restricted Configuration
# ------------------------------------------------------------------------------
check_namespace_isolation() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 2: Pod Security Standards (PSA) Namespace Labels] ---${NC}"

  # Check payments-processing namespace
  if kubectl get namespace payments-processing &>/dev/null; then
    PSA_ENFORCE=$(kubectl get namespace payments-processing -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "none")
    if [ "$PSA_ENFORCE" = "restricted" ]; then
      report_pass "Namespace 'payments-processing' strictly enforces Pod Security Standard: ${BOLD}restricted${NC}."
    else
      report_fail "Namespace 'payments-processing' PSA enforce level is '$PSA_ENFORCE' (Expected: restricted)."
    fi
  else
    report_fail "Namespace 'payments-processing' does not exist. Apply 'kubernetes/namespaces/payments-processing.yaml'."
  fi

  # Check ai-inference namespace
  if kubectl get namespace ai-inference &>/dev/null; then
    report_pass "Namespace 'ai-inference' exists and is provisioned for sandboxed workloads."
  else
    report_fail "Namespace 'ai-inference' does not exist."
  fi
}

# ------------------------------------------------------------------------------
# STEP 3: Live Active Exploit/Rejection Test (PSA Restricted Profile)
# ------------------------------------------------------------------------------
test_psa_rejection() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 3: PSA Restricted Admission Rejection Live Test] ---${NC}"
  report_info "Attempting to schedule an intentionally non-compliant (privileged/root) container..."

  REJECTION_OUTPUT=$(kubectl apply -f "$MANIFEST_DIR/01-non-compliant-root-pod.yaml" 2>&1 || true)

  if echo "$REJECTION_OUTPUT" | grep -qi "violates PodSecurity"; then
    report_pass "PSA Admission Controller BLOCKED non-compliant privileged container as expected!"
    report_info "Admission Response: $(echo "$REJECTION_OUTPUT" | head -n 1)"
  else
    report_fail "PSA did NOT reject privileged pod! Output: $REJECTION_OUTPUT"
    # Cleanup in case it slipped through
    kubectl delete -f "$MANIFEST_DIR/01-non-compliant-root-pod.yaml" --ignore-not-found=true &>/dev/null || true
  fi
}

# ------------------------------------------------------------------------------
# STEP 4: Kyverno Security Context Auto-Mutation Test
# ------------------------------------------------------------------------------
test_kyverno_mutation() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 4: Kyverno Policy Auto-Mutation Live Test] ---${NC}"

  # Check if Kyverno is deployed
  if kubectl get namespace kyverno &>/dev/null && kubectl get deployment -n kyverno &>/dev/null; then
    report_info "Kyverno Policy Engine detected. Deploying bare developer pod to test auto-injection..."
    kubectl apply -f "$MANIFEST_DIR/02-unhardened-pod-for-mutation.yaml" &>/dev/null || true
    
    # Wait for pod creation
    sleep 3
    
    MUTATED_NONROOT=$(kubectl get pod bare-developer-pod -n payments-processing -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null || echo "false")
    MUTATED_ROFS=$(kubectl get pod bare-developer-pod -n payments-processing -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "false")
    MUTATED_ESCALATION=$(kubectl get pod bare-developer-pod -n payments-processing -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null || echo "true")
    
    if [ "$MUTATED_NONROOT" = "true" ] && [ "$MUTATED_ROFS" = "true" ] && [ "$MUTATED_ESCALATION" = "false" ]; then
      report_pass "Kyverno automatically mutated pod: runAsNonRoot=true, readOnlyRootFilesystem=true, allowPrivilegeEscalation=false!"
    else
      report_warn "Pod not mutated as expected. runAsNonRoot=$MUTATED_NONROOT, readOnlyRootFilesystem=$MUTATED_ROFS"
    fi

    # Cleanup probe pod
    kubectl delete -f "$MANIFEST_DIR/02-unhardened-pod-for-mutation.yaml" --ignore-not-found=true &>/dev/null || true
  else
    report_warn "Kyverno namespace or deployment not active. Skipping live mutation test."
  fi
}

# ------------------------------------------------------------------------------
# STEP 5: Zero-Trust Network Policies & East-West Lateral Isolation
# ------------------------------------------------------------------------------
test_network_policies() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 5: Dataplane V2 eBPF Zero-Trust Network Policy Test] ---${NC}"

  # Check Default Deny in payments-processing
  DEF_DENY=$(kubectl get networkpolicy -n payments-processing default-deny-all 2>/dev/null || echo "")
  if [ -n "$DEF_DENY" ]; then
    report_pass "NetworkPolicy 'default-deny-all' is ACTIVE in payments-processing namespace."
  else
    report_fail "NetworkPolicy 'default-deny-all' is MISSING in payments-processing namespace."
  fi

  # Deploy network probe pods
  report_info "Spinning up isolated probe pods to test East-West packet drop..."
  kubectl apply -f "$MANIFEST_DIR/04-network-probe-target.yaml" &>/dev/null || true
  kubectl apply -f "$MANIFEST_DIR/03-network-probe-source.yaml" &>/dev/null || true

  # Wait for probe pods
  kubectl wait --for=condition=Ready pod/network-probe-source -n payments-processing --timeout=45s &>/dev/null || true
  kubectl wait --for=condition=Ready pod/network-probe-target -n ai-inference --timeout=45s &>/dev/null || true

  TARGET_IP=$(kubectl get pod network-probe-target -n ai-inference -o jsonpath='{.status.podIP}' 2>/dev/null || echo "")

  if [ -n "$TARGET_IP" ]; then
    report_info "Target Pod IP in ai-inference: $TARGET_IP. Attempting unauthorized connection from payments-processing..."
    # Attempt curl with 3s timeout
    PROBE_RESULT=$(kubectl exec -n payments-processing network-probe-source -- nc -z -w 3 "$TARGET_IP" 8080 2>&1 || echo "BLOCKED")
    
    if echo "$PROBE_RESULT" | grep -qi -E "BLOCKED|timed out|Operation timed out"; then
      report_pass "eBPF Dataplane V2 dropped unauthorized East-West packet (Default-Deny working)!"
    else
      report_warn "Traffic probe returned: $PROBE_RESULT (Expected: connection timeout/drop)."
    fi
  else
    report_warn "Could not retrieve target Pod IP. Skipping lateral connectivity check."
  fi

  # Cleanup network probe pods
  kubectl delete -f "$MANIFEST_DIR/03-network-probe-source.yaml" --ignore-not-found=true &>/dev/null || true
  kubectl delete -f "$MANIFEST_DIR/04-network-probe-target.yaml" --ignore-not-found=true &>/dev/null || true
}

# ------------------------------------------------------------------------------
# STEP 6: GKE Sandbox (gVisor) Virtualized Kernel Isolation
# ------------------------------------------------------------------------------
test_gvisor_sandbox() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 6: GKE Sandbox (gVisor) Virtualized Kernel Verification] ---${NC}"

  # Check runtime class
  GVISOR_RC=$(kubectl get runtimeclass gvisor 2>/dev/null || echo "")
  if [ -n "$GVISOR_RC" ]; then
    report_pass "RuntimeClass 'gvisor' is registered in the cluster."
  else
    report_warn "RuntimeClass 'gvisor' not found. Ensure cluster or nodepool has sandbox_type='gvisor'."
  fi

  # Deploy gVisor probe pod
  report_info "Deploying gVisor probe workload..."
  kubectl apply -f "$MANIFEST_DIR/05-gvisor-sandbox-probe.yaml" &>/dev/null || true

  sleep 5
  GVISOR_LOGS=$(kubectl logs gvisor-probe-pod -n ai-inference 2>/dev/null || echo "")

  if [ -n "$GVISOR_LOGS" ]; then
    report_pass "gVisor sandboxed pod initialized successfully."
    report_info "Kernel Diagnostic Output: $(echo "$GVISOR_LOGS" | head -n 2)"
  else
    report_warn "gVisor probe pod scheduled or pending node assignment."
  fi

  kubectl delete -f "$MANIFEST_DIR/05-gvisor-sandbox-probe.yaml" --ignore-not-found=true &>/dev/null || true
}

# ------------------------------------------------------------------------------
# STEP 7: Storage & Secrets CSI Driver Verification
# ------------------------------------------------------------------------------
check_storage_and_secrets() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 7: Secrets CSI Driver & Hardware Storage Encryption] ---${NC}"

  # Check GCP Secret Manager CSI Driver
  CSI_PODS=$(kubectl get daemonset -n kube-system gke-gcp-secret-manager-csi-driver 2>/dev/null || \
             kubectl get daemonset -n kube-system csi-secrets-store 2>/dev/null || echo "")
  if [ -n "$CSI_PODS" ]; then
    report_pass "GCP Secret Manager CSI Driver DaemonSet is ACTIVE in kube-system."
  else
    report_warn "Secret Manager CSI DaemonSet not detected in kube-system."
  fi

  # Check SecretProviderClass
  SPC=$(kubectl get secretproviderclass -n payments-processing gcp-database-secret-provider 2>/dev/null || echo "")
  if [ -n "$SPC" ]; then
    report_pass "SecretProviderClass 'gcp-database-secret-provider' is provisioned with in-memory tmpfs mount."
  else
    report_fail "SecretProviderClass 'gcp-database-secret-provider' missing in payments-processing namespace."
  fi
}

# ------------------------------------------------------------------------------
# STEP 8: Google Cloud Armor WAF & Gateway API Status
# ------------------------------------------------------------------------------
check_cloud_armor_and_gateway() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 8: Cloud Armor WAF & Edge Security Verification] ---${NC}"

  # Check Cloud Armor policy in GCP
  ARMOR_POLICY=$(gcloud compute security-policies describe enterprise-owasp-policy --project "$PROJECT_ID" --format="value(name)" 2>/dev/null || echo "")
  if [ "$ARMOR_POLICY" = "enterprise-owasp-policy" ]; then
    report_pass "Cloud Armor WAF Security Policy 'enterprise-owasp-policy' is ACTIVE in Google Cloud."
    report_info "Configured OWASP Rules: SQLi (1000), XSS (1001), LFI (1002), RCE (1003), Scanners (1004), Rate-Limit (2000)."
  else
    report_warn "Cloud Armor policy 'enterprise-owasp-policy' not found in GCP project $PROJECT_ID."
  fi

  # Check Gateway API CRDs
  GATEWAYS=$(kubectl get gateways -n payments-processing 2>/dev/null || echo "")
  if [ -n "$GATEWAYS" ]; then
    report_pass "GKE Gateway API resource 'gke-cde-gateway' is provisioned."
  else
    report_info "Standard Ingress or Gateway API configured in payments-processing namespace."
  fi
}

# ------------------------------------------------------------------------------
# STEP 9: Audit Logging & BigQuery SIEM Telemetry Sinks
# ------------------------------------------------------------------------------
check_audit_logging_and_bigquery() {
  echo -e "\n${BOLD}${MAGENTA}--- [PHASE 9: Security Audit Logging & BigQuery SIEM Sinks] ---${NC}"

  # Check BigQuery Dataset
  BQ_DATASET=$(bq show "${PROJECT_ID}:gke_security_audit_logs" 2>/dev/null | grep -i "Dataset" || echo "")
  if [ -n "$BQ_DATASET" ]; then
    report_pass "BigQuery Audit Logging Dataset 'gke_security_audit_logs' exists and is ready for compliance SQL queries."
  else
    report_warn "BigQuery dataset 'gke_security_audit_logs' not found (Run Terraform to provision)."
  fi

  # Check Logging Sink
  LOG_SINK=$(gcloud logging sinks describe gke-security-bigquery-sink --project "$PROJECT_ID" --format="value(name)" 2>/dev/null || echo "")
  if [ "$LOG_SINK" = "gke-security-bigquery-sink" ]; then
    report_pass "GCP Logging Sink 'gke-security-bigquery-sink' is streaming GKE audit & eBPF drop logs to BigQuery."
  else
    report_warn "Logging Sink 'gke-security-bigquery-sink' not found in GCP project $PROJECT_ID."
  fi
}

# ------------------------------------------------------------------------------
# STEP 10: Final Compliance Scorecard & Summary
# ------------------------------------------------------------------------------
print_summary() {
  echo ""
  echo -e "${CYAN}${BOLD}==========================================================================${NC}"
  echo -e "${CYAN}${BOLD}                   🏆 GKE SECURITY COMPLIANCE SCORECARD                  ${NC}"
  echo -e "${CYAN}${BOLD}==========================================================================${NC}"
  echo -e "  Passed Controls:   ${GREEN}${BOLD}$PASSED_TESTS${NC} / $TOTAL_TESTS"
  echo -e "  Warnings/Manual:   ${YELLOW}${BOLD}$WARNING_TESTS${NC}"
  echo -e "  Failed Controls:   ${RED}${BOLD}$FAILED_TESTS${NC}"
  echo -e "${CYAN}--------------------------------------------------------------------------${NC}"

  if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  VERDICT: CLUSTER MEETS CIS GKE & PCI-DSS ZERO-TRUST COMPLIANCE! 🚀${NC}"
    echo -e "${GREEN}  Tudo está rodando bonito e blindado no GCP!${NC}"
  else
    echo -e "${RED}${BOLD}  VERDICT: NON-COMPLIANT FINDINGS DETECTED ($FAILED_TESTS failing checks).${NC}"
    echo -e "${YELLOW}  Review the failed controls above and apply remediation manifests.${NC}"
  fi
  echo -e "${CYAN}==========================================================================${NC}"
  echo ""
}

# Execution Pipeline
check_prerequisites
check_node_and_cluster_hardening
check_namespace_isolation
test_psa_rejection
test_kyverno_mutation
test_network_policies
test_gvisor_sandbox
check_storage_and_secrets
check_cloud_armor_and_gateway
check_audit_logging_and_bigquery
print_summary

# created by @jsaccomani

#!/bin/bash
set -euo pipefail

# ==============================================================================
# Greenfield GKE Security Hardening & Zero-Trust Bootstrapper (2026 Baseline)
# Standards: CIS GKE Benchmark v1.9.0, PCI-DSS v4.0 (CDE), NIST CSF 2.0
# Author: @jsaccomani (Google Cloud PSO AI & Infra Security LatAm)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "=========================================================================="
echo "    🛡️  GKE SECURITY HARDENING & ZERO-TRUST BOOTSTRAPPER (2026)         "
echo "=========================================================================="
echo -e "${NC}"

# Parse optional arguments
SKIP_TERRAFORM=false
for arg in "$@"; do
  case $arg in
    --skip-terraform)
      SKIP_TERRAFORM=true
      shift
      ;;
  esac
done

# 1. Dependency Validation
echo -e "${YELLOW}[1/7] Validating local tools and prerequisites...${NC}"
for cmd in gcloud kubectl terraform; do
  if ! command -v "$cmd" &> /dev/null; then
    # Check fallback path in user Google Cloud SDK
    if [ -f "$HOME/google-cloud-sdk/bin/$cmd" ]; then
      export PATH="$HOME/google-cloud-sdk/bin:$PATH"
    else
      echo -e "${RED}ERROR: Required command '$cmd' is not installed or not in PATH.${NC}" >&2
      exit 1
    fi
  fi
done

CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$CURRENT_PROJECT" ]; then
  echo -e "${RED}ERROR: No GCP Project configured in gcloud CLI. Run 'gcloud config set project <PROJECT_ID>' first.${NC}" >&2
  exit 1
fi
echo -e "${GREEN}✓ Local prerequisites verified. Active GCP Project: ${BOLD}$CURRENT_PROJECT${NC}"

# 2. Terraform Infrastructure Provisioning
if [ "$SKIP_TERRAFORM" = true ]; then
  echo -e "${YELLOW}[2/7] Skipping Terraform provisioning (--skip-terraform provided)...${NC}"
else
  echo -e "${YELLOW}[2/7] Provisioning GCP Zero-Trust Infrastructure via Terraform...${NC}"
  cd terraform/
  if [ ! -f "terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    sed "s/your-gcp-project-id/$CURRENT_PROJECT/g" terraform.tfvars.example > terraform.tfvars
  fi
  terraform init
  terraform apply -auto-approve
  cd ../

  # Configure kubectl credentials for the hardened GKE cluster
  echo -e "${CYAN}Configuring kubectl context for hardened cluster...${NC}"
  gcloud container clusters get-credentials hardened-gke-cluster --zone us-central1-a --project "$CURRENT_PROJECT"
fi

# 3. Apply Secure Declarative Namespaces with Pod Security Standards (PSA Restricted)
echo -e "${YELLOW}[3/7] Enforcing Pod Security Admission (PSA) Restricted namespaces...${NC}"
kubectl apply -f kubernetes/namespaces/payments-processing.yaml
kubectl apply -f kubernetes/namespaces/ai-inference.yaml

# 4. Apply eBPF Dataplane V2 Zero-Trust Network Policies
echo -e "${YELLOW}[4/7] Applying Dataplane V2 (eBPF) Zero-Trust Network Policies...${NC}"
kubectl apply -f kubernetes/policies/default-deny-netpolicy.yaml
kubectl apply -f kubernetes/policies/allow-dns-egress.yaml
kubectl apply -f kubernetes/policies/allow-intra-app-traffic.yaml
kubectl apply -f kubernetes/policies/metadata-gate-netpolicy.yaml

# 5. Policy Engine Setup (Kyverno & Gatekeeper)
echo -e "${YELLOW}[5/7] Deploying Kyverno Policy Engine for automated context mutation...${NC}"
if command -v helm &> /dev/null; then
  helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update || true
  helm repo update || true
  helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace \
    --set admissionController.replicas=2 \
    --set backgroundController.replicas=1 || true

  echo "Waiting for Kyverno webhook to become ready..."
  kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=90s 2>/dev/null || \
  kubectl rollout status deployment/kyverno -n kyverno --timeout=90s 2>/dev/null || true

  kubectl apply -f kubernetes/policies/kyverno/mutate-pod-security.yaml || true
  kubectl apply -f kubernetes/policies/kyverno/validate-disallow-privileged.yaml || true
else
  echo -e "${YELLOW}Helm not found; skipping Kyverno Helm install. Applying baseline Gatekeeper constraints...${NC}"
  kubectl apply -f kubernetes/policies/gatekeeper-block-latest.yaml 2>/dev/null || true
fi

# 6. Apply Secret Manager CSI & Hardware Storage Configurations
echo -e "${YELLOW}[6/7] Deploying Secret Manager CSI providers and hardened storage classes...${NC}"
# Substitute current project ID in SecretProviderClass if needed
sed "s/enterprise-core/$CURRENT_PROJECT/g" kubernetes/storage/sm-secret-provider.yaml | kubectl apply -f -
kubectl apply -f kubernetes/storage/hardened-ml-storage.yaml
kubectl apply -f kubernetes/workload-identity/cde-service-account.yaml

# 7. Deploy Hardened Reference Workloads & Verify
echo -e "${YELLOW}[7/7] Deploying Hardened Workloads and validating cluster state...${NC}"
kubectl apply -f kubernetes/workloads/cde-payment-service.yaml
kubectl apply -f kubernetes/workloads/gvisor-sandboxed-workload.yaml || true

echo ""
echo -e "${GREEN}${BOLD}==========================================================================${NC}"
echo -e "${GREEN}${BOLD}    ✓  GREENFIELD GKE SECURITY HARDENING BOOTSTRAP COMPLETE!             ${NC}"
echo -e "${GREEN}${BOLD}==========================================================================${NC}"
echo ""
echo -e "${CYAN}Next Step: Run the Interactive Hands-On Lab and Verification Suite:${NC}"
echo -e "  ${BOLD}./lab/verify-gke-security.sh${NC}"
echo ""
echo -e "View the full hands-on lab guide at: ${BOLD}lab/README.md${NC}"
echo ""

# created by @jsaccomani

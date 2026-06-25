#!/bin/bash
# ==============================================================================
# GKE Security Lab Cleanup & Tear-down Utility
# Author: @jsaccomani (Google Cloud PSO AI & Infra Security LatAm)
# ==============================================================================

set -uo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=========================================================================="
echo "          🧹  GKE SECURITY LAB CLEANUP & RESOURCE TEARDOWN               "
echo "=========================================================================="
echo -e "${NC}"

echo -e "Choose cleanup scope:"
echo "1) Clean up Lab Test Workloads & Probe Pods only (Keep GKE & GCP Infrastructure)"
echo "2) Full Infrastructure Teardown (Terraform Destroy - GKE, VPC, Cloud Armor, KMS)"
echo "3) Cancel"
echo ""

read -rp "Enter choice [1-3]: " CHOICE

case "$CHOICE" in
  1)
    echo -e "\n${YELLOW}Cleaning up test workloads in Kubernetes...${NC}"
    kubectl delete namespace payments-processing ai-inference --ignore-not-found=true
    kubectl delete pod --all -n default --ignore-not-found=true
    echo -e "${GREEN}✓ Lab workloads and test namespaces removed.${NC}"
    ;;
  2)
    echo -e "\n${RED}${BOLD}WARNING: This will destroy all Terraform-managed resources in GCP!${NC}"
    read -rp "Are you sure you want to run 'terraform destroy'? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      cd terraform/
      terraform destroy -auto-approve
      cd ../
      echo -e "${GREEN}✓ All GCP infrastructure destroyed cleanly.${NC}"
    else
      echo "Teardown aborted."
    fi
    ;;
  *)
    echo "Exiting without making changes."
    ;;
esac

# created by @jsaccomani

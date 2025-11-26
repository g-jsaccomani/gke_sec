#!/bin/bash
# ==============================================================================
# LAB TEST 7: Cloud Armor WAF Attack Simulation Script
# Simulates Layer 7 attacks against the GKE Ingress/Gateway external endpoint
# Expected Results: All attacks must be blocked with HTTP 403 Forbidden
# ==============================================================================

set -euo pipefail

TARGET_URL="${1:-}"

if [ -z "$TARGET_URL" ]; then
  echo "Usage: ./07-cloud-armor-attack-payloads.sh <INGRESS_OR_GATEWAY_URL>"
  echo "Example: ./07-cloud-armor-attack-payloads.sh http://34.120.x.x/api/v1/payments"
  exit 1
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=========================================================================="
echo "      🛡️  CLOUD ARMOR WAF ATTACK & OWASP MITIGATION TEST SUITE            "
echo "=========================================================================="
echo -e "${NC}"
echo "Target Endpoint: $TARGET_URL"
echo ""

test_attack() {
  local test_name="$1"
  local url_suffix="$2"
  local header_arg="${3:-}"

  echo -n -e "Testing ${YELLOW}$test_name${NC}... "
  
  if [ -n "$header_arg" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL$url_suffix" -H "$header_arg" || echo "000")
  else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL$url_suffix" || echo "000")
  fi

  if [ "$HTTP_CODE" = "403" ]; then
    echo -e "${GREEN}${BOLD}[BLOCKED - HTTP 403 (PASS)]${NC}"
  elif [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${RED}${BOLD}[ALLOWED - HTTP $HTTP_CODE (FAIL)]${NC}"
  else
    echo -e "${YELLOW}[RESPONSE: HTTP $HTTP_CODE]${NC}"
  fi
}

# 1. SQL Injection Test
test_attack "SQL Injection (SQLi)" "?id=1'%20OR%20'1'='1"

# 2. Cross-Site Scripting Test
test_attack "Cross-Site Scripting (XSS)" "?query=<script>alert('xss')</script>"

# 3. Local File Inclusion / Path Traversal
test_attack "Local File Inclusion (LFI)" "?file=../../../../etc/passwd"

# 4. Remote Code Execution
test_attack "Remote Code Execution (RCE)" "?cmd=;cat%20/etc/shadow"

# 5. Scanner User-Agent Detection
test_attack "Vulnerability Scanner Detection" "" "User-Agent: sqlmap/1.4.11"

echo ""
echo -e "${GREEN}Cloud Armor WAF attack verification completed.${NC}"

# created by @jsaccomani

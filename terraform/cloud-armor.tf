# Google Cloud Armor Edge WAF Policy with OWASP Core Ruleset & Adaptive Protection
resource "google_compute_security_policy" "enterprise_owasp_policy" {
  name        = "enterprise-owasp-policy"
  project     = var.project_id
  description = "Enterprise Cloud Armor WAF policy protecting GKE Ingress & Gateway API"

  # Rule 1000: Block SQL Injection (SQLi)
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Mitigate OWASP Top 10 SQL Injection attacks"
  }

  # Rule 1001: Block Cross-Site Scripting (XSS)
  rule {
    action   = "deny(403)"
    priority = "1001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Mitigate OWASP Top 10 Cross-Site Scripting (XSS) attacks"
  }

  # Rule 1002: Block Local File Inclusion (LFI) & Path Traversal
  rule {
    action   = "deny(403)"
    priority = "1002"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-v33-stable')"
      }
    }
    description = "Mitigate Local File Inclusion (LFI) and Directory Traversal attacks"
  }

  # Rule 1003: Block Remote Code Execution (RCE)
  rule {
    action   = "deny(403)"
    priority = "1003"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rce-v33-stable')"
      }
    }
    description = "Mitigate Remote Code Execution (RCE) and command injection vectors"
  }

  # Rule 1004: Block Automated Scanners & Vulnerability Probers
  rule {
    action   = "deny(403)"
    priority = "1004"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('scannerdetection-v33-stable')"
      }
    }
    description = "Block known security scanners and automated exploit reconnaissance tools"
  }

  # Rule 2000: Rate Limiting & Anti-DDoS Threshold
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 120
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Rate limit aggressive traffic bursts to 120 req/min per source IP"
  }

  # Default Rule: Allow legitimate traffic
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule for inspected traffic"
  }

  # ML-based Layer 7 Adaptive Protection
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }
}

# created by @jsaccomani

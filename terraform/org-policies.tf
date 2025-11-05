resource "google_project_organization_policy" "block_service_account_keys" {
  count      = var.enable_org_policies ? 1 : 0
  project    = var.project_id
  constraint = "constraints/iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "disable_cloud_shell" {
  count      = var.enable_org_policies ? 1 : 0
  project    = var.project_id
  constraint = "constraints/compute.disableCloudShell"

  boolean_policy {
    enforced = true
  }
}

# created by @jsaccomani

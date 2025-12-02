resource "google_project_access_approval_settings" "project_access_approval" {
  count               = var.enable_access_approval ? 1 : 0
  project_id          = var.project_id
  notification_emails = ["soc-alerts@enterprise-platform.com"]

  enrolled_services {
    cloud_product    = "all"
    enrollment_level = "BLOCK_ALL"
  }
}

resource "google_essential_contacts_contact" "security_contact" {
  count                               = var.enable_access_approval ? 1 : 0
  parent                              = "projects/${var.project_id}"
  email                               = "soc-alerts@enterprise-platform.com"
  language_tag                        = "en"
  notification_category_subscriptions = ["SECURITY", "TECHNICAL"]
}

# created by @jsaccomani

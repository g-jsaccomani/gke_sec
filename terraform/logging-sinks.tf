resource "google_pubsub_topic" "xsiam_logs_topic" {
  name    = "xsiam-audit-logs-topic"
  project = var.project_id
}

resource "google_logging_folder_sink" "aggregated_cortex_sink" {
  count            = var.enable_cortex_logging && var.folder_id != "" ? 1 : 0
  name             = "xsiam-folder-aggregated-sink"
  folder           = var.folder_id
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.xsiam_logs_topic.id}"
  include_children = true

  filter = <<EOT
    resource.type="gke_cluster" OR
    logName:"cloudaudit.googleapis.com" OR
    (resource.type="k8s_node" AND logName:"logs/dataplane-v2.drops")
  EOT
}

resource "google_pubsub_topic_iam_member" "pubsub_publisher" {
  count   = var.enable_cortex_logging && var.folder_id != "" ? 1 : 0
  topic   = google_pubsub_topic.xsiam_logs_topic.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_folder_sink.aggregated_cortex_sink[0].writer_identity
  project = var.project_id
}

# created by @jsaccomani

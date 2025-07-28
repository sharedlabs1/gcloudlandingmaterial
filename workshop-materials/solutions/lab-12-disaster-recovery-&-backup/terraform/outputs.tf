output "lab_12_resources" {
  description = "Resources created in Lab 12"
  value = {
    lab_number = "12"
    lab_title  = "Disaster Recovery & Backup"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_12_bucket.name
  }
}

output "integration_outputs" {
  description = "Outputs for integration with subsequent labs"
  value = {
    lab_completed = true
    timestamp     = timestamp()
    common_labels = local.common_labels
  }
}

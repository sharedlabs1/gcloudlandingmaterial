output "lab_08_resources" {
  description = "Resources created in Lab 08"
  value = {
    lab_number = "08"
    lab_title  = "Shared Services Implementation"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_08_bucket.name
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

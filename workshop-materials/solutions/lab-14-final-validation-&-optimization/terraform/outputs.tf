output "lab_14_resources" {
  description = "Resources created in Lab 14"
  value = {
    lab_number = "14"
    lab_title  = "Final Validation & Optimization"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_14_bucket.name
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

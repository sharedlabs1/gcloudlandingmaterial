output "lab_13_resources" {
  description = "Resources created in Lab 13"
  value = {
    lab_number = "13"
    lab_title  = "Cost Management & Optimization"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_13_bucket.name
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

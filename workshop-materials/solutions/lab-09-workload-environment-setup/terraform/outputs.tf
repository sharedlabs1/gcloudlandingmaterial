output "lab_09_resources" {
  description = "Resources created in Lab 09"
  value = {
    lab_number = "09"
    lab_title  = "Workload Environment Setup"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_09_bucket.name
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

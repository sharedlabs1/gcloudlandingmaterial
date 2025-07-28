output "lab_05_resources" {
  description = "Resources created in Lab 05"
  value = {
    lab_number = "05"
    lab_title  = "Identity and Access Management"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_05_bucket.name
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

output "lab_11_resources" {
  description = "Resources created in Lab 11"
  value = {
    lab_number = "11"
    lab_title  = "Advanced Monitoring & Alerting"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_11_bucket.name
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

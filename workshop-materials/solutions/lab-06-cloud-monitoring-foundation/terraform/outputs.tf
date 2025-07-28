output "lab_06_resources" {
  description = "Resources created in Lab 06"
  value = {
    lab_number = "06"
    lab_title  = "Cloud Monitoring Foundation"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_06_bucket.name
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

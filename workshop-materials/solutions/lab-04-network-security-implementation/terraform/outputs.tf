output "lab_04_resources" {
  description = "Resources created in Lab 04"
  value = {
    lab_number = "04"
    lab_title  = "Network Security Implementation"
    project_id = var.project_id
    region     = var.region
    bucket     = google_storage_bucket.lab_04_bucket.name
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

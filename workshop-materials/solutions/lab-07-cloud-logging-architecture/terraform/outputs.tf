# Outputs for Lab 07

output "lab_07_resources" {
  description = "Resources created in Lab 07"
  value = {
    lab_number = "07"
    project_id = var.project_id
    region     = var.region
  }
}

output "log_buckets" {
  description = "Created log storage buckets"
  value = {
    audit_logs    = google_storage_bucket.audit_log_bucket.name
    security_logs = google_storage_bucket.security_log_bucket.name
  }
}

output "log_sinks" {
  description = "Created log sinks"
  value = {
    audit_sink    = google_logging_project_sink.audit_sink.name
    security_sink = google_logging_project_sink.security_sink.name
    bigquery_sink = google_logging_project_sink.bigquery_sink.name
    alerting_sink = google_logging_project_sink.alerting_sink.name
  }
}

output "bigquery_dataset" {
  description = "BigQuery dataset for logs"
  value = {
    dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
    location   = google_bigquery_dataset.logs_dataset.location
  }
}

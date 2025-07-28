# Lab 07 Solution: Cloud Logging Architecture
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "${TF_STATE_BUCKET}"
    prefix = "lab-07/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "07"
    component   = "logging"
    environment = "production"
  }
}

# Create log storage buckets
resource "google_storage_bucket" "audit_log_bucket" {
  name     = "${var.project_id}-audit-logs"
  location = var.region
  
  uniform_bucket_level_access = true
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 2555  # 7 years for compliance
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "audit-logs"
    retention = "7-years"
  })
}

resource "google_storage_bucket" "security_log_bucket" {
  name     = "${var.project_id}-security-logs"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 1095  # 3 years
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "security-logs"
    retention = "3-years"
  })
}

# Create log sinks
resource "google_logging_project_sink" "audit_sink" {
  name        = "techcorp-audit-logs"
  description = "Compliance audit logs for SOX, PCI DSS requirements"
  
  filter = <<-EOT
    protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
    protoPayload.serviceName="iam.googleapis.com" OR
    protoPayload.serviceName="storage.googleapis.com" OR
    (protoPayload.authenticationInfo.principalEmail!="" AND
     protoPayload.methodName!="" AND
     severity >= "NOTICE")
  EOT
  
  destination = "storage.googleapis.com/${google_storage_bucket.audit_log_bucket.name}"
  unique_writer_identity = true
}

resource "google_logging_project_sink" "security_sink" {
  name        = "techcorp-security-logs"
  description = "Security monitoring and incident response logs"
  
  filter = <<-EOT
    (severity >= "WARNING" AND
     (protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
      protoPayload.serviceName="iam.googleapis.com" OR
      protoPayload.serviceName="compute.googleapis.com")) OR
    (jsonPayload.message=~"SECURITY" OR
     jsonPayload.message=~"UNAUTHORIZED")
  EOT
  
  destination = "storage.googleapis.com/${google_storage_bucket.security_log_bucket.name}"
  unique_writer_identity = true
}

# Create BigQuery dataset for log analysis
resource "google_bigquery_dataset" "logs_dataset" {
  dataset_id  = "techcorp_logs"
  description = "Dataset for real-time log analysis and reporting"
  location    = var.region
  
  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  labels = local.common_labels
}

resource "google_logging_project_sink" "bigquery_sink" {
  name        = "techcorp-logs-bigquery"
  description = "Real-time log analysis in BigQuery"
  
  filter = <<-EOT
    (severity >= "INFO" AND
     (resource.type="gce_instance" OR
      resource.type="cloud_function" OR
      resource.type="gke_cluster")) OR
    (protoPayload.methodName!="" AND
     severity >= "NOTICE")
  EOT
  
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs_dataset.dataset_id}"
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Create Pub/Sub topic for alerting
resource "google_pubsub_topic" "log_alerts" {
  name = "techcorp-log-alerts"
  
  labels = merge(local.common_labels, {
    purpose = "log-alerting"
  })
}

resource "google_logging_project_sink" "alerting_sink" {
  name        = "techcorp-log-alerting"
  description = "Real-time log alerts for critical events"
  
  filter = <<-EOT
    severity >= "ERROR" OR
    (jsonPayload.message=~"CRITICAL" OR
     jsonPayload.message=~"EMERGENCY")
  EOT
  
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.log_alerts.name}"
  unique_writer_identity = true
}

# Grant permissions for log sinks
resource "google_storage_bucket_iam_member" "audit_sink_writer" {
  bucket = google_storage_bucket.audit_log_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_sink.writer_identity
}

resource "google_storage_bucket_iam_member" "security_sink_writer" {
  bucket = google_storage_bucket.security_log_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.security_sink.writer_identity
}

resource "google_bigquery_dataset_iam_member" "logs_dataset_writer" {
  dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery_sink.writer_identity
}

resource "google_pubsub_topic_iam_member" "alerting_sink_publisher" {
  topic  = google_pubsub_topic.log_alerts.name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.alerting_sink.writer_identity
}

# Create log-based metrics
resource "google_logging_metric" "failed_auth_metric" {
  name   = "techcorp_failed_auth_attempts"
  filter = <<-EOT
    protoPayload.serviceName="iam.googleapis.com" AND
    protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey" AND
    severity >= "WARNING"
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Failed Authentication Attempts"
  }
  
  label_extractors = {
    "user"   = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "method" = "EXTRACT(protoPayload.methodName)"
  }
}

resource "google_logging_metric" "critical_errors_metric" {
  name   = "techcorp_critical_errors"
  filter = <<-EOT
    severity >= "ERROR" AND
    (jsonPayload.message=~"CRITICAL" OR
     jsonPayload.level="CRITICAL")
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Critical Application Errors"
  }
  
  label_extractors = {
    "service"  = "EXTRACT(resource.labels.service_name)"
    "instance" = "EXTRACT(resource.labels.instance_id)"
  }
}

# Create monitoring policies
resource "google_monitoring_alert_policy" "failed_auth_alert" {
  display_name = "TechCorp - High Failed Authentication Attempts"
  
  conditions {
    display_name = "Failed auth attempts > 10 in 5 minutes"
    
    condition_threshold {
      filter         = "metric.type=\"logging.googleapis.com/user/techcorp_failed_auth_attempts\""
      duration       = "300s"
      comparison     = "COMPARISON_GREATER_THAN"
      threshold_value = 10
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  enabled = true
}

data "google_client_openid_userinfo" "current" {}

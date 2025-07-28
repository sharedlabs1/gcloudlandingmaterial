# Lab 07: Cloud Logging Architecture

## Lab Overview

**Duration**: 45 minutes 
**Difficulty**: Intermediate  
**Prerequisites**: Successful completion of Labs 01-06 (Day 1 foundation)

### Lab Description
Configure centralized logging with log sinks, aggregation, analysis capabilities, and long-term retention to meet TechCorp's operational and compliance requirements including audit trails for financial regulations.

### Business Context
As TechCorp's cloud infrastructure matures, this lab implements advanced operational capabilities essential for production fintech environments, including regulatory compliance, operational excellence, and enterprise-grade automation.

## Learning Objectives

After completing this lab, you will be able to:

• Design and implement enterprise centralized logging architecture
• Configure log sinks for different destinations and compliance requirements
• Implement structured logging with proper log levels and formatting
• Set up log-based metrics and automated monitoring
• Configure compliance-grade log retention and audit trails
• Implement security monitoring and automated alerting from logs
• Set up log export for long-term archival and analysis

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

**Centralized Logging Strategy**: Enterprise logging requires centralized collection, routing, and analysis of logs from all infrastructure and application components. This includes structured logging, log correlation, and automated analysis for both operational and security purposes.

**Log Sinks and Routing**: GCP Cloud Logging provides advanced log routing capabilities through sinks, allowing logs to be sent to different destinations based on filters, content, and business requirements. This enables cost optimization and compliance with data residency requirements.

**Compliance and Audit Logging**: Financial services require immutable audit trails, long-term retention, and specific log formats for regulatory compliance. This includes SOX, PCI DSS, and other fintech regulations requiring detailed activity logging.

**Log Analysis and Alerting**: Advanced log analysis includes real-time monitoring, anomaly detection, and automated alerting based on log patterns. This enables proactive incident response and security monitoring.

### Architecture Diagram
```
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab 07 Components
Integration with Labs 01-06
```

## Pre-Lab Setup

### Environment Verification
```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-07

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Lab: 07"
echo "Current directory: $(pwd)"

# Check prerequisites from previous labs
echo "Checking previous lab outputs..."
ls -la ../lab-06/outputs/

# Verify Day 1 foundation is complete
required_labs=(01 02 03 04 05 06)
for lab in "${required_labs[@]}"; do
    if [ -f "../lab-$lab/outputs/lab-$lab-validation.json" ]; then
        status=$(jq -r '.status' "../lab-$lab/outputs/lab-$lab-validation.json")
        if [ "$status" = "PASSED" ]; then
            echo "✓ Lab $lab: Foundation ready"
        else
            echo "✗ Lab $lab: Validation failed - please complete Day 1 labs first"
            exit 1
        fi
    else
        echo "✗ Lab $lab: Not completed - please complete Day 1 labs first"
        exit 1
    fi
done
```

### Required Variables
```bash
# Set lab-specific variables
export LAB_PREFIX="lab07"
export TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export LAB_USER=$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}

# Get previous lab outputs for integration
if [ -f "../lab-06/outputs/terraform-outputs.json" ]; then
    echo "✓ Previous lab outputs available for integration"
else
    echo "⚠ Previous lab outputs not found - some integrations may not work"
fi
```

## Lab Implementation

### Step 1: Centralized Logging Infrastructure Setup

Configure the foundational logging infrastructure for TechCorp's enterprise needs.

```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-07/terraform

# Create main logging configuration
cat > main.tf << 'LOGGING_MAIN_END'
# Lab 07: Cloud Logging Architecture
# Centralized logging infrastructure for TechCorp

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "${TF_STATE_BUCKET}"
    prefix = "lab-07/terraform/state"
  }
}

# Get previous lab outputs
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

# Local values for consistent configuration
locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "07"
    component   = "logging"
    environment = "enterprise"
    compliance  = "fintech"
  }
  
  # Log retention periods for different log types
  retention_policies = {
    audit_logs     = 2555  # 7 years for compliance
    security_logs  = 1095  # 3 years
    application_logs = 365 # 1 year
    debug_logs     = 30    # 30 days
  }
}

# Create dedicated log storage buckets for different retention periods
resource "google_storage_bucket" "audit_log_bucket" {
  name     = "${var.project_id}-audit-logs"
  location = var.region
  
  # Compliance-grade settings
  uniform_bucket_level_access = true
  force_destroy = false
  
  # Versioning for audit trail integrity
  versioning {
    enabled = true
  }
  
  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = local.retention_policies.audit_logs
    }
    action {
      type = "Delete"
    }
  }
  
  # Prevent accidental deletion
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
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
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = local.retention_policies.security_logs
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

resource "google_storage_bucket" "application_log_bucket" {
  name     = "${var.project_id}-application-logs"
  location = var.region
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = local.retention_policies.application_logs
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "application-logs"
    retention = "1-year"
  })
}
LOGGING_MAIN_END

echo "✓ Main logging infrastructure configuration created"
```

### Step 2: Configure Advanced Log Sinks

Set up comprehensive log routing for different compliance and operational requirements.

```bash
# Add log sinks configuration
cat >> main.tf << 'LOG_SINKS_END'

# Audit log sink for compliance (all admin activity)
resource "google_logging_project_sink" "audit_sink" {
  name        = "techcorp-audit-logs"
  description = "Compliance audit logs for SOX, PCI DSS requirements"
  
  # Capture all admin activity and data access
  filter = <<-EOT
    protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
    protoPayload.serviceName="iam.googleapis.com" OR
    protoPayload.serviceName="storage.googleapis.com" OR
    protoPayload.serviceName="compute.googleapis.com" OR
    (protoPayload.authenticationInfo.principalEmail!="" AND
     protoPayload.methodName!="" AND
     severity >= "NOTICE")
  EOT
  
  destination = "storage.googleapis.com/${google_storage_bucket.audit_log_bucket.name}"
  
  # Use unique writer identity for security
  unique_writer_identity = true
}

# Security log sink for monitoring suspicious activities
resource "google_logging_project_sink" "security_sink" {
  name        = "techcorp-security-logs"
  description = "Security monitoring and incident response logs"
  
  filter = <<-EOT
    (severity >= "WARNING" AND
     (protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
      protoPayload.serviceName="iam.googleapis.com" OR
      protoPayload.serviceName="compute.googleapis.com")) OR
    (jsonPayload.message=~"SECURITY" OR
     jsonPayload.message=~"UNAUTHORIZED" OR
     jsonPayload.message=~"FAILED_LOGIN" OR
     jsonPayload.message=~"INTRUSION")
  EOT
  
  destination = "storage.googleapis.com/${google_storage_bucket.security_log_bucket.name}"
  unique_writer_identity = true
}

# Application log sink for operational monitoring
resource "google_logging_project_sink" "application_sink" {
  name        = "techcorp-application-logs"
  description = "Application logs for debugging and monitoring"
  
  filter = <<-EOT
    resource.type="gce_instance" OR
    resource.type="k8s_container" OR
    resource.type="cloud_function" OR
    (logName=~"projects/[^/]+/logs/app" AND severity >= "INFO")
  EOT
  
  destination = "storage.googleapis.com/${google_storage_bucket.application_log_bucket.name}"
  unique_writer_identity = true
}

# BigQuery sink for real-time log analysis
resource "google_bigquery_dataset" "logs_dataset" {
  dataset_id  = "techcorp_logs"
  description = "Dataset for real-time log analysis and reporting"
  location    = var.region
  
  # Set access controls
  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  access {
    role          = "READER"
    special_group = "projectReaders"
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
  
  # Configure BigQuery options
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Pub/Sub sink for real-time alerting
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
     jsonPayload.message=~"EMERGENCY" OR
     protoPayload.authenticationInfo.principalEmail=~".*@.*" AND
     protoPayload.methodName=~".*delete.*")
  EOT
  
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.log_alerts.name}"
  unique_writer_identity = true
}
LOG_SINKS_END

echo "✓ Advanced log sinks configuration added"
```

### Step 3: Set Up IAM for Log Management

Configure proper access controls for log management and compliance.

```bash
# Add IAM configuration for logging
cat >> main.tf << 'LOGGING_IAM_END'

# Grant logging sink permissions to write to storage buckets
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

resource "google_storage_bucket_iam_member" "application_sink_writer" {
  bucket = google_storage_bucket.application_log_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.application_sink.writer_identity
}

# Grant BigQuery permissions
resource "google_bigquery_dataset_iam_member" "logs_dataset_writer" {
  dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery_sink.writer_identity
}

# Grant Pub/Sub permissions
resource "google_pubsub_topic_iam_member" "alerting_sink_publisher" {
  topic  = google_pubsub_topic.log_alerts.name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.alerting_sink.writer_identity
}

# Create dedicated service account for log analysis
resource "google_service_account" "log_analyst" {
  account_id   = "techcorp-log-analyst"
  display_name = "TechCorp Log Analyst Service Account"
  description  = "Service account for log analysis and monitoring automation"
}

# Grant log analyst permissions
resource "google_project_iam_member" "log_analyst_permissions" {
  for_each = toset([
    "roles/logging.viewer",
    "roles/bigquery.dataViewer",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.log_analyst.email}"
}

# Data source for current user
data "google_client_openid_userinfo" "current" {}
LOGGING_IAM_END

echo "✓ Logging IAM configuration added"
```

### Step 4: Create Log-Based Metrics and Monitoring

Set up automated monitoring and alerting based on log patterns.

```bash
# Add log-based metrics configuration
cat >> main.tf << 'LOG_METRICS_END'

# Log-based metric for failed authentication attempts
resource "google_logging_metric" "failed_auth_metric" {
  name   = "techcorp_failed_auth_attempts"
  filter = <<-EOT
    protoPayload.serviceName="iam.googleapis.com" AND
    protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey" AND
    protoPayload.authenticationInfo.principalEmail!="" AND
    severity >= "WARNING"
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Failed Authentication Attempts"
  }
  
  value_extractor = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
  
  label_extractors = {
    "user" = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "method" = "EXTRACT(protoPayload.methodName)"
  }
}

# Log-based metric for critical application errors
resource "google_logging_metric" "critical_errors_metric" {
  name   = "techcorp_critical_errors"
  filter = <<-EOT
    severity >= "ERROR" AND
    (jsonPayload.message=~"CRITICAL" OR
     jsonPayload.message=~"FATAL" OR
     jsonPayload.level="CRITICAL")
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Critical Application Errors"
  }
  
  label_extractors = {
    "service" = "EXTRACT(resource.labels.service_name)"
    "instance" = "EXTRACT(resource.labels.instance_id)"
  }
}

# Log-based metric for data access patterns
resource "google_logging_metric" "data_access_metric" {
  name   = "techcorp_data_access"
  filter = <<-EOT
    protoPayload.serviceName="storage.googleapis.com" AND
    (protoPayload.methodName="storage.objects.get" OR
     protoPayload.methodName="storage.objects.create" OR
     protoPayload.methodName="storage.objects.delete") AND
    protoPayload.resourceName=~".*sensitive.*"
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Sensitive Data Access"
  }
  
  label_extractors = {
    "user" = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "operation" = "EXTRACT(protoPayload.methodName)"
    "resource" = "EXTRACT(protoPayload.resourceName)"
  }
}

# Create monitoring policy for failed authentication
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
  
  notification_channels = []  # Will be configured in monitoring lab
  
  alert_strategy {
    auto_close = "1800s"  # 30 minutes
  }
  
  enabled = true
}

# Create monitoring policy for critical errors
resource "google_monitoring_alert_policy" "critical_error_alert" {
  display_name = "TechCorp - Critical Application Errors"
  
  conditions {
    display_name = "Critical errors detected"
    
    condition_threshold {
      filter         = "metric.type=\"logging.googleapis.com/user/techcorp_critical_errors\""
      duration       = "60s"
      comparison     = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "3600s"  # 1 hour
  }
  
  enabled = true
}
LOG_METRICS_END

echo "✓ Log-based metrics and monitoring configuration added"
```

### Step 5: Create Variables and Outputs

Set up configuration management for the logging infrastructure.

```bash
# Create variables file
cat > variables.tf << 'LOGGING_VARS_END'
# Variables for Lab 07: Cloud Logging Architecture

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region"
  type        = string
  default     = "us-central1"
}

variable "tf_state_bucket" {
  description = "Terraform state bucket name"
  type        = string
}

variable "log_retention_days" {
  description = "Default log retention period in days"
  type        = number
  default     = 365
}

variable "audit_log_retention_days" {
  description = "Audit log retention period for compliance"
  type        = number
  default     = 2555  # 7 years
}

variable "enable_data_access_logs" {
  description = "Enable data access logging for compliance"
  type        = bool
  default     = true
}

variable "log_export_enabled" {
  description = "Enable log export to external systems"
  type        = bool
  default     = true
}

variable "compliance_mode" {
  description = "Enable additional compliance features"
  type        = string
  default     = "fintech"
  
  validation {
    condition     = contains(["basic", "fintech", "healthcare"], var.compliance_mode)
    error_message = "Compliance mode must be basic, fintech, or healthcare."
  }
}
LOGGING_VARS_END

# Create terraform.tfvars
cat > terraform.tfvars << 'LOGGING_TFVARS_END'
# Lab 07 Configuration Values
project_id = "${PROJECT_ID}"
region = "${REGION}"
tf_state_bucket = "${TF_STATE_BUCKET}"

# Compliance configuration for TechCorp
compliance_mode = "fintech"
audit_log_retention_days = 2555  # 7 years for SOX compliance
enable_data_access_logs = true
log_export_enabled = true
LOGGING_TFVARS_END

# Create comprehensive outputs
cat > outputs.tf << 'LOGGING_OUTPUTS_END'
# Outputs for Lab 07: Cloud Logging Architecture

# Log storage buckets
output "log_storage_buckets" {
  description = "Created log storage buckets"
  value = {
    audit_logs       = google_storage_bucket.audit_log_bucket.name
    security_logs    = google_storage_bucket.security_log_bucket.name
    application_logs = google_storage_bucket.application_log_bucket.name
  }
}

# Log sinks
output "log_sinks" {
  description = "Configured log sinks"
  value = {
    audit_sink       = google_logging_project_sink.audit_sink.name
    security_sink    = google_logging_project_sink.security_sink.name
    application_sink = google_logging_project_sink.application_sink.name
    bigquery_sink    = google_logging_project_sink.bigquery_sink.name
    alerting_sink    = google_logging_project_sink.alerting_sink.name
  }
}

# BigQuery dataset for log analysis
output "logs_bigquery_dataset" {
  description = "BigQuery dataset for log analysis"
  value = {
    dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
    location   = google_bigquery_dataset.logs_dataset.location
  }
}

# Pub/Sub topic for alerting
output "log_alerting_topic" {
  description = "Pub/Sub topic for log-based alerting"
  value = {
    name = google_pubsub_topic.log_alerts.name
    id   = google_pubsub_topic.log_alerts.id
  }
}

# Log-based metrics
output "log_metrics" {
  description = "Created log-based metrics"
  value = {
    failed_auth_metric   = google_logging_metric.failed_auth_metric.name
    critical_errors_metric = google_logging_metric.critical_errors_metric.name
    data_access_metric   = google_logging_metric.data_access_metric.name
  }
}

# Monitoring policies
output "monitoring_policies" {
  description = "Created monitoring alert policies"
  value = {
    failed_auth_alert   = google_monitoring_alert_policy.failed_auth_alert.name
    critical_error_alert = google_monitoring_alert_policy.critical_error_alert.name
  }
}

# Service accounts
output "log_service_accounts" {
  description = "Service accounts for log management"
  value = {
    log_analyst = {
      email = google_service_account.log_analyst.email
      name  = google_service_account.log_analyst.name
    }
  }
}

# Integration outputs for subsequent labs
output "logging_integration" {
  description = "Logging integration points for other labs"
  value = {
    bigquery_dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
    alerting_topic_name = google_pubsub_topic.log_alerts.name
    log_analyst_sa      = google_service_account.log_analyst.email
  }
}
LOGGING_OUTPUTS_END

echo "✓ Variables and outputs configuration created"
```

### Step 6: Deploy and Validate Logging Infrastructure

Initialize, plan, and apply the logging configuration.

```bash
# Initialize and deploy
echo "Initializing Terraform for logging infrastructure..."
terraform init

echo "Validating logging configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✓ Terraform configuration is valid"
else
    echo "✗ Terraform configuration validation failed"
    exit 1
fi

echo "Planning logging infrastructure deployment..."
terraform plan -var-file=terraform.tfvars -out=lab07.tfplan

echo "Review the plan above. It should show:"
echo "- Log storage buckets with compliance-grade retention"
echo "- Advanced log sinks for different log types"
echo "- BigQuery dataset for real-time log analysis"
echo "- Pub/Sub topic for real-time alerting"
echo "- Log-based metrics and monitoring policies"
echo "- IAM bindings for secure log access"

read -p "Apply this logging configuration? (y/N): " confirm
if [[ $confirm == "y" || $confirm == "Y" ]]; then
    echo "Applying logging infrastructure..."
    terraform apply lab07.tfplan
    
    if [ $? -eq 0 ]; then
        echo "✓ Logging infrastructure deployed successfully"
        echo "✓ Centralized logging architecture is ready"
    else
        echo "✗ Terraform apply failed"
        exit 1
    fi
else
    echo "Terraform apply cancelled"
    exit 1
fi
```

### Step 7: Test Logging Configuration

Validate that logs are being properly collected and routed.

```bash
# Create logging test script
cat > ../scripts/test-logging.sh << 'LOGGING_TEST_END'
#!/bin/bash

echo "=== Testing TechCorp Logging Configuration ==="

# Test log generation
echo "Generating test logs..."
gcloud logging write techcorp-test-log '{"message": "Test log entry", "severity": "INFO", "component": "test"}'
gcloud logging write techcorp-test-log '{"message": "Test ERROR log", "severity": "ERROR", "component": "test"}'
gcloud logging write techcorp-test-log '{"message": "CRITICAL system alert", "severity": "CRITICAL", "component": "test"}'

# Wait for log ingestion
echo "Waiting for log ingestion (30 seconds)..."
sleep 30

# Test log queries
echo "Testing log queries..."
gcloud logging read "logName=\"projects/${PROJECT_ID}/logs/techcorp-test-log\"" --limit=5 --format=json

# Test BigQuery export
echo "Checking BigQuery log export..."
bq query --use_legacy_sql=false "SELECT timestamp, severity, jsonPayload.message FROM \`${PROJECT_ID}.techcorp_logs.*\` WHERE jsonPayload.component = 'test' LIMIT 5"

# Test log-based metrics
echo "Checking log-based metrics..."
gcloud logging metrics list --filter="name:techcorp"

echo "✓ Logging configuration test completed"
LOGGING_TEST_END

chmod +x ../scripts/test-logging.sh

echo "✓ Logging test script created"
echo "Run: cd ~/gcp-landing-zone-workshop/lab-07/scripts && ./test-logging.sh"
```

## Expected Deliverables

Upon successful completion of this lab, you should have:

• Centralized logging infrastructure with compliance-grade retention policies
• Advanced log sinks routing logs to BigQuery, Cloud Storage, and Pub/Sub
• Log-based metrics for security monitoring and operational alerting
• BigQuery dataset for real-time log analysis and reporting
• Compliance audit trails meeting fintech regulatory requirements
• Automated monitoring policies for critical events and security incidents
• Service accounts and IAM configuration for secure log management
• Integration points for subsequent monitoring and alerting labs

## Validation and Testing

### Automated Validation
```bash
# Create comprehensive validation script
cat > validation/validate-lab-07.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab 07 Validation Script ==="
echo "Started at: $(date)"
echo "Project: $PROJECT_ID"
echo

# Source workshop configuration
source ../../workshop-config.env

validation_passed=0
validation_failed=0

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo "✓ $2"
        ((validation_passed++))
    else
        echo "✗ $2"
        ((validation_failed++))
    fi
}

# Check Day 1 prerequisites
echo "Validating Day 1 prerequisites..."
day1_labs=(01 02 03 04 05 06)
for lab in "${day1_labs[@]}"; do
    if [ -f "../../lab-$lab/outputs/lab-$lab-validation.json" ]; then
        status=$(jq -r '.status' "../../lab-$lab/outputs/lab-$lab-validation.json")
        check_status $([ "$status" = "PASSED" ] && echo 0 || echo 1) "Day 1 Lab $lab prerequisite"
    else
        echo "✗ Day 1 Lab $lab not completed"
        ((validation_failed++))
    fi
done

# Check log storage buckets
echo "Checking log storage buckets..."
buckets=("audit-logs" "security-logs" "application-logs")
for bucket_type in "${buckets[@]}"; do
    bucket_name="${PROJECT_ID}-${bucket_type}"
    if gsutil ls gs://$bucket_name &>/dev/null; then
        echo "✓ Log bucket created: $bucket_name"
        ((validation_passed++))
        
        # Check bucket configuration
        if gsutil lifecycle get gs://$bucket_name | grep -q "age"; then
            echo "✓ Lifecycle policy configured for $bucket_name"
            ((validation_passed++))
        else
            echo "✗ Lifecycle policy missing for $bucket_name"
            ((validation_failed++))
        fi
    else
        echo "✗ Log bucket missing: $bucket_name"
        ((validation_failed++))
    fi
done

# Check log sinks
echo "Checking log sinks..."
log_sinks=("techcorp-audit-logs" "techcorp-security-logs" "techcorp-application-logs" "techcorp-logs-bigquery" "techcorp-log-alerting")
for sink in "${log_sinks[@]}"; do
    if gcloud logging sinks describe $sink --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Log sink created: $sink"
        ((validation_passed++))
    else
        echo "✗ Log sink missing: $sink"
        ((validation_failed++))
    fi
done

# Check BigQuery dataset
echo "Checking BigQuery dataset..."
if bq show --dataset ${PROJECT_ID}:techcorp_logs &>/dev/null; then
    echo "✓ BigQuery logs dataset created"
    ((validation_passed++))
else
    echo "✗ BigQuery logs dataset missing"
    ((validation_failed++))
fi

# Check Pub/Sub topic
echo "Checking Pub/Sub alerting topic..."
if gcloud pubsub topics describe techcorp-log-alerts --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Pub/Sub alerting topic created"
    ((validation_passed++))
else
    echo "✗ Pub/Sub alerting topic missing"
    ((validation_failed++))
fi

# Check log-based metrics
echo "Checking log-based metrics..."
log_metrics=("techcorp_failed_auth_attempts" "techcorp_critical_errors" "techcorp_data_access")
for metric in "${log_metrics[@]}"; do
    if gcloud logging metrics describe $metric --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Log-based metric created: $metric"
        ((validation_passed++))
    else
        echo "✗ Log-based metric missing: $metric"
        ((validation_failed++))
    fi
done

# Check monitoring alert policies
echo "Checking monitoring alert policies..."
policies=$(gcloud alpha monitoring policies list --filter="displayName:TechCorp" --format="value(name)" 2>/dev/null)
if [ -n "$policies" ]; then
    echo "✓ Monitoring alert policies created"
    ((validation_passed++))
else
    echo "✗ Monitoring alert policies missing"
    ((validation_failed++))
fi

# Check service accounts
echo "Checking log management service accounts..."
sa_email="techcorp-log-analyst@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe $sa_email --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Log analyst service account created"
    ((validation_passed++))
else
    echo "✗ Log analyst service account missing"
    ((validation_failed++))
fi

# Test log ingestion
echo "Testing log ingestion..."
test_log_entry="{\"message\": \"Lab 07 validation test\", \"severity\": \"INFO\", \"lab\": \"07\"}"
if gcloud logging write lab07-validation "$test_log_entry" --project=$PROJECT_ID; then
    echo "✓ Log ingestion test successful"
    ((validation_passed++))
else
    echo "✗ Log ingestion test failed"
    ((validation_failed++))
fi

# Check Terraform outputs
echo "Checking Terraform outputs..."
cd terraform
terraform_outputs=$(terraform output -json 2>/dev/null)
if [ $? -eq 0 ] && [ "$terraform_outputs" != "{}" ]; then
    echo "✓ Terraform outputs available"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=("log_storage_buckets" "log_sinks" "logs_bigquery_dataset" "log_alerting_topic")
    for output in "${required_outputs[@]}"; do
        if echo "$terraform_outputs" | jq -e ".$output" &>/dev/null; then
            echo "✓ Output available: $output"
            ((validation_passed++))
        else
            echo "✗ Output missing: $output"
            ((validation_failed++))
        fi
    done
else
    echo "✗ Terraform outputs not available"
    ((validation_failed++))
fi
cd ..

# Check integration with previous labs
echo "Checking integration with previous labs..."
cd terraform
if [ -f "terraform.tfstate" ]; then
    terraform_outputs=$(terraform output -json 2>/dev/null)
    if [ $? -eq 0 ] && [ "$terraform_outputs" != "{}" ]; then
        echo "✓ Lab 07 Terraform state accessible"
        ((validation_passed++))
    else
        echo "✗ Lab 07 Terraform outputs not available"
        ((validation_failed++))
    fi
else
    echo "✗ Lab 07 Terraform state not found"
    ((validation_failed++))
fi
cd ..

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"
echo "Total checks: $((validation_passed + validation_failed))"

if [ $validation_failed -eq 0 ]; then
    echo
    echo "🎉 Lab 07 validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-07-validation.json << VALIDATION_JSON_END
{
  "lab": "07",
  "status": "PASSED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID",
  "day": 2,
  "integration_verified": true
}
VALIDATION_JSON_END
    
    exit 0
else
    echo
    echo "❌ Lab 07 validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-07-validation.json << VALIDATION_JSON_END
{
  "lab": "07",
  "status": "FAILED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID",
  "day": 2,
  "integration_verified": false
}
VALIDATION_JSON_END
    
    exit 1
fi
VALIDATION_SCRIPT_END

chmod +x validation/validate-lab-07.sh

# Run validation
echo "Running Lab 07 validation..."
cd validation
./validate-lab-07.sh
cd ..
```

### Manual Verification Steps
1. **Visual Inspection**: Check GCP Console for created resources
2. **Functional Testing**: Verify resource functionality and connectivity
3. **Security Review**: Confirm security controls are properly configured
4. **Integration Testing**: Verify integration with Day 1 infrastructure
5. **Performance Testing**: Validate performance and scalability
6. **Documentation**: Ensure all configurations are documented

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Log Sink Permission Issues**
```bash
# Check service account permissions for log sinks
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:serviceAccount"

# Manual permission grant
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:cloud-logs@system.gserviceaccount.com" --role="roles/storage.objectCreator"
```

**Issue 2: BigQuery Dataset Access Issues**
```bash
# Check BigQuery API enablement
gcloud services list --enabled --filter="name:bigquery.googleapis.com"

# Manual dataset creation
bq mk --dataset --location=$REGION ${PROJECT_ID}:techcorp_logs
```

**Issue 3: Log Retention Policy Issues**
```bash
# Check bucket lifecycle policies
gsutil lifecycle get gs://${PROJECT_ID}-audit-logs

# Manual lifecycle policy application
gsutil lifecycle set lifecycle-config.json gs://${PROJECT_ID}-audit-logs
```

**Issue 4: Pub/Sub Topic Creation Issues**
```bash
# Check Pub/Sub API enablement
gcloud services list --enabled --filter="name:pubsub.googleapis.com"

# Manual topic creation
gcloud pubsub topics create techcorp-log-alerts
```

### Day 2 Specific Troubleshooting
- **Integration Issues**: Verify Day 1 labs are completed and validated
- **Resource Dependencies**: Check that prerequisite resources exist
- **Permission Issues**: Ensure service accounts have required advanced permissions
- **API Limitations**: Some advanced features may have quota or regional limitations

### Getting Help
- **Immediate Support**: Raise hand for instructor assistance
- **Documentation**: Reference GCP documentation and Terraform provider docs
- **Community**: Check Stack Overflow and GCP Community forums
- **Logs**: Review Terraform logs and GCP audit logs for error details

## Lab Completion Checklist

### Technical Deliverables
- [ ] All Terraform resources deployed successfully
- [ ] Validation script passes all checks
- [ ] Resources are properly tagged and labeled
- [ ] Security best practices implemented
- [ ] Monitoring and logging configured (where applicable)
- [ ] Integration with Day 1 infrastructure verified
- [ ] Performance and scalability validated
- [ ] Documentation updated

### Knowledge Transfer
- [ ] Understand the purpose of each component created
- [ ] Can explain the architecture to others
- [ ] Know how to troubleshoot common issues
- [ ] Familiar with relevant GCP services and features
- [ ] Understand operational procedures and maintenance

### File Organization
- [ ] Terraform configurations saved in terraform/ directory
- [ ] Scripts saved in scripts/ directory
- [ ] Documentation saved in docs/ directory
- [ ] Outputs saved in outputs/ directory
- [ ] Validation results saved and accessible

## Output Artifacts

```bash
# Save all lab outputs for future reference
mkdir -p outputs

# Terraform outputs
if [ -f terraform/terraform.tfstate ]; then
    terraform -chdir=terraform output -json > outputs/terraform-outputs.json
    echo "✓ Terraform outputs saved"
fi

# Resource inventories (enhanced for Day 2)
gcloud compute instances list --format=json > outputs/compute-instances.json 2>/dev/null || echo "No compute instances"
gcloud iam service-accounts list --format=json > outputs/service-accounts.json 2>/dev/null || echo "No service accounts"
gcloud compute networks list --format=json > outputs/networks.json 2>/dev/null || echo "No networks"
gcloud compute firewall-rules list --format=json > outputs/firewall-rules.json 2>/dev/null || echo "No firewall rules"
gcloud logging sinks list --format=json > outputs/logging-sinks.json 2>/dev/null || echo "No logging sinks"
gcloud monitoring policies list --format=json > outputs/monitoring-policies.json 2>/dev/null || echo "No monitoring policies"
gcloud dns managed-zones list --format=json > outputs/dns-zones.json 2>/dev/null || echo "No DNS zones"

# Configuration backups
cp -r terraform/ outputs/ 2>/dev/null || echo "No terraform directory to backup"
cp -r scripts/ outputs/ 2>/dev/null || echo "No scripts directory to backup"

# Create enhanced lab summary for Day 2
cat > outputs/lab-07-summary.md << 'LAB_SUMMARY_END'
# Lab 07 Summary - Day 2 Advanced Implementation

## Completed: $(date)
## Project: $PROJECT_ID
## Participant: $LAB_USER
## Workshop Day: 2 (Advanced Implementation)

### Resources Created
- [Advanced resources and configurations for Cloud Logging Architecture]

### Key Learnings
- [Advanced technical concepts and enterprise patterns]

### Integration Points
- Integration with Day 1 foundation (Labs 01-06)
- Dependencies on previous Day 2 labs
- Outputs for subsequent advanced labs

### Next Steps
- Proceed to Lab 08
- Review outputs for integration with subsequent labs
- Validate enterprise readiness

### Files Generated
$(ls -la outputs/)

### Day 2 Progress
Lab 07 of 14 completed (Day 2: Lab 1 of 8)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
```

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

```bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab 07:"
    cat outputs/terraform-outputs.json | jq -r 'to_entries[] | "\(.key): \(.value.value)"'
fi

# Show integration with Day 1 foundation
echo "Integration with Day 1 foundation:"
for lab in 01 02 03 04 05 06; do
    if [ -f "../lab-$lab/outputs/terraform-outputs.json" ]; then
        echo "  ✓ Lab $lab outputs available for integration"
    fi
done
```

### Dependencies for Future Labs
- **Lab 08**: Will use [specific outputs] from this lab
- **Integration Points**: [How this lab integrates with overall Day 2 architecture]
- **Enterprise Readiness**: [Production deployment considerations]

## Next Steps

### Immediate Next Steps
1. **Validate Log Flow**: Test that logs are being properly collected and routed to destinations
2. **Review Compliance Settings**: Ensure retention policies meet regulatory requirements
3. **Test Alerting**: Verify that critical log events trigger appropriate alerts
4. **Prepare for Lab 08**: The logging infrastructure will integrate with shared services

### Key Takeaways
- **Centralized Logging**: All logs flow through a unified architecture for compliance and monitoring
- **Compliance Ready**: Retention policies and audit trails meet fintech regulatory requirements
- **Real-time Analysis**: BigQuery integration enables sophisticated log analysis and reporting
- **Security Monitoring**: Log-based metrics provide automated security incident detection

### Preparation for Next Lab
1. **Ensure all validation passes**: Fix any failed checks before proceeding
2. **Review outputs**: Understand what was created and why
3. **Verify integration**: Confirm proper integration with Day 1 foundation
4. **Take a break**: Complex Day 2 labs require mental breaks between sessions
5. **Ask questions**: Clarify any concepts before moving forward

---

## Additional Resources

### Documentation References
- **GCP Documentation**: [Relevant advanced GCP service documentation]
- **Terraform Provider**: [Advanced Terraform provider documentation]
- **Enterprise Best Practices**: [Links to enterprise architectural best practices]
- **Compliance Guidelines**: [Fintech compliance and regulatory guidance]

### Code Samples
- **GitHub Repository**: [Workshop repository with complete solutions]
- **Enterprise Reference Architectures**: [GCP enterprise reference architectures]
- **Production Patterns**: [Real-world production implementation examples]

---

**Lab 07 Complete** ✅

**Estimated Time for Completion**: 45 minutes
**Next Lab**: Lab 08 - [Next lab title]

*Day 2 Focus: Advanced enterprise implementations for production readiness*


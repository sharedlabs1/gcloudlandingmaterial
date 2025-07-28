# Lab 10: Security Controls & Compliance

## Lab Overview

**Duration**: 60 minutes 
**Difficulty**: Advanced  
**Prerequisites**: Successful completion of Labs 01-09 (including workload environments)

### Lab Description
Implement advanced security controls including encryption, key management, security scanning, and compliance monitoring to meet fintech regulatory requirements including PCI DSS, SOX, and industry best practices.

### Business Context
As TechCorp's cloud infrastructure matures, this lab implements advanced operational capabilities essential for production fintech environments, including regulatory compliance, operational excellence, and enterprise-grade automation.

## Learning Objectives

After completing this lab, you will be able to:

• Implement comprehensive encryption with customer-managed keys (CMEK)
• Configure advanced security scanning and vulnerability management
• Set up compliance monitoring and policy enforcement automation
• Implement security incident detection and automated response
• Configure audit logging and compliance reporting
• Set up data loss prevention (DLP) and sensitive data protection
• Implement network security controls and micro-segmentation

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

**Enterprise Security Framework**: Financial services require comprehensive security controls including encryption at rest and in transit, identity and access management, network security, and continuous monitoring. This includes implementing defense-in-depth strategies and zero-trust principles.

**Compliance Automation**: Regulatory compliance requires continuous monitoring, automated policy enforcement, and audit trail generation. This includes PCI DSS for payment processing, SOX for financial reporting, and other industry-specific requirements.

**Key Management**: Customer-managed encryption keys (CMEK) provide additional security and compliance benefits. This includes key rotation, access controls, and integration with Hardware Security Modules (HSMs).

**Security Scanning and Monitoring**: Continuous security assessment includes vulnerability scanning, configuration compliance monitoring, and security incident detection and response automation.

### Architecture Diagram
```
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab 10 Components
Integration with Labs 01-09
```

## Pre-Lab Setup

### Environment Verification
```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-10

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Lab: 10"
echo "Current directory: $(pwd)"

# Check prerequisites from previous labs
echo "Checking previous lab outputs..."
ls -la ../lab-09/outputs/

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
export LAB_PREFIX="lab10"
export TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export LAB_USER=$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}

# Get previous lab outputs for integration
if [ -f "../lab-09/outputs/terraform-outputs.json" ]; then
    echo "✓ Previous lab outputs available for integration"
else
    echo "⚠ Previous lab outputs not found - some integrations may not work"
fi
```

## Lab Implementation

### Step 1: Customer-Managed Encryption Keys (CMEK)

Set up comprehensive encryption with customer-managed keys for enhanced security.

```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-10/terraform

# Create main security configuration
cat > main.tf << 'SECURITY_MAIN_END'
# Lab 10: Security Controls & Compliance
# Advanced security controls for TechCorp enterprise environment

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
    prefix = "lab-10/terraform/state"
  }
}

# Get previous lab outputs for integration
data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

data "terraform_remote_state" "lab08" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-08/terraform/state"
  }
}

data "terraform_remote_state" "lab09" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-09/terraform/state"
  }
}

# Local values for security configuration
locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "10"
    component   = "security"
    environment = "production"
    compliance  = "fintech"
  }
  
  # Key ring locations for different compliance zones
  key_locations = {
    primary   = var.region
    secondary = "us-east1"
    global    = "global"
  }
  
  # Security policies configuration
  security_policies = {
    web_security = {
      name        = "techcorp-web-security"
      description = "Web application security policy"
      rules = [
        {
          priority    = 1000
          action      = "deny(403)"
          description = "Block SQL injection attempts"
          expression  = "evaluatePreconfiguredExpr('sqli-stable')"
        },
        {
          priority    = 2000
          action      = "deny(403)"
          description = "Block XSS attempts"
          expression  = "evaluatePreconfiguredExpr('xss-stable')"
        },
        {
          priority    = 3000
          action      = "rate_based_ban"
          description = "Rate limiting"
          expression  = "true"
        }
      ]
    }
  }
}

# Create primary KMS key ring for application data
resource "google_kms_key_ring" "primary_keyring" {
  name     = "techcorp-primary-keyring"
  location = local.key_locations.primary
  
  depends_on = [google_project_service.kms_api]
}

# Enable required APIs
resource "google_project_service" "security_apis" {
  for_each = toset([
    "cloudkms.googleapis.com",
    "securitycenter.googleapis.com",
    "dlp.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containeranalysis.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Separate KMS API enablement for dependency management
resource "google_project_service" "kms_api" {
  service = "cloudkms.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Create encryption keys for different data types
resource "google_kms_crypto_key" "application_data_key" {
  name     = "techcorp-application-data"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
  
  # Automatic rotation every 90 days for compliance
  rotation_period = "7776000s"  # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = "application-data"
    compliance = "pci-dss"
  })
}

resource "google_kms_crypto_key" "database_key" {
  name     = "techcorp-database-encryption"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
  
  rotation_period = "7776000s"  # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = "database-encryption"
    compliance = "sox"
  })
}

resource "google_kms_crypto_key" "backup_key" {
  name     = "techcorp-backup-encryption"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
  
  rotation_period = "15552000s"  # 180 days (longer for backups)
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = "backup-encryption"
    compliance = "general"
  })
}

# Create secondary key ring for DR/backup
resource "google_kms_key_ring" "secondary_keyring" {
  name     = "techcorp-secondary-keyring"
  location = local.key_locations.secondary
  
  depends_on = [google_project_service.kms_api]
}

resource "google_kms_crypto_key" "dr_key" {
  name     = "techcorp-disaster-recovery"
  key_ring = google_kms_key_ring.secondary_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
  
  rotation_period = "31536000s"  # 1 year for DR
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = "disaster-recovery"
    compliance = "business-continuity"
  })
}
SECURITY_MAIN_END

echo "✓ Security main configuration created"
```

### Step 2: Advanced Security Policies and Cloud Armor

Configure Web Application Firewall and security policies.

```bash
# Add security policies configuration
cat >> main.tf << 'SECURITY_POLICIES_END'

# Create Cloud Armor security policy for web applications
resource "google_compute_security_policy" "web_security_policy" {
  name        = "techcorp-web-security-policy"
  description = "Security policy for TechCorp web applications"
  
  # Default rule - allow all traffic not matching other rules
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }
  
  # Block known malicious IPs
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "203.0.113.0/24",  # Example malicious range
          "198.51.100.0/24"  # Example malicious range
        ]
      }
    }
    description = "Block known malicious IP ranges"
  }
  
  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Rate limiting: 100 requests per minute per IP"
  }
  
  # SQL injection protection
  rule {
    action   = "deny(403)"
    priority = "3000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "Block SQL injection attempts"
  }
  
  # XSS protection
  rule {
    action   = "deny(403)"
    priority = "4000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "Block XSS attempts"
  }
  
  # Geographic restriction (example: block traffic from certain countries)
  rule {
    action   = "deny(403)"
    priority = "5000"
    match {
      expr {
        expression = "origin.region_code == 'CN' || origin.region_code == 'RU'"
      }
    }
    description = "Geographic restrictions for compliance"
  }
  
  # Advanced threat protection
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

# Apply security policy to load balancer backend
resource "google_compute_backend_service" "secure_web_backend" {
  name        = "techcorp-secure-web-backend"
  description = "Secure backend service with Cloud Armor protection"
  protocol    = "HTTP"
  timeout_sec = 30
  
  backend {
    group           = data.terraform_remote_state.lab09.outputs.instance_groups.web.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
  
  health_checks   = [data.terraform_remote_state.lab09.outputs.health_checks.web.id]
  security_policy = google_compute_security_policy.web_security_policy.id
  
  # Enable Cloud CDN for performance and additional security
  enable_cdn = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl          = 86400
    negative_caching = true
    
    # Security headers
    negative_caching_policy {
      code = 404
      ttl  = 60
    }
  }
  
  # Connection draining
  connection_draining_timeout_sec = 300
  
  # Comprehensive logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
SECURITY_POLICIES_END

echo "✓ Security policies configuration added"
```

### Step 3: Data Loss Prevention (DLP) and Sensitive Data Protection

Set up DLP scanning and protection for sensitive data.

```bash
# Add DLP configuration
cat >> main.tf << 'DLP_CONFIG_END'

# Create DLP inspect template for financial data
resource "google_data_loss_prevention_inspect_template" "financial_data_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for detecting financial sensitive data"
  display_name = "TechCorp Financial Data Detection"
  
  inspect_config {
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "US_SOCIAL_SECURITY_NUMBER"
    }
    info_types {
      name = "US_BANK_ROUTING_MICR"
    }
    info_types {
      name = "IBAN_CODE"
    }
    info_types {
      name = "SWIFT_CODE"
    }
    
    # Custom info type for TechCorp customer IDs
    custom_info_types {
      info_type {
        name = "TECHCORP_CUSTOMER_ID"
      }
      regex {
        pattern = "TC[0-9]{8}"
      }
      likelihood = "LIKELY"
    }
    
    # Minimum likelihood threshold
    min_likelihood = "POSSIBLE"
    
    # Limits for performance
    limits {
      max_findings_per_info_type {
        info_type {
          name = "CREDIT_CARD_NUMBER"
        }
        max_findings = 100
      }
      max_findings_per_request = 1000
    }
  }
}

# Create DLP de-identification template
resource "google_data_loss_prevention_deidentify_template" "financial_deidentify_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for de-identifying financial data"
  display_name = "TechCorp Financial Data De-identification"
  
  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "CREDIT_CARD_NUMBER"
        }
        primitive_transformation {
          crypto_replace_ffx_fpe_config {
            crypto_key {
              kms_wrapped {
                wrapped_key   = google_kms_crypto_key.application_data_key.id
                crypto_key_name = google_kms_crypto_key.application_data_key.id
              }
            }
            alphabet = "NUMERIC"
          }
        }
      }
      
      transformations {
        info_types {
          name = "US_SOCIAL_SECURITY_NUMBER"
        }
        primitive_transformation {
          crypto_hash_config {
            crypto_key {
              kms_wrapped {
                wrapped_key   = google_kms_crypto_key.application_data_key.id
                crypto_key_name = google_kms_crypto_key.application_data_key.id
              }
            }
          }
        }
      }
    }
  }
}

# Create DLP job trigger for continuous scanning
resource "google_data_loss_prevention_job_trigger" "storage_scan_trigger" {
  parent       = "projects/${var.project_id}"
  description  = "Scan Cloud Storage for sensitive financial data"
  display_name = "TechCorp Storage Scanner"
  
  triggers {
    schedule {
      recurrence_period_duration = "86400s"  # Daily scan
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.financial_data_template.id
    
    storage_config {
      cloud_storage_options {
        file_set {
          url = "gs://${data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket}/*"
        }
        
        bytes_limit_per_file      = 104857600  # 100MB
        bytes_limit_per_file_percent = 10
        file_types = ["CSV", "JSON", "TEXT_FILE"]
        sample_method = "RANDOM_START"
      }
      
      timespan_config {
        start_time = "2023-01-01T00:00:00Z"
        timestamp_field {
          name = "timestamp"
        }
      }
    }
    
    actions {
      pub_sub {
        topic = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
      }
    }
    
    actions {
      save_findings {
        output_config {
          table {
            project_id = var.project_id
            dataset_id = "techcorp_security"
            table_id   = "dlp_findings"
          }
        }
      }
    }
  }
  
  status = "HEALTHY"
}

# Create BigQuery dataset for security findings
resource "google_bigquery_dataset" "security_dataset" {
  dataset_id  = "techcorp_security"
  description = "Dataset for security findings and compliance data"
  location    = var.region
  
  # Access controls
  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  
  access {
    role   = "WRITER"
    group_by_email = "security-team@techcorp.com"  # Example security team
  }
  
  labels = merge(local.common_labels, {
    purpose = "security-findings"
    compliance = "pci-dss"
  })
}
DLP_CONFIG_END

echo "✓ DLP configuration added"
```

### Step 4: Security Monitoring and Incident Response

Set up comprehensive security monitoring and automated response.

```bash
# Add security monitoring configuration
cat >> main.tf << 'SECURITY_MONITORING_END'

# Create Security Command Center notification config
resource "google_scc_notification_config" "security_notifications" {
  config_id    = "techcorp-security-notifications"
  organization = var.organization_id  # Set by instructor if available
  description  = "Security Command Center notifications for TechCorp"
  
  pubsub_topic = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
  
  streaming_config {
    filter = <<-EOT
      (category="MALWARE" OR 
       category="SUSPICIOUS_ACTIVITY" OR 
       category="VULNERABILITY" OR
       category="DATA_EXFILTRATION") AND
      state="ACTIVE"
    EOT
  }
}

# Create custom security findings
resource "google_scc_source" "techcorp_security_source" {
  count = var.organization_id != "" ? 1 : 0
  
  display_name = "TechCorp Custom Security Scanner"
  organization = var.organization_id
  description  = "Custom security findings from TechCorp application security scans"
}

# Create monitoring alert policy for security events
resource "google_monitoring_alert_policy" "security_incidents" {
  display_name = "TechCorp Security Incidents"
  combiner     = "OR"
  
  conditions {
    display_name = "High severity security findings"
    
    condition_threshold {
      filter         = "resource.type=\"gce_instance\" AND metric.type=\"logging.googleapis.com/user/security_events\""
      duration       = "300s"
      comparison     = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }
  
  notification_channels = []  # Would be configured with actual notification channels
  
  alert_strategy {
    auto_close = "604800s"  # 7 days
  }
  
  enabled = true
}

# Create log-based metric for security events
resource "google_logging_metric" "security_events_metric" {
  name   = "techcorp_security_events"
  filter = <<-EOT
    (jsonPayload.severity="HIGH" OR jsonPayload.severity="CRITICAL") AND
    (jsonPayload.category="SECURITY" OR 
     jsonPayload.event_type="UNAUTHORIZED_ACCESS" OR
     jsonPayload.event_type="SUSPICIOUS_ACTIVITY")
  EOT
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Security Events Count"
  }
  
  label_extractors = {
    "severity" = "EXTRACT(jsonPayload.severity)"
    "category" = "EXTRACT(jsonPayload.category)"
    "source_ip" = "EXTRACT(jsonPayload.source_ip)"
  }
}

# Create Cloud Function for automated security response
resource "google_storage_bucket_object" "security_response_function" {
  name   = "security-response-function.zip"
  bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  content = base64encode("# Placeholder for security response function code")
}

resource "google_cloudfunctions_function" "security_response" {
  name        = "techcorp-security-response"
  description = "Automated security incident response function"
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  source_archive_object = google_storage_bucket_object.security_response_function.name
  entry_point          = "security_response_handler"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    ALERT_TOPIC = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
    KMS_KEY = google_kms_crypto_key.application_data_key.id
  }
  
  labels = local.common_labels
}

# Create firewall rules for micro-segmentation
resource "google_compute_firewall" "deny_all_internal" {
  name    = "techcorp-deny-all-internal"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  deny {
    protocol = "tcp"
  }
  deny {
    protocol = "udp"
  }
  deny {
    protocol = "icmp"
  }
  
  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["deny-internal"]
  priority      = 1000
  
  description = "Default deny rule for micro-segmentation"
}

resource "google_compute_firewall" "allow_web_to_app" {
  name    = "techcorp-allow-web-to-app"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  allow {
    protocol = "tcp"
    ports    = ["8080", "443"]
  }
  
  source_tags = ["techcorp-web-tier"]
  target_tags = ["techcorp-app-tier"]
  priority    = 900
  
  description = "Allow web tier to communicate with app tier"
}

resource "google_compute_firewall" "allow_app_to_db" {
  name    = "techcorp-allow-app-to-db"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  allow {
    protocol = "tcp"
    ports    = ["5432", "3306"]
  }
  
  source_tags = ["techcorp-app-tier"]
  target_tags = ["techcorp-database-tier"]
  priority    = 900
  
  description = "Allow app tier to communicate with database tier"
}

# Data source for current user
data "google_client_openid_userinfo" "current" {}
SECURITY_MONITORING_END

echo "✓ Security monitoring configuration added"
```

### Step 5: Binary Authorization and Container Security

Configure container security and binary authorization for GKE.

```bash
# Add container security configuration
cat >> main.tf << 'CONTAINER_SECURITY_END'

# Create Binary Authorization policy
resource "google_binary_authorization_policy" "policy" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }
  
  admission_whitelist_patterns {
    name_pattern = "us-docker.pkg.dev/${var.project_id}/*"
  }
  
  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.build_attestor.name]
  }
  
  # Allow specific system images
  cluster_admission_rules {
    cluster                 = data.terraform_remote_state.lab09.outputs.gke_cluster.name
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.build_attestor.name]
  }
}

# Create attestor for build verification
resource "google_binary_authorization_attestor" "build_attestor" {
  name = "techcorp-build-attestor"
  description = "Attestor for TechCorp build verification"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.build_note.name
    public_keys {
      id = "techcorp-build-key"
      ascii_armored_pgp_public_key = var.pgp_public_key  # Would be provided
    }
  }
}

# Create Container Analysis note
resource "google_container_analysis_note" "build_note" {
  name = "techcorp-build-note"
  
  attestation_authority {
    hint {
      human_readable_name = "TechCorp Build Verification"
    }
  }
}

# Create vulnerability scanning configuration
resource "google_container_analysis_note" "vulnerability_note" {
  name = "techcorp-vulnerability-note"
  
  vulnerability {
    details {
      package = "TechCorp Security Scanner"
      package_type = "GENERIC"
      severity_name = "HIGH"
      description = "Automated vulnerability scanning for TechCorp containers"
    }
  }
}

# Create Kubernetes network policies (via ConfigMap)
resource "google_storage_bucket_object" "network_policies" {
  name   = "k8s-network-policies.yaml"
  bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  content = <<-EOT
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-default-deny
      namespace: default
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
      - Egress
    ---
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-web-policy
      namespace: default
    spec:
      podSelector:
        matchLabels:
          tier: web
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
        ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
      egress:
      - to:
        - podSelector:
            matchLabels:
              tier: app
        ports:
        - protocol: TCP
          port: 8080
    ---
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-app-policy
      namespace: default
    spec:
      podSelector:
        matchLabels:
          tier: app
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - podSelector:
            matchLabels:
              tier: web
        ports:
        - protocol: TCP
          port: 8080
      egress:
      - to:
        - podSelector:
            matchLabels:
              tier: database
        ports:
        - protocol: TCP
          port: 5432
  EOT
}
CONTAINER_SECURITY_END

echo "✓ Container security configuration added"
```

## Expected Deliverables

Upon successful completion of this lab, you should have:

• Customer-managed encryption keys (CMEK) with automatic rotation for all data types
• Cloud Armor security policies with WAF protection, rate limiting, and geographic restrictions
• Data Loss Prevention (DLP) scanning with automated de-identification of sensitive data
• Security Command Center integration with automated incident response
• Binary Authorization for container security and build verification
• Network micro-segmentation with firewall rules and Kubernetes network policies
• Comprehensive security monitoring with log-based metrics and alerting
• Compliance automation for PCI DSS, SOX, and other fintech requirements

## Validation and Testing

### Automated Validation
```bash
# Create comprehensive validation script
cat > validation/validate-lab-10.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab 10 Validation Script ==="
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

# Check KMS key rings and keys
echo "Checking KMS infrastructure..."
keyrings=("techcorp-primary-keyring" "techcorp-secondary-keyring")
for keyring in "${keyrings[@]}"; do
    if gcloud kms keyrings describe $keyring --location=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo "✓ KMS keyring created: $keyring"
        ((validation_passed++))
        
        # Check keys in keyring
        key_count=$(gcloud kms keys list --keyring=$keyring --location=$REGION --format="value(name)" | wc -l)
        if [ $key_count -gt 0 ]; then
            echo "✓ Encryption keys found in $keyring: $key_count keys"
            ((validation_passed++))
        else
            echo "✗ No encryption keys found in $keyring"
            ((validation_failed++))
        fi
    else
        echo "✗ KMS keyring missing: $keyring"
        ((validation_failed++))
    fi
done

# Check Cloud Armor security policy
echo "Checking Cloud Armor security policies..."
if gcloud compute security-policies describe techcorp-web-security-policy --global --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Cloud Armor security policy created"
    ((validation_passed++))
    
    # Check security rules
    rule_count=$(gcloud compute security-policies describe techcorp-web-security-policy --global --format="value(rules.length())")
    if [ $rule_count -gt 5 ]; then
        echo "✓ Security policy rules configured: $rule_count rules"
        ((validation_passed++))
    else
        echo "✗ Insufficient security policy rules: $rule_count"
        ((validation_failed++))
    fi
else
    echo "✗ Cloud Armor security policy missing"
    ((validation_failed++))
fi

# Check DLP templates
echo "Checking DLP templates..."
dlp_templates=$(gcloud dlp inspect-templates list --format="value(name)" | grep techcorp | wc -l)
if [ $dlp_templates -gt 0 ]; then
    echo "✓ DLP inspect templates created: $dlp_templates templates"
    ((validation_passed++))
else
    echo "✗ DLP inspect templates missing"
    ((validation_failed++))
fi

deidentify_templates=$(gcloud dlp deidentify-templates list --format="value(name)" | grep techcorp | wc -l)
if [ $deidentify_templates -gt 0 ]; then
    echo "✓ DLP de-identify templates created: $deidentify_templates templates"
    ((validation_passed++))
else
    echo "✗ DLP de-identify templates missing"
    ((validation_failed++))
fi

# Check DLP job triggers
echo "Checking DLP job triggers..."
job_triggers=$(gcloud dlp job-triggers list --format="value(name)" | grep techcorp | wc -l)
if [ $job_triggers -gt 0 ]; then
    echo "✓ DLP job triggers created: $job_triggers triggers"
    ((validation_passed++))
else
    echo "✗ DLP job triggers missing"
    ((validation_failed++))
fi

# Check BigQuery security dataset
echo "Checking security BigQuery dataset..."
if bq show --dataset ${PROJECT_ID}:techcorp_security &>/dev/null; then
    echo "✓ Security BigQuery dataset created"
    ((validation_passed++))
else
    echo "✗ Security BigQuery dataset missing"
    ((validation_failed++))
fi

# Check security monitoring resources
echo "Checking security monitoring..."
if gcloud logging metrics describe techcorp_security_events --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Security events log metric created"
    ((validation_passed++))
else
    echo "✗ Security events log metric missing"
    ((validation_failed++))
fi

# Check monitoring alert policies
security_policies=$(gcloud alpha monitoring policies list --filter="displayName:TechCorp Security" --format="value(name)" | wc -l)
if [ $security_policies -gt 0 ]; then
    echo "✓ Security monitoring alert policies created"
    ((validation_passed++))
else
    echo "✗ Security monitoring alert policies missing"
    ((validation_failed++))
fi

# Check Cloud Functions for security response
echo "Checking security response automation..."
if gcloud functions describe techcorp-security-response --region=$REGION --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Security response Cloud Function created"
    ((validation_passed++))
else
    echo "✗ Security response Cloud Function missing"
    ((validation_failed++))
fi

# Check firewall rules for micro-segmentation
echo "Checking micro-segmentation firewall rules..."
security_fw_rules=("techcorp-deny-all-internal" "techcorp-allow-web-to-app" "techcorp-allow-app-to-db")
for rule in "${security_fw_rules[@]}"; do
    if gcloud compute firewall-rules describe $rule --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Firewall rule created: $rule"
        ((validation_passed++))
    else
        echo "✗ Firewall rule missing: $rule"
        ((validation_failed++))
    fi
done

# Check Binary Authorization policy
echo "Checking Binary Authorization..."
if gcloud container binauthz policy describe --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Binary Authorization policy configured"
    ((validation_passed++))
else
    echo "✗ Binary Authorization policy missing"
    ((validation_failed++))
fi

# Check attestors
attestor_count=$(gcloud container binauthz attestors list --format="value(name)" | wc -l)
if [ $attestor_count -gt 0 ]; then
    echo "✓ Binary Authorization attestors created: $attestor_count"
    ((validation_passed++))
else
    echo "✗ Binary Authorization attestors missing"
    ((validation_failed++))
fi

# Check Container Analysis notes
echo "Checking Container Analysis..."
analysis_notes=$(gcloud alpha container analysis notes list --format="value(name)" | grep techcorp | wc -l)
if [ $analysis_notes -gt 0 ]; then
    echo "✓ Container Analysis notes created: $analysis_notes"
    ((validation_passed++))
else
    echo "✗ Container Analysis notes missing"
    ((validation_failed++))
fi

# Check API enablement for security services
echo "Checking security APIs..."
security_apis=("cloudkms.googleapis.com" "securitycenter.googleapis.com" "dlp.googleapis.com" "binaryauthorization.googleapis.com")
for api in "${security_apis[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        echo "✓ Security API enabled: $api"
        ((validation_passed++))
    else
        echo "✗ Security API not enabled: $api"
        ((validation_failed++))
    fi
done

# Check Terraform outputs
echo "Checking Terraform outputs..."
cd terraform
terraform_outputs=$(terraform output -json 2>/dev/null)
if [ $? -eq 0 ] && [ "$terraform_outputs" != "{}" ]; then
    echo "✓ Terraform outputs available"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=("kms_keys" "security_policies" "dlp_templates" "security_monitoring")
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
        echo "✓ Lab 10 Terraform state accessible"
        ((validation_passed++))
    else
        echo "✗ Lab 10 Terraform outputs not available"
        ((validation_failed++))
    fi
else
    echo "✗ Lab 10 Terraform state not found"
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
    echo "🎉 Lab 10 validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-10-validation.json << VALIDATION_JSON_END
{
  "lab": "10",
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
    echo "❌ Lab 10 validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-10-validation.json << VALIDATION_JSON_END
{
  "lab": "10",
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

chmod +x validation/validate-lab-10.sh

# Run validation
echo "Running Lab 10 validation..."
cd validation
./validate-lab-10.sh
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

**Issue 1: KMS Permission Issues**
```bash
# Check KMS API enablement
gcloud services list --enabled --filter="name:cloudkms.googleapis.com"

# Check KMS permissions
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.role:roles/cloudkms"

# Manual key creation test
gcloud kms keyrings create test-keyring --location=$REGION
```

**Issue 2: Cloud Armor Configuration Issues**
```bash
# Check Compute Engine API
gcloud services list --enabled --filter="name:compute.googleapis.com"

# Manual security policy creation
gcloud compute security-policies create test-policy --description="Test policy"
```

**Issue 3: DLP API Issues**
```bash
# Check DLP API enablement
gcloud services list --enabled --filter="name:dlp.googleapis.com"

# Test DLP access
gcloud dlp inspect-templates list --format="table(name)"
```

**Issue 4: Binary Authorization Issues**
```bash
# Check Binary Authorization API
gcloud services list --enabled --filter="name:binaryauthorization.googleapis.com"

# Check GKE cluster configuration
gcloud container clusters describe techcorp-microservices --region=$REGION
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
cat > outputs/lab-10-summary.md << 'LAB_SUMMARY_END'
# Lab 10 Summary - Day 2 Advanced Implementation

## Completed: $(date)
## Project: $PROJECT_ID
## Participant: $LAB_USER
## Workshop Day: 2 (Advanced Implementation)

### Resources Created
- [Advanced resources and configurations for Security Controls & Compliance]

### Key Learnings
- [Advanced technical concepts and enterprise patterns]

### Integration Points
- Integration with Day 1 foundation (Labs 01-06)
- Dependencies on previous Day 2 labs
- Outputs for subsequent advanced labs

### Next Steps
- Proceed to Lab 11
- Review outputs for integration with subsequent labs
- Validate enterprise readiness

### Files Generated
$(ls -la outputs/)

### Day 2 Progress
Lab 10 of 14 completed (Day 2: Lab 4 of 8)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
```

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

```bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab 10:"
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
- **Lab 11**: Will use [specific outputs] from this lab
- **Integration Points**: [How this lab integrates with overall Day 2 architecture]
- **Enterprise Readiness**: [Production deployment considerations]

## Next Steps

### Immediate Next Steps
1. **Test Security Controls**: Verify that WAF rules and DLP scanning are working
2. **Validate Encryption**: Ensure all data is encrypted with customer-managed keys
3. **Review Compliance**: Check that all fintech regulatory requirements are met
4. **Prepare for Lab 11**: Security infrastructure will integrate with advanced monitoring

### Key Takeaways
- **Defense in Depth**: Multiple layers of security controls protect against various threats
- **Compliance Automation**: Automated scanning and monitoring ensure continuous compliance
- **Key Management**: Customer-managed encryption provides enhanced security and control
- **Incident Response**: Automated security response reduces time to mitigation

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

**Lab 10 Complete** ✅

**Estimated Time for Completion**: 60 minutes
**Next Lab**: Lab 11 - [Next lab title]

*Day 2 Focus: Advanced enterprise implementations for production readiness*


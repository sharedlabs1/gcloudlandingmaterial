# Lab 10 Solution: Security Controls & Compliance
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
    prefix = "lab-10/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "10"
    component   = "security"
    environment = "production"
    compliance  = "fintech"
  }
}

# Enable required APIs
resource "google_project_service" "security_apis" {
  for_each = toset([
    "cloudkms.googleapis.com",
    "dlp.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containeranalysis.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
}

# Create KMS key ring and keys
resource "google_kms_key_ring" "primary_keyring" {
  name     = "techcorp-primary-keyring"
  location = var.region
  
  depends_on = [google_project_service.security_apis]
}

resource "google_kms_crypto_key" "application_data_key" {
  name     = "techcorp-application-data"
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

# Create Cloud Armor security policy
resource "google_compute_security_policy" "web_security_policy" {
  name        = "techcorp-web-security-policy"
  description = "Security policy for TechCorp web applications"
  
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
  
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "203.0.113.0/24",
          "198.51.100.0/24"
        ]
      }
    }
    description = "Block known malicious IP ranges"
  }
  
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
}

# Create DLP inspect template
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
    
    custom_info_types {
      info_type {
        name = "TECHCORP_CUSTOMER_ID"
      }
      regex {
        pattern = "TC[0-9]{8}"
      }
      likelihood = "LIKELY"
    }
    
    min_likelihood = "POSSIBLE"
    
    limits {
      max_findings_per_request = 1000
    }
  }
}

# Create DLP deidentify template
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
                wrapped_key     = google_kms_crypto_key.application_data_key.id
                crypto_key_name = google_kms_crypto_key.application_data_key.id
              }
            }
            alphabet = "NUMERIC"
          }
        }
      }
    }
  }
}

# Create Binary Authorization policy
resource "google_binary_authorization_policy" "policy" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }
  
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.build_attestor.name]
  }
}

resource "google_binary_authorization_attestor" "build_attestor" {
  name = "techcorp-build-attestor"
  description = "Attestor for TechCorp build verification"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.build_note.name
    public_keys {
      id = "techcorp-build-key"
      ascii_armored_pgp_public_key = var.pgp_public_key
    }
  }
}

resource "google_container_analysis_note" "build_note" {
  name = "techcorp-build-note"
  
  attestation_authority {
    hint {
      human_readable_name = "TechCorp Build Verification"
    }
  }
}

# Create BigQuery dataset for security findings
resource "google_bigquery_dataset" "security_dataset" {
  dataset_id  = "techcorp_security"
  description = "Dataset for security findings and compliance data"
  location    = var.region
  
  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  labels = merge(local.common_labels, {
    purpose = "security-findings"
    compliance = "pci-dss"
  })
}

data "google_client_openid_userinfo" "current" {}

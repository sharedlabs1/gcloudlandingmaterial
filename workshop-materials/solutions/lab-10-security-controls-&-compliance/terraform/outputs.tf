# Outputs for Lab 10

output "lab_10_resources" {
  description = "Resources created in Lab 10"
  value = {
    lab_number = "10"
    project_id = var.project_id
    region     = var.region
  }
}

output "kms_keys" {
  description = "Created KMS keys"
  value = {
    application_key = google_kms_crypto_key.application_data_key.id
    database_key    = google_kms_crypto_key.database_key.id
  }
}

output "security_policy" {
  description = "Cloud Armor security policy"
  value = {
    name = google_compute_security_policy.web_security_policy.name
    id   = google_compute_security_policy.web_security_policy.id
  }
}

output "dlp_templates" {
  description = "DLP templates"
  value = {
    inspect_template    = google_data_loss_prevention_inspect_template.financial_data_template.id
    deidentify_template = google_data_loss_prevention_deidentify_template.financial_deidentify_template.id
  }
}

output "binary_authorization" {
  description = "Binary Authorization configuration"
  value = {
    attestor = google_binary_authorization_attestor.build_attestor.name
  }
}

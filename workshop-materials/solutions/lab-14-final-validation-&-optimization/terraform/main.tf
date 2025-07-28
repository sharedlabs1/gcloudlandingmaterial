# Lab 14 Solution: Final Validation & Optimization
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
    prefix = "lab-14/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get previous lab outputs for integration
data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "14"
    environment = "production"
    component   = "final-validation-&-optimization"
  }
}

# Lab-specific resources for Final Validation & Optimization
# This is a template solution - actual implementation would include:
# - End-to-end validation framework
# - Performance testing and optimization
# - Production readiness assessment
# - Final architecture review

# Enable required APIs for this lab
resource "google_project_service" "lab_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
}

# Placeholder resource - would be replaced with actual lab resources
resource "google_storage_bucket" "lab_14_bucket" {
  name     = "${var.project_id}-lab-14-resources"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = local.common_labels
}

data "google_client_openid_userinfo" "current" {}

# Lab 06 Solution: Cloud Monitoring Foundation
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
    prefix = "lab-06/terraform/state"
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
    lab         = "06"
    environment = "production"
    component   = "cloud-monitoring-foundation"
  }
}

# Lab-specific resources for Cloud Monitoring Foundation
# This is a template solution - actual implementation would include:
# - Monitoring workspace setup
# - Custom metrics and dashboards
# - Alerting policies and notification channels
# - SLI/SLO monitoring infrastructure

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
resource "google_storage_bucket" "lab_06_bucket" {
  name     = "${var.project_id}-lab-06-resources"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = local.common_labels
}

data "google_client_openid_userinfo" "current" {}

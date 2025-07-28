# Lab 05 Solution: Identity and Access Management
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
    prefix = "lab-05/terraform/state"
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
    lab         = "05"
    environment = "production"
    component   = "identity-and-access-management"
  }
}

# Lab-specific resources for Identity and Access Management
# This is a template solution - actual implementation would include:
# - Custom IAM roles and policies
# - Service account management
# - Workload Identity configuration
# - Access control automation

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
resource "google_storage_bucket" "lab_05_bucket" {
  name     = "${var.project_id}-lab-05-resources"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = local.common_labels
}

data "google_client_openid_userinfo" "current" {}

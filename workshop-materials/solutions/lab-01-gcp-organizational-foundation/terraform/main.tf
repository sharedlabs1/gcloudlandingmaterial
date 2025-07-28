# Lab 01 Solution: GCP Organizational Foundation
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
    prefix = "lab-01/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_tags = {
    workshop    = "gcp-landing-zone"
    lab         = "01"
    created_by  = "terraform"
    environment = "workshop"
  }
  
  environments = {
    shared-services = "Shared Services"
    development     = "Development"
    staging         = "Staging"
    production      = "Production (Simulated)"
  }
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
}

# Create service accounts for each environment
resource "google_service_account" "environment_sa" {
  for_each = local.environments
  
  account_id   = "workshop-${each.key}-sa"
  display_name = "${each.value} Service Account"
  description  = "Service account for ${each.value} environment"
}

# Create storage buckets for each environment
resource "google_storage_bucket" "environment_buckets" {
  for_each = local.environments
  
  name     = "${var.project_id}-${each.key}-workshop-storage"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_tags, {
    environment = each.key
  })
}

# Project metadata
resource "google_compute_project_metadata" "workshop_metadata" {
  metadata = {
    enable-oslogin = "TRUE"
    workshop       = "gcp-landing-zone"
    lab           = "01"
  }
}

data "google_client_openid_userinfo" "current" {}

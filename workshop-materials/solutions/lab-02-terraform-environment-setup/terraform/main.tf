# Lab 02 Solution: Terraform Environment Setup
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
    prefix = "lab-02/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get lab 01 outputs
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

locals {
  subnet_config = {
    "shared-mgmt" = {
      cidr        = "10.0.0.0/24"
      region      = var.region
      description = "Management subnet"
    }
    "dev-web" = {
      cidr        = "10.1.0.0/22"
      region      = var.region
      description = "Development web tier"
    }
    "dev-app" = {
      cidr        = "10.1.4.0/22"
      region      = var.region
      description = "Development app tier"
    }
  }
}

# Create VPC using module
module "shared_vpc" {
  source = "../modules/vpc-network"
  
  project_id   = var.project_id
  network_name = "techcorp-shared-vpc"
  region       = var.region
  subnets      = local.subnet_config
}

# Create IAM using module
module "iam_structure" {
  source = "../modules/iam-bindings"
  
  project_id = var.project_id
  
  service_accounts = {
    "web-tier-sa" = {
      display_name = "Web Tier Service Account"
      description  = "Service account for web tier"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter"
      ]
    }
    "app-tier-sa" = {
      display_name = "App Tier Service Account"
      description  = "Service account for app tier"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
        "roles/storage.objectAdmin"
      ]
    }
  }
}

data "google_client_openid_userinfo" "current" {}

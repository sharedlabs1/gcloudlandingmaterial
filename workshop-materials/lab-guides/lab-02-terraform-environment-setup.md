# Lab 02: Terraform Environment Setup

## Lab Overview

**Duration**: 45 minutes 
**Difficulty**: Beginner  
**Prerequisites**: Successful completion of Lab 01 with all projects created and accessible

### Lab Description
Configure a robust, enterprise-grade Terraform environment with remote state management, module architecture, security best practices, and automation capabilities for the TechCorp landing zone.

### Business Context
As part of TechCorp's cloud transformation initiative, this lab focuses on building enterprise-grade infrastructure that meets fintech compliance requirements while enabling rapid development and deployment capabilities.

## Learning Objectives

After completing this lab, you will be able to:

• Configure Terraform remote state backend with Cloud Storage including versioning and encryption
• Create comprehensive reusable Terraform module structure for VPC, IAM, and monitoring components
• Set up dedicated service accounts for Terraform automation with minimal required permissions
• Implement Terraform security best practices including state encryption and access controls
• Configure Terraform workspace management for multi-environment deployments
• Set up validation and testing framework for Terraform configurations

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

**Terraform State Management**: Remote state backends provide centralized state storage, enabling team collaboration and preventing state conflicts. GCS backend offers versioning, encryption, and access controls for production environments.

**Module Architecture**: Terraform modules enable code reusability, consistency, and maintainability. Well-designed modules encapsulate resources and provide clear interfaces through variables and outputs.

**Security Best Practices**: Terraform security involves secure state storage, service account authentication, secret management, and resource access controls. Production environments require encrypted state, minimal permissions, and audit logging.

**Automation and CI/CD**: Terraform automation includes plan validation, automated testing, approval workflows, and deployment pipelines. This enables safe, repeatable infrastructure deployments.

### Architecture Diagram
```
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab 02 Components
```

## Pre-Lab Setup

### Environment Verification
```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-02

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Lab: 02"
echo "Current directory: $(pwd)"

# Check prerequisites from previous labs
if [ "02" != "01" ]; then
    echo "Checking previous lab outputs..."
    ls -la ../lab-01/outputs/
fi
```

### Required Variables
```bash
# Set lab-specific variables
export LAB_PREFIX="lab02"
export TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export LAB_USER=$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}
```

## Lab Implementation

### Step 1: Advanced State Backend Configuration

Configure enterprise-grade remote state management with security and versioning.

```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-02/terraform

# Create enhanced backend configuration
cat > backend.tf << 'BACKEND_ENHANCED_END'
# Enhanced Terraform backend configuration for enterprise use
terraform {
  backend "gcs" {
    bucket                      = "${TF_STATE_BUCKET}"
    prefix                      = "environments/lab-02"
    impersonate_service_account = "terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"
    encryption_key              = "${KMS_KEY_NAME}"  # Will be set up in this lab
  }
}

# Required provider versions with specific constraints
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
BACKEND_ENHANCED_END

echo "✓ Enhanced backend configuration created"
```

### Step 2: Create Terraform Service Account and KMS Setup

Set up dedicated automation service account and encryption for state files.

```bash
# Create service account and KMS configuration
cat > automation-setup.tf << 'AUTOMATION_TF_END'
# Terraform automation service account and security setup

# Create KMS keyring for Terraform state encryption
resource "google_kms_key_ring" "terraform_state" {
  name     = "terraform-state-keyring"
  location = var.region
  project  = var.project_id
}

# Create KMS key for state encryption
resource "google_kms_crypto_key" "terraform_state" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_state.id
  purpose  = "ENCRYPT_DECRYPT"
  
  lifecycle {
    prevent_destroy = true
  }
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
}

# Create dedicated Terraform automation service account
resource "google_service_account" "terraform_automation" {
  account_id   = "terraform-automation"
  display_name = "Terraform Automation Service Account"
  description  = "Service account for automated Terraform operations"
  project      = var.project_id
}

# Grant minimal required permissions to Terraform service account
resource "google_project_iam_member" "terraform_automation_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.admin",
    "roles/monitoring.admin",
    "roles/logging.admin",
    "roles/dns.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_automation.email}"
}

# Grant KMS permissions for state encryption
resource "google_kms_crypto_key_iam_member" "terraform_state_key" {
  crypto_key_id = google_kms_crypto_key.terraform_state.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.terraform_automation.email}"
}

# Create service account key for automation (in production, use Workload Identity)
resource "google_service_account_key" "terraform_automation" {
  service_account_id = google_service_account.terraform_automation.name
  
  # Store in terraform state only - in production use secret manager
  keepers = {
    rotation_time = timestamp()
  }
}

# Store service account key in Secret Manager
resource "google_secret_manager_secret" "terraform_sa_key" {
  secret_id = "terraform-automation-key"
  project   = var.project_id
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "terraform_sa_key" {
  secret      = google_secret_manager_secret.terraform_sa_key.id
  secret_data = base64decode(google_service_account_key.terraform_automation.private_key)
}
AUTOMATION_TF_END

echo "✓ Automation setup configuration created"
```

### Step 3: Create Comprehensive Module Structure

Build reusable modules for common infrastructure patterns.

```bash
# Create modules directory structure
mkdir -p ../modules/{vpc-network,iam-bindings,monitoring-setup,shared-services,compute-instance}

# Create VPC Network Module
mkdir -p ../modules/vpc-network
cat > ../modules/vpc-network/main.tf << 'VPC_MODULE_END'
# VPC Network Module for TechCorp Landing Zone

# Create VPC network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
  routing_mode           = var.routing_mode
  description            = var.description
  
  delete_default_routes_on_create = var.delete_default_routes
}

# Create subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  description   = each.value.description
  
  # Secondary IP ranges for GKE
  dynamic "secondary_ip_range" {
    for_each = try(each.value.secondary_ranges, [])
    content {
      range_name    = secondary_ip_range.value.name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }
  
  # Private Google Access
  private_ip_google_access = try(each.value.private_google_access, true)
  
  # Flow logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Create Cloud Router for NAT
resource "google_compute_router" "router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
  
  bgp {
    asn = 64512
  }
}

# Create Cloud NAT
resource "google_compute_router_nat" "nat" {
  count  = var.enable_nat ? 1 : 0
  name   = "${var.network_name}-nat"
  router = google_compute_router.router[0].name
  region = var.region
  project = var.project_id
  
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
VPC_MODULE_END

cat > ../modules/vpc-network/variables.tf << 'VPC_VARS_END'
# VPC Network Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "description" {
  description = "Description of the VPC network"
  type        = string
  default     = "VPC network created by Terraform"
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
}

variable "delete_default_routes" {
  description = "Delete default routes (0.0.0.0/0)"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr                   = string
    region                 = string
    description           = string
    private_google_access = optional(bool, true)
    secondary_ranges = optional(list(object({
      name = string
      cidr = string
    })), [])
  }))
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
}

variable "enable_nat" {
  description = "Enable Cloud NAT for outbound internet access"
  type        = bool
  default     = true
}
VPC_VARS_END

cat > ../modules/vpc-network/outputs.tf << 'VPC_OUTPUTS_END'
# VPC Network Module Outputs

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnets" {
  description = "Map of subnet details"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      id            = v.id
      self_link     = v.self_link
      cidr          = v.ip_cidr_range
      region        = v.region
      gateway_address = v.gateway_address
    }
  }
}

output "router_name" {
  description = "Name of the Cloud Router (if created)"
  value       = var.enable_nat ? google_compute_router.router[0].name : null
}

output "nat_name" {
  description = "Name of the Cloud NAT (if created)"
  value       = var.enable_nat ? google_compute_router_nat.nat[0].name : null
}
VPC_OUTPUTS_END

echo "✓ VPC network module created"
```

### Step 4: Create IAM Bindings Module

```bash
# Create IAM module
mkdir -p ../modules/iam-bindings
cat > ../modules/iam-bindings/main.tf << 'IAM_MODULE_END'
# IAM Bindings Module for TechCorp Landing Zone

# Project-level IAM bindings
resource "google_project_iam_binding" "project_bindings" {
  for_each = var.project_bindings
  
  project = var.project_id
  role    = each.key
  members = each.value
  
  dynamic "condition" {
    for_each = try(var.conditional_bindings[each.key], [])
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Service account creation
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts
  
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

# Service account IAM bindings
resource "google_project_iam_member" "service_account_bindings" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in var.service_accounts : [
        for role in sa_config.roles : {
          key = "${sa_key}-${role}"
          service_account = sa_key
          role = role
        }
      ]
    ]) : binding.key => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account].email}"
}

# Workload Identity bindings (for GKE)
resource "google_service_account_iam_binding" "workload_identity" {
  for_each = var.workload_identity_bindings
  
  service_account_id = google_service_account.service_accounts[each.key].name
  role              = "roles/iam.workloadIdentityUser"
  members           = each.value
}
IAM_MODULE_END

cat > ../modules/iam-bindings/variables.tf << 'IAM_VARS_END'
# IAM Bindings Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_bindings" {
  description = "Map of IAM role to list of members"
  type        = map(list(string))
  default     = {}
}

variable "conditional_bindings" {
  description = "Conditional IAM bindings"
  type = map(list(object({
    title       = string
    description = string
    expression  = string
  })))
  default = {}
}

variable "service_accounts" {
  description = "Service accounts to create"
  type = map(object({
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {}
}

variable "workload_identity_bindings" {
  description = "Workload Identity bindings for service accounts"
  type        = map(list(string))
  default     = {}
}
IAM_VARS_END

cat > ../modules/iam-bindings/outputs.tf << 'IAM_OUTPUTS_END'
# IAM Bindings Module Outputs

output "service_accounts" {
  description = "Created service accounts"
  value = {
    for k, v in google_service_account.service_accounts : k => {
      email = v.email
      name  = v.name
      id    = v.id
    }
  }
}

output "project_bindings" {
  description = "Project IAM bindings created"
  value = {
    for k, v in google_project_iam_binding.project_bindings : k => {
      role    = v.role
      members = v.members
    }
  }
}
IAM_OUTPUTS_END

echo "✓ IAM bindings module created"
```

### Step 5: Create Main Configuration Using Modules

```bash
# Create main configuration that uses the modules
cat > main.tf << 'MAIN_TF_END'
# Lab 02: Terraform Environment Setup
# Main configuration using modular architecture

# Get lab 01 outputs
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

# Local values
locals {
  common_tags = {
    workshop      = "gcp-landing-zone"
    lab           = "02"
    participant   = var.participant_id
    created_by    = "terraform"
    environment   = "workshop"
    cost_center   = "training"
  }
  
  # Network configuration
  network_config = {
    shared_vpc = {
      name        = "techcorp-shared-vpc"
      description = "Shared VPC for TechCorp landing zone"
      region      = var.region
    }
  }
  
  # Subnet configuration
  subnet_config = {
    "shared-mgmt" = {
      cidr                   = "10.0.0.0/24"
      region                 = var.region
      description           = "Shared management subnet"
      private_google_access = true
    }
    "dev-web" = {
      cidr                   = "10.1.0.0/22"
      region                 = var.region
      description           = "Development web tier subnet"
      private_google_access = true
      secondary_ranges = [
        {
          name = "dev-web-pods"
          cidr = "10.1.16.0/20"
        },
        {
          name = "dev-web-services"
          cidr = "10.1.32.0/20"
        }
      ]
    }
    "dev-app" = {
      cidr                   = "10.1.4.0/22"
      region                 = var.region
      description           = "Development app tier subnet"
      private_google_access = true
    }
    "staging-web" = {
      cidr                   = "10.2.0.0/22"
      region                 = var.region
      description           = "Staging web tier subnet"
      private_google_access = true
    }
    "staging-app" = {
      cidr                   = "10.2.4.0/22"
      region                 = var.region
      description           = "Staging app tier subnet"
      private_google_access = true
    }
  }
}

# Create shared VPC network using module
module "shared_vpc" {
  source = "../modules/vpc-network"
  
  project_id            = var.project_id
  network_name          = local.network_config.shared_vpc.name
  description          = local.network_config.shared_vpc.description
  region               = var.region
  routing_mode         = "REGIONAL"
  delete_default_routes = false
  enable_nat           = true
  
  subnets = local.subnet_config
  
  depends_on = [
    google_kms_crypto_key.terraform_state
  ]
}

# Create IAM structure using module
module "iam_structure" {
  source = "../modules/iam-bindings"
  
  project_id = var.project_id
  
  # Project-level bindings
  project_bindings = {
    "roles/viewer" = [
      "user:${data.google_client_openid_userinfo.current.email}"
    ]
    "roles/compute.networkAdmin" = [
      "serviceAccount:${google_service_account.terraform_automation.email}"
    ]
  }
  
  # Service accounts for workloads
  service_accounts = {
    "web-tier-sa" = {
      display_name = "Web Tier Service Account"
      description  = "Service account for web tier workloads"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
        "roles/storage.objectViewer"
      ]
    }
    "app-tier-sa" = {
      display_name = "Application Tier Service Account"
      description  = "Service account for application tier workloads"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
        "roles/storage.objectAdmin",
        "roles/cloudsql.client"
      ]
    }
    "monitoring-sa" = {
      display_name = "Monitoring Service Account"
      description  = "Service account for monitoring and observability"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/monitoring.dashboardEditor",
        "roles/logging.logWriter"
      ]
    }
  }
  
  depends_on = [
    google_service_account.terraform_automation
  ]
}

# Data source for current user
data "google_client_openid_userinfo" "current" {}
MAIN_TF_END

echo "✓ Main configuration using modules created"
```

### Step 6: Create Variables and Outputs

```bash
# Create comprehensive variables file
cat > variables.tf << 'VARS_TF_END'
# Variables for Lab 02: Terraform Environment Setup

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The default GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "participant_id" {
  description = "Unique participant identifier"
  type        = string
}

variable "tf_state_bucket" {
  description = "Terraform state bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "workshop"
}

# Network variables
variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "enable_private_google_access" {
  description = "Enable private Google access on subnets"
  type        = bool
  default     = true
}

# Security variables
variable "enable_os_login" {
  description = "Enable OS Login for instances"
  type        = bool
  default     = true
}

variable "allowed_ssh_sources" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
VARS_TF_END

# Create terraform.tfvars
cat > terraform.tfvars << 'TFVARS_END'
# Lab 02 Configuration Values
project_id = "${PROJECT_ID}"
region = "${REGION}"
zone = "${ZONE}"
participant_id = "${PROJECT_ID##*-}"
tf_state_bucket = "${TF_STATE_BUCKET}"

# Network configuration
enable_flow_logs = true
enable_private_google_access = true

# Security configuration
enable_os_login = true
allowed_ssh_sources = ["10.0.0.0/8"]
TFVARS_END

# Create comprehensive outputs
cat > outputs.tf << 'OUTPUTS_TF_END'
# Outputs for Lab 02: Terraform Environment Setup

# Terraform automation outputs
output "terraform_service_account" {
  description = "Terraform automation service account details"
  value = {
    email = google_service_account.terraform_automation.email
    name  = google_service_account.terraform_automation.name
    id    = google_service_account.terraform_automation.id
  }
}

output "kms_key_name" {
  description = "KMS key for Terraform state encryption"
  value       = google_kms_crypto_key.terraform_state.id
}

# Network outputs
output "shared_vpc" {
  description = "Shared VPC network details"
  value = {
    id            = module.shared_vpc.network_id
    self_link     = module.shared_vpc.network_self_link
    name          = module.shared_vpc.network_name
  }
}

output "subnets" {
  description = "Created subnets"
  value       = module.shared_vpc.subnets
}

output "nat_gateway" {
  description = "NAT gateway details"
  value = {
    router_name = module.shared_vpc.router_name
    nat_name    = module.shared_vpc.nat_name
  }
}

# IAM outputs
output "workload_service_accounts" {
  description = "Workload service accounts"
  value       = module.iam_structure.service_accounts
}

# Module information
output "modules_used" {
  description = "Terraform modules used in this configuration"
  value = [
    "vpc-network",
    "iam-bindings"
  ]
}

# Configuration for next labs
output "network_config" {
  description = "Network configuration for subsequent labs"
  value = {
    shared_vpc_id      = module.shared_vpc.network_id
    shared_vpc_name    = module.shared_vpc.network_name
    management_subnet  = module.shared_vpc.subnets["shared-mgmt"]
    dev_web_subnet     = module.shared_vpc.subnets["dev-web"]
    dev_app_subnet     = module.shared_vpc.subnets["dev-app"]
    staging_web_subnet = module.shared_vpc.subnets["staging-web"]
    staging_app_subnet = module.shared_vpc.subnets["staging-app"]
  }
}
OUTPUTS_TF_END

echo "✓ Variables and outputs configuration created"
```

### Step 7: Initialize, Plan, and Apply

```bash
# Initialize Terraform with modules
echo "Initializing Terraform with modules..."
terraform init

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✓ Terraform configuration is valid"
else
    echo "✗ Terraform configuration validation failed"
    exit 1
fi

# Create and review plan
echo "Creating Terraform execution plan..."
terraform plan -var-file=terraform.tfvars -out=lab02.tfplan

echo "Plan created. Review the resources to be created:"
echo "- KMS keyring and crypto key for state encryption"
echo "- Terraform automation service account with minimal permissions"
echo "- Shared VPC network with subnets for dev/staging environments"
echo "- Cloud Router and NAT gateway for internet access"
echo "- Workload service accounts for web, app, and monitoring tiers"
echo "- IAM bindings for service accounts"

read -p "Apply this configuration? (y/N): " confirm
if [[ $confirm == "y" || $confirm == "Y" ]]; then
    echo "Applying Terraform configuration..."
    terraform apply lab02.tfplan
    
    if [ $? -eq 0 ]; then
        echo "✓ Terraform apply completed successfully"
        echo "✓ Enhanced Terraform environment is ready"
    else
        echo "✗ Terraform apply failed"
        exit 1
    fi
else
    echo "Terraform apply cancelled"
    exit 1
fi
```

### Step 8: Configure Enhanced Backend

```bash
# Update backend configuration with KMS encryption
echo "Updating backend configuration with KMS encryption..."

# Get KMS key name from Terraform output
KMS_KEY_NAME=$(terraform output -raw kms_key_name)
SA_EMAIL=$(terraform output -json terraform_service_account | jq -r '.email')

echo "KMS Key: $KMS_KEY_NAME"
echo "Service Account: $SA_EMAIL"

# Create updated backend configuration
cat > backend-enhanced.tf << BACKEND_ENHANCED_END
# Enhanced backend configuration with encryption and service account
terraform {
  backend "gcs" {
    bucket                      = "${TF_STATE_BUCKET}"
    prefix                      = "environments/lab-02-enhanced"
    impersonate_service_account = "$SA_EMAIL"
    encryption_key              = "$KMS_KEY_NAME"
  }
}
BACKEND_ENHANCED_END

# Note: In production, you would migrate to the enhanced backend
echo "✓ Enhanced backend configuration created"
echo "Note: Backend migration would be done in production environments"
```

## Expected Deliverables

Upon successful completion of this lab, you should have:

• Enhanced Terraform configuration with remote state encryption using Cloud KMS
• Comprehensive module library including VPC network and IAM management modules
• Dedicated Terraform automation service account with minimal required permissions
• Shared VPC network with properly segmented subnets for multi-environment architecture
• Cloud Router and NAT gateway for secure internet access from private instances
• Workload service accounts for web, application, and monitoring tiers with appropriate role assignments
• Terraform state file encrypted with customer-managed KMS key
• Complete module documentation and reusable infrastructure components

## Validation and Testing

### Automated Validation
```bash
# Create comprehensive validation script
cat > validation/validate-lab-02.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab 02 Validation Script ==="
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

# Check KMS keyring and key creation
echo "Checking KMS infrastructure..."
if gcloud kms keyrings describe terraform-state-keyring --location=$REGION --project=$PROJECT_ID &>/dev/null; then
    echo "✓ KMS keyring created"
    ((validation_passed++))
    
    if gcloud kms keys describe terraform-state-key --keyring=terraform-state-keyring --location=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo "✓ KMS crypto key created"
        ((validation_passed++))
    else
        echo "✗ KMS crypto key missing"
        ((validation_failed++))
    fi
else
    echo "✗ KMS keyring missing"
    ((validation_failed++))
fi

# Check Terraform automation service account
echo "Checking Terraform automation service account..."
sa_email="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe $sa_email --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Terraform automation service account created"
    ((validation_passed++))
    
    # Check key roles
    roles=("roles/compute.admin" "roles/iam.serviceAccountAdmin" "roles/cloudkms.cryptoKeyEncrypterDecrypter")
    for role in "${roles[@]}"; do
        if gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.role:$role AND bindings.members:serviceAccount:$sa_email" --format="value(bindings.members)" | grep -q "$sa_email"; then
            echo "✓ Service account has role: $role"
            ((validation_passed++))
        else
            echo "✗ Service account missing role: $role"
            ((validation_failed++))
        fi
    done
else
    echo "✗ Terraform automation service account missing"
    ((validation_failed++))
fi

# Check VPC network and subnets
echo "Checking VPC network and subnets..."
if gcloud compute networks describe techcorp-shared-vpc --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Shared VPC network created"
    ((validation_passed++))
    
    # Check specific subnets
    subnets=("shared-mgmt" "dev-web" "dev-app" "staging-web" "staging-app")
    for subnet in "${subnets[@]}"; do
        if gcloud compute networks subnets describe $subnet --region=$REGION --project=$PROJECT_ID &>/dev/null; then
            echo "✓ Subnet created: $subnet"
            ((validation_passed++))
        else
            echo "✗ Subnet missing: $subnet"
            ((validation_failed++))
        fi
    done
else
    echo "✗ Shared VPC network missing"
    ((validation_failed++))
fi

# Check Cloud Router and NAT
echo "Checking Cloud Router and NAT gateway..."
if gcloud compute routers describe techcorp-shared-vpc-router --region=$REGION --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Cloud Router created"
    ((validation_passed++))
    
    if gcloud compute routers nats describe techcorp-shared-vpc-nat --router=techcorp-shared-vpc-router --region=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Cloud NAT created"
        ((validation_passed++))
    else
        echo "✗ Cloud NAT missing"
        ((validation_failed++))
    fi
else
    echo "✗ Cloud Router missing"
    ((validation_failed++))
fi

# Check workload service accounts
echo "Checking workload service accounts..."
workload_sas=("web-tier-sa" "app-tier-sa" "monitoring-sa")
for sa in "${workload_sas[@]}"; do
    sa_email="$sa@${PROJECT_ID}.iam.gserviceaccount.com"
    if gcloud iam service-accounts describe $sa_email --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Workload service account created: $sa"
        ((validation_passed++))
    else
        echo "✗ Workload service account missing: $sa"
        ((validation_failed++))
    fi
done

# Check Terraform modules
echo "Checking Terraform modules..."
if [ -d "../modules/vpc-network" ] && [ -f "../modules/vpc-network/main.tf" ]; then
    echo "✓ VPC network module exists"
    ((validation_passed++))
else
    echo "✗ VPC network module missing"
    ((validation_failed++))
fi

if [ -d "../modules/iam-bindings" ] && [ -f "../modules/iam-bindings/main.tf" ]; then
    echo "✓ IAM bindings module exists"
    ((validation_passed++))
else
    echo "✗ IAM bindings module missing"
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
    required_outputs=("shared_vpc" "subnets" "terraform_service_account" "kms_key_name")
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

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"
echo "Total checks: $((validation_passed + validation_failed))"

if [ $validation_failed -eq 0 ]; then
    echo
    echo "🎉 Lab 02 validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-02-validation.json << VALIDATION_JSON_END
{
  "lab": "02",
  "status": "PASSED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID"
}
VALIDATION_JSON_END
    
    exit 0
else
    echo
    echo "❌ Lab 02 validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-02-validation.json << VALIDATION_JSON_END
{
  "lab": "02",
  "status": "FAILED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID"
}
VALIDATION_JSON_END
    
    exit 1
fi
VALIDATION_SCRIPT_END

chmod +x validation/validate-lab-02.sh

# Run validation
echo "Running Lab 02 validation..."
cd validation
./validate-lab-02.sh
cd ..
```

### Manual Verification Steps
1. **Visual Inspection**: Check GCP Console for created resources
2. **Functional Testing**: Verify resource functionality and connectivity
3. **Security Review**: Confirm security controls are properly configured
4. **Documentation**: Ensure all configurations are documented

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Module Path Issues**
```bash
# Check module directory structure
ls -la ../modules/

# Verify module files
find ../modules -name "*.tf" -type f
```

**Issue 2: KMS Permission Issues**
```bash
# Check KMS API enablement
gcloud services list --enabled --filter="name:cloudkms.googleapis.com"

# Manual KMS setup
gcloud kms keyrings create terraform-state-keyring --location=$REGION
```

**Issue 3: Service Account Issues**
```bash
# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID

# Manual service account creation
gcloud iam service-accounts create terraform-automation --display-name="Terraform Automation"
```

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
- [ ] Documentation updated

### Knowledge Transfer
- [ ] Understand the purpose of each component created
- [ ] Can explain the architecture to others
- [ ] Know how to troubleshoot common issues
- [ ] Familiar with relevant GCP services and features

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

# Resource inventories
gcloud compute instances list --format=json > outputs/compute-instances.json 2>/dev/null || echo "No compute instances"
gcloud iam service-accounts list --format=json > outputs/service-accounts.json 2>/dev/null || echo "No service accounts"
gcloud compute networks list --format=json > outputs/networks.json 2>/dev/null || echo "No networks"
gcloud compute firewall-rules list --format=json > outputs/firewall-rules.json 2>/dev/null || echo "No firewall rules"

# Configuration backups
cp -r terraform/ outputs/ 2>/dev/null || echo "No terraform directory to backup"
cp -r scripts/ outputs/ 2>/dev/null || echo "No scripts directory to backup"

# Create lab summary
cat > outputs/lab-02-summary.md << 'LAB_SUMMARY_END'
# Lab 02 Summary

## Completed: $(date)
## Project: $PROJECT_ID
## Participant: $LAB_USER

### Resources Created
- [List of resources created in this lab]

### Key Learnings
- [Key technical concepts learned]

### Next Steps
- Proceed to Lab 03
- Review outputs for integration with subsequent labs

### Files Generated
$(ls -la outputs/)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
```

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

```bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab 02:"
    cat outputs/terraform-outputs.json | jq -r 'to_entries[] | "\(.key): \(.value.value)"'
fi
```

### Dependencies for Future Labs
- **Lab 03**: Will use [specific outputs] from this lab
- **Integration Points**: [How this lab integrates with overall architecture]

## Next Steps

### Immediate Next Steps
1. **Review Module Architecture**: Understand how modules improve code organization and reusability
2. **Test Advanced Features**: Verify KMS encryption and service account automation
3. **Prepare for Lab 03**: The enhanced Terraform setup will be used for core networking architecture

### Key Takeaways
- **Advanced State Management**: Encrypted remote state with dedicated service accounts
- **Module Architecture**: Reusable, maintainable infrastructure components
- **Security Best Practices**: Encryption, minimal permissions, and audit logging
- **Enterprise Readiness**: Production-grade Terraform configuration patterns

### Preparation for Next Lab
1. **Ensure all validation passes**: Fix any failed checks before proceeding
2. **Review outputs**: Understand what was created and why
3. **Take a break**: Complex labs require mental breaks between sessions
4. **Ask questions**: Clarify any concepts before moving forward

---

## Additional Resources

### Documentation References
- **GCP Documentation**: [Relevant GCP service documentation]
- **Terraform Provider**: [Relevant Terraform provider documentation]
- **Best Practices**: [Links to architectural best practices]

### Code Samples
- **GitHub Repository**: [Workshop repository with complete solutions]
- **Reference Architectures**: [GCP reference architecture examples]

---

**Lab 02 Complete** ✅

**Estimated Time for Completion**: 45 minutes
**Next Lab**: Lab 03 - [Next lab title]

*Remember to save all outputs and configurations before proceeding to the next lab!*


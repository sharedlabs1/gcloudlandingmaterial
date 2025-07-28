# Lab 02 Concepts: Terraform Environment Setup

## Learning Objectives
After completing this lab, you will understand:
- Advanced Terraform patterns and module architecture
- Remote state management and collaboration workflows
- VPC networking fundamentals and design patterns
- IAM automation and service account management
- Enterprise Terraform practices and security

---

## Core Concepts

### 1. Terraform Module Architecture

#### Module Design Principles
```
┌─────────────────────────────────────────┐
│           Module Architecture          │
├─────────────────────────────────────────┤
│  Root Module (main.tf)                 │
│  ├── vpc-network module                │
│  │   ├── VPC creation                  │
│  │   ├── Subnet management             │
│  │   └── NAT gateway setup             │
│  ├── iam-bindings module               │
│  │   ├── Service accounts              │
│  │   ├── Role bindings                 │
│  │   └── Policy management             │
│  └── monitoring-setup module           │
│      ├── Workspace creation            │
│      ├── Dashboard setup               │
│      └── Alert policies                │
└─────────────────────────────────────────┘
```

#### Module Benefits
- **Reusability**: Write once, use across environments
- **Maintainability**: Centralized updates and improvements
- **Consistency**: Standardized configurations and patterns
- **Testing**: Isolated validation and testing capabilities

#### Best Practices
```hcl
# Module Structure Example
module "vpc_network" {
  source = "./modules/vpc-network"
  
  # Required variables
  project_id   = var.project_id
  network_name = "techcorp-shared-vpc"
  region       = var.region
  
  # Configuration object
  subnets = {
    "web-tier" = {
      cidr        = "10.1.0.0/24"
      region      = var.region
      description = "Web tier subnet"
    }
    "app-tier" = {
      cidr        = "10.1.1.0/24" 
      region      = var.region
      description = "Application tier subnet"
    }
  }
  
  # Feature flags
  enable_nat     = true
  enable_logging = true
  
  # Labels for organization
  labels = local.common_labels
}
```

### 2. Remote State Management

#### State Backend Architecture
```
┌─────────────────────────────────────────┐
│         Remote State Strategy          │
├─────────────────────────────────────────┤
│  Google Cloud Storage Backend          │
│  ┌─────────────────┐                   │
│  │ State Bucket    │                   │
│  │ ├── lab-01/     │ → Foundation      │
│  │ ├── lab-02/     │ → Networking      │
│  │ ├── lab-03/     │ → Security        │
│  │ └── lab-XX/     │ → Other labs      │
│  │                 │                   │
│  │ Features:       │                   │
│  │ ├── Versioning  │ → Change history  │
│  │ ├── Encryption  │ → Data protection │
│  │ ├── Access Ctrl │ → IAM permissions │
│  │ └── Lifecycle   │ → Cost optimization│
│  └─────────────────┘                   │
└─────────────────────────────────────────┘
```

#### State Integration Pattern
```hcl
# Accessing previous lab state
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

# Using outputs from previous labs
resource "google_compute_instance" "app_server" {
  name         = "app-server"
  machine_type = "e2-medium"
  
  # Using service account from Lab 01
  service_account {
    email  = data.terraform_remote_state.lab01.outputs.service_accounts["app-tier-sa"].email
    scopes = ["cloud-platform"]
  }
  
  # Using network from current lab
  network_interface {
    network    = module.shared_vpc.network_id
    subnetwork = module.shared_vpc.subnets["app-tier"].self_link
  }
}
```

### 3. VPC Networking Fundamentals

#### Network Architecture Patterns
```
┌─────────────────────────────────────────────────────────────┐
│                TechCorp VPC Architecture                    │
├─────────────────────────────────────────────────────────────┤
│  Shared VPC (techcorp-shared-vpc)                          │
│  ├── Management Subnet (10.0.0.0/24)                       │
│  │   ├── Bastion hosts                                     │
│  │   ├── Monitoring systems                                │
│  │   └── Administrative tools                              │
│  ├── Web Tier Subnet (10.1.0.0/22)                        │
│  │   ├── Load balancers                                    │
│  │   ├── Web servers                                       │
│  │   └── CDN endpoints                                     │
│  ├── App Tier Subnet (10.1.4.0/22)                        │
│  │   ├── Application servers                               │
│  │   ├── API gateways                                      │
│  │   └── Microservices                                     │
│  └── Data Tier Subnet (10.1.8.0/22)                       │
│      ├── Database servers                                  │
│      ├── Data warehouses                                   │
│      └── Analytics systems                                 │
│                                                             │
│  Network Services                                          │
│  ├── Cloud Router → BGP routing                            │
│  ├── Cloud NAT → Outbound internet                         │
│  ├── Private Google Access → Google APIs                   │
│  └── VPC Flow Logs → Traffic monitoring                    │
└─────────────────────────────────────────────────────────────┘
```

#### Subnet Design Considerations
- **CIDR Planning**: Non-overlapping address spaces
- **Regional Placement**: Latency and availability considerations
- **Secondary Ranges**: For GKE pods and services
- **Private Google Access**: For accessing Google APIs
- **Flow Logs**: For traffic analysis and security

#### Routing and Connectivity
```hcl
# Cloud Router for dynamic routing
resource "google_compute_router" "vpc_router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  
  bgp {
    asn               = 64512
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "vpc_nat" {
  name   = "${var.network_name}-nat"
  router = google_compute_router.vpc_router.name
  region = var.region
  
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

### 4. IAM Automation Patterns

#### Service Account Management
```hcl
# Dynamic service account creation
resource "google_service_account" "workload_sas" {
  for_each = var.service_accounts
  
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

# Role binding automation
resource "google_project_iam_member" "sa_bindings" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in var.service_accounts : [
        for role in sa_config.roles : {
          key             = "${sa_key}-${role}"
          service_account = sa_key
          role           = role
        }
      ]
    ]) : binding.key => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload_sas[each.value.service_account].email}"
}
```

#### Workload Identity Integration
```
┌─────────────────────────────────────────┐
│        Workload Identity Pattern       │
├─────────────────────────────────────────┤
│  Kubernetes Pod                        │
│  ├── Kubernetes Service Account        │
│  │   └── workload-identity annotation  │
│  └── Pod Security Context              │
│                                         │
│  ↓ (Authentication Flow)               │
│                                         │
│  Google Service Account                │
│  ├── IAM Policy Binding               │
│  │   └── Kubernetes SA can assume     │
│  └── GCP Resource Permissions         │
│      ├── Cloud Storage access         │
│      ├── BigQuery permissions         │
│      └── Other GCP services           │
└─────────────────────────────────────────┘
```

### 5. Enterprise Security Patterns

#### Encryption and Key Management
```hcl
# Customer-managed encryption keys
resource "google_kms_key_ring" "terraform_keyring" {
  name     = "terraform-state-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "terraform_key" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  
  rotation_period = "7776000s"  # 90 days
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
}

# Backend configuration with encryption
terraform {
  backend "gcs" {
    bucket         = "terraform-state-bucket"
    prefix         = "lab-02/terraform/state"
    encryption_key = "projects/PROJECT_ID/locations/REGION/keyRings/RING/cryptoKeys/KEY"
  }
}
```

#### Network Security Foundations
```hcl
# Private Google Access for secure API communication
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  # Enable private Google access
  private_ip_google_access = true
  
  # Enable flow logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}
```

---

## Advanced Terraform Patterns

### 1. Dynamic Configuration
```hcl
# Dynamic block creation based on input
resource "google_compute_firewall" "tier_rules" {
  for_each = var.firewall_rules
  
  name    = each.key
  network = google_compute_network.vpc.name
  
  dynamic "allow" {
    for_each = each.value.allow_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  source_tags = each.value.source_tags
  target_tags = each.value.target_tags
  priority    = each.value.priority
}
```

### 2. Conditional Resource Creation
```hcl
# Environment-specific resource creation
resource "google_compute_global_address" "static_ip" {
  count = var.environment == "production" ? 1 : 0
  
  name         = "production-static-ip"
  address_type = "EXTERNAL"
}

# Feature flag pattern
resource "google_monitoring_workspace" "workspace" {
  count = var.enable_monitoring ? 1 : 0
  
  project = var.project_id
}
```

### 3. Data Validation and Type Constraints
```hcl
# Variable validation
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Complex type definitions
variable "subnets" {
  description = "Subnet configuration"
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
```

---

## Integration Patterns

### 1. Lab-to-Lab Integration
```
Lab 01 Outputs  →  Lab 02 Inputs  →  Lab 03 Dependencies
├── Service Accounts  →  Workload Identity  →  Instance Templates
├── Storage Buckets   →  Terraform State   →  Backup Configs
└── Project Structure →  Resource Naming   →  Monitoring Setup
```

### 2. Output Organization
```hcl
# Structured outputs for downstream consumption
output "network_config" {
  description = "Network configuration for subsequent labs"
  value = {
    vpc_id           = module.shared_vpc.network_id
    vpc_name         = module.shared_vpc.network_name
    vpc_self_link    = module.shared_vpc.network_self_link
    
    subnets = {
      for k, v in module.shared_vpc.subnets : k => {
        id        = v.id
        self_link = v.self_link
        cidr      = v.cidr
        region    = v.region
      }
    }
    
    nat_gateway = {
      router_name = module.shared_vpc.router_name
      nat_name    = module.shared_vpc.nat_name
    }
  }
}
```

---

## Troubleshooting Guide

### Common Terraform Issues

#### State Lock Conflicts
**Problem**: Terraform state is locked by another operation
```bash
# Solution: Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Prevention: Implement proper CI/CD workflows
# Use terraform plan/apply in controlled environments
```

#### Module Path Issues
**Problem**: Module not found or incorrect path
```bash
# Solution: Verify module source paths
terraform init -upgrade

# For local modules, use relative paths
source = "../modules/vpc-network"

# For remote modules, use proper versioning
source = "git::https://github.com/org/terraform-modules.git//vpc?ref=v1.0.0"
```

#### Resource Dependencies
**Problem**: Resources created in wrong order
```hcl
# Solution: Use explicit dependencies
resource "google_compute_instance" "app_server" {
  # ... configuration ...
  
  depends_on = [
    google_compute_subnetwork.app_subnet,
    google_service_account.app_sa
  ]
}
```

### Network Configuration Issues

#### CIDR Conflicts
**Problem**: Subnet CIDR ranges overlap
```bash
# Solution: Plan CIDR allocation carefully
# Management:    10.0.0.0/24  (256 IPs)
# Web Tier:      10.1.0.0/22  (1024 IPs)
# App Tier:      10.1.4.0/22  (1024 IPs)
# Data Tier:     10.1.8.0/22  (1024 IPs)
```

#### Private Google Access
**Problem**: Can't access Google APIs from private instances
```hcl
# Solution: Enable private Google access
resource "google_compute_subnetwork" "private_subnet" {
  private_ip_google_access = true
  # ... other configuration ...
}
```

---

## Best Practices Summary

### Module Development
1. **Single Responsibility**: Each module should have a clear, focused purpose
2. **Minimal Interface**: Expose only necessary variables and outputs
3. **Documentation**: Include README and examples for each module
4. **Versioning**: Use semantic versioning for module releases

### State Management
1. **Remote Backend**: Always use remote state for team collaboration
2. **State Encryption**: Encrypt state files with customer-managed keys
3. **Backup Strategy**: Implement regular state file backups
4. **Access Control**: Restrict state file access to authorized users

### Security
1. **Least Privilege**: Grant minimal required permissions
2. **Network Isolation**: Use private subnets and controlled egress
3. **Encryption**: Encrypt data at rest and in transit
4. **Audit Logging**: Enable comprehensive audit trails

---

## Assessment Questions

1. **How do Terraform modules improve infrastructure management?**
2. **What are the benefits of remote state management?**
3. **How does VPC design support security and compliance requirements?**
4. **What are the key considerations for IAM automation?**
5. **How do you handle sensitive data in Terraform configurations?**

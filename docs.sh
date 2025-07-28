#!/bin/bash

# GCP Landing Zone Workshop - Documentation & Presentation Generator
# This script creates comprehensive documentation and presentation materials

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

log "Creating GCP Landing Zone Workshop Documentation & Presentations..."

# Configuration
WORKSHOP_TITLE="GCP Landing Zone Workshop"
COMPANY_NAME="TechCorp"
AUTHOR="Cloud Architecture Team"
WORKSHOP_DURATION="2 Days"
MAX_PARTICIPANTS="20"

# Check dependencies
command -v pandoc >/dev/null 2>&1 || warn "Pandoc not found. Install for presentation conversion."

# Check if workshop-materials directory exists, create if needed
if [ ! -d "workshop-materials" ]; then
    warn "workshop-materials directory not found. Creating directory structure..."
    mkdir -p workshop-materials
fi

# Create documentation directory structure
log "Creating documentation directory structure..."
mkdir -p workshop-materials/docs/{presentations,guides,diagrams,reference}
log "✓ Directory structure created"

# Function to create slide content for presentations
create_presentation_slide() {
    local slide_title="$1"
    local slide_content="$2"
    
    cat << SLIDE_END

---

## ${slide_title}

${slide_content}

SLIDE_END
}

# Function to validate generated content
validate_documentation() {
    log "Validating generated documentation..."
    local errors=0
    
    # Check required files
    local required_files=(
        "workshop-materials/docs/presentations/workshop-overview.md"
        "workshop-materials/docs/guides/lab-01-concepts.md"
        "workshop-materials/docs/diagrams/architecture-overview.md"
        "workshop-materials/docs/reference/complete-workshop-guide.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Missing required file: $file"
            ((errors++))
        else
            log "✓ Found: $file"
        fi
    done
    
    # Check file sizes (basic validation)
    if [[ -f "workshop-materials/docs/presentations/workshop-overview.md" ]]; then
        local size=$(wc -l < "workshop-materials/docs/presentations/workshop-overview.md")
        if [[ $size -lt 100 ]]; then
            warn "Presentation file seems incomplete (only $size lines)"
            ((errors++))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        log "✅ Documentation validation passed!"
        return 0
    else
        error "❌ Documentation validation failed with $errors errors"
        return 1
    fi
}

# Create main workshop presentation
log "Creating main workshop presentation..."
cat > workshop-materials/docs/presentations/workshop-overview.md << OVERVIEW_PRESENTATION_END
---
title: ${WORKSHOP_TITLE}
subtitle: Enterprise Cloud Foundation for ${COMPANY_NAME}
author: ${AUTHOR}
date: $(date +"%Y-%m-%d")
theme: corporate
transition: slide
---

# ${WORKSHOP_TITLE}
## Enterprise Cloud Foundation for ${COMPANY_NAME}

### ${WORKSHOP_DURATION} Hands-On Workshop
Building Production-Ready Cloud Infrastructure

---

## Workshop Overview

### Objective
Build a complete, enterprise-grade Google Cloud Platform landing zone for **TechCorp**, a fintech company requiring:

- **Regulatory Compliance** (PCI DSS, SOX)
- **Enterprise Security** (Encryption, Access Controls)
- **High Availability** (Multi-zone, Auto-scaling)
- **Operational Excellence** (Monitoring, Logging, Automation)

### Target Audience
- Cloud Architects and Engineers
- DevOps and Platform Teams  
- Security and Compliance Professionals
- Infrastructure Automation Specialists

---

## What You'll Build

### TechCorp Landing Zone Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TechCorp Landing Zone                    │
├─────────────────────────────────────────────────────────────┤
│  Shared Services          │  Development    │  Production   │
│  ┌─────────────────┐     │  ┌─────────────┐ │ ┌───────────┐ │
│  │ DNS             │     │  │ Web Tier    │ │ │ Web Tier  │ │
│  │ Certificates    │     │  │ App Tier    │ │ │ App Tier  │ │
│  │ Security Scan   │     │  │ Data Tier   │ │ │ Data Tier │ │
│  │ Monitoring      │     │  │ GKE Cluster │ │ │ GKE       │ │
│  │ Logging         │     │  └─────────────┘ │ └───────────┘ │
│  └─────────────────┘     │                 │               │
└─────────────────────────────────────────────────────────────┘
```

---

## Workshop Structure

### Day 1: Foundation (Labs 01-07)
| Lab | Topic | Duration | Focus |
|-----|-------|----------|-------|
| 01 | GCP Organizational Foundation | 45 min | Projects, IAM, Organization |
| 02 | Terraform Environment Setup | 45 min | IaC, Modules, State Management |
| 03 | Core Networking Architecture | 60 min | VPC, Subnets, Firewall Rules |
| 04 | Network Security Implementation | 60 min | Cloud Armor, DDoS Protection |
| 05 | Identity and Access Management | 60 min | Custom Roles, Service Accounts |
| 06 | Cloud Monitoring Foundation | 45 min | Metrics, Dashboards, Alerting |
| 07 | Cloud Logging Architecture | 45 min | Centralized Logs, Compliance |

### Day 2: Advanced Implementation (Labs 08-14)
| Lab | Topic | Duration | Focus |
|-----|-------|----------|-------|
| 08 | Shared Services Implementation | 60 min | DNS, Certificates, Security |
| 09 | Workload Environment Setup | 60 min | Multi-tier Apps, Auto-scaling |
| 10 | Security Controls & Compliance | 60 min | Encryption, DLP, Binary Auth |
| 11 | Advanced Monitoring & Alerting | 60 min | SRE Practices, Incident Response |
| 12 | Disaster Recovery & Backup | 45 min | Business Continuity, DR |
| 13 | Cost Management & Optimization | 45 min | Cost Controls, Optimization |
| 14 | Final Validation & Optimization | 60 min | End-to-End Testing |

---

## Learning Outcomes

### By Workshop Completion, You Will:

#### **Technical Skills**
- Design enterprise GCP architectures
- Implement Infrastructure as Code with Terraform
- Configure advanced networking and security
- Set up comprehensive monitoring and logging
- Implement compliance and governance controls

#### **Enterprise Capabilities**
- Build production-ready cloud foundations
- Implement fintech-grade security controls
- Design for high availability and disaster recovery
- Optimize costs and operational efficiency
- Establish DevOps and automation practices

#### **Real-World Application**
- Apply learnings to your organization
- Lead cloud transformation initiatives
- Implement security and compliance frameworks
- Establish operational excellence practices

---

## Prerequisites

### Required Knowledge
- Basic GCP services familiarity
- Terraform fundamentals
- Networking concepts (VPC, DNS, Load Balancing)
- Basic Linux command line

### Required Tools
- GCP Account with billing enabled
- Local development environment
- Terraform >= 1.5
- gcloud CLI
- Git and code editor

### Workshop Environment
- Individual GCP project per participant
- Pre-configured APIs and permissions
- Terraform state bucket
- Workshop materials and solutions

---

## Success Criteria

### Technical Deliverables
✅ **Complete Landing Zone** deployed and validated  
✅ **Security Controls** implemented and tested  
✅ **Monitoring & Logging** operational  
✅ **Compliance** requirements met  
✅ **Documentation** created and reviewed

### Knowledge Validation
✅ **Architecture Review** with instructor  
✅ **Security Assessment** completed  
✅ **Operational Procedures** demonstrated  
✅ **Cost Optimization** strategies applied  
✅ **Production Readiness** checklist completed

---

## Workshop Flow

### Hands-On Learning Approach
1. **Concept Introduction** (15 minutes per lab)
2. **Guided Implementation** (30-45 minutes per lab)
3. **Validation & Testing** (10-15 minutes per lab)
4. **Integration Review** (5 minutes per lab)

### Support Structure
- **Lead Instructor**: Architecture guidance and troubleshooting
- **Technical Assistants**: Hands-on support during labs
- **Workshop Materials**: Complete guides and solutions
- **Slack Channel**: Real-time Q&A and collaboration

### Continuous Validation
- Each lab includes validation scripts
- Integration testing between labs
- Progressive complexity building
- Real-time feedback and adjustment

---

## Let's Begin!

### Ready to Transform Your Cloud Infrastructure?

**Next**: Lab 00 - Environment Setup
- Verify your development environment
- Configure GCP authentication
- Initialize workshop workspace
- Run environment validation

**Questions?**
- Technical setup issues
- Workshop logistics
- Learning objectives
- Schedule and breaks

---
OVERVIEW_PRESENTATION_END

# Create concept guides for each lab
echo "Creating detailed concept guides..."

# Lab 01 Concepts
cat > workshop-materials/docs/guides/lab-01-concepts.md << 'LAB01_CONCEPTS_END'
# Lab 01 Concepts: GCP Organizational Foundation

## Learning Objectives
After completing this lab, you will understand:
- GCP resource hierarchy and organizational structure
- Project management and resource organization
- Service account patterns and IAM fundamentals
- Infrastructure as Code principles with Terraform
- Enterprise governance and compliance foundations

---

## Core Concepts

### 1. GCP Resource Hierarchy

#### Organizational Structure
```
Organization (Root)
├── Folders (Business Units/Environments)
│   ├── Projects (Applications/Workloads)
│   │   └── Resources (Compute, Storage, Network)
│   └── Projects
└── Folders
    └── Projects
        └── Resources
```

#### Key Benefits
- **Centralized Policy Management**: Policies inherit down the hierarchy
- **Billing Organization**: Cost allocation and budgeting by structure
- **Access Control**: IAM roles and permissions inheritance
- **Resource Grouping**: Logical organization of related resources

#### Best Practices
- **Folder Strategy**: Organize by environment, business unit, or team
- **Project Naming**: Consistent naming conventions for easy identification
- **Resource Labels**: Consistent tagging for cost allocation and management
- **Policy Inheritance**: Leverage hierarchy for consistent governance

### 2. Project Management Patterns

#### Multi-Project Strategy
```
TechCorp Organization
├── Shared Services Folder
│   └── shared-services-project
│       ├── DNS zones
│       ├── Certificate management
│       └── Monitoring infrastructure
├── Development Folder  
│   └── development-project
│       ├── Development workloads
│       ├── Testing infrastructure
│       └── Sandbox resources
├── Staging Folder
│   └── staging-project
│       ├── Pre-production testing
│       ├── Performance validation
│       └── Integration testing
└── Production Folder
    └── production-project
        ├── Production workloads
        ├── Critical data systems
        └── Customer-facing services
```

#### Project Benefits
- **Environment Isolation**: Clear boundaries between dev/staging/prod
- **Security Boundaries**: Different access controls per environment
- **Billing Separation**: Cost tracking and allocation per environment
- **Resource Quotas**: Independent limits and controls

### 3. Service Account Architecture

#### Service Account Types
- **User-Managed Service Accounts**: Created by users for applications
- **Google-Managed Service Accounts**: Created automatically by Google services
- **Default Service Accounts**: Provided by default (should be replaced)

#### Security Patterns
```
┌─────────────────────────────────────────┐
│           Service Account Design        │
├─────────────────────────────────────────┤
│  Environment-Specific Service Accounts │
│  ┌─────────────────┐                   │
│  │ web-tier-sa     │ → Web applications │
│  │ app-tier-sa     │ → App services     │
│  │ data-tier-sa    │ → Database access  │
│  │ monitoring-sa   │ → Observability    │
│  └─────────────────┘                   │
│                                         │
│  Principle of Least Privilege          │
│  ┌─────────────────┐                   │
│  │ Minimal Roles   │ → Only required   │
│  │ Scoped Access   │ → Specific resources│
│  │ Regular Audit   │ → Access review    │
│  └─────────────────┘                   │
└─────────────────────────────────────────┘
```

#### Best Practices
- **One Service Account Per Service**: Avoid sharing across services
- **Minimal Permissions**: Grant only required roles and permissions
- **Regular Rotation**: Implement key rotation policies
- **Workload Identity**: Use for GKE workloads instead of keys

### 4. Infrastructure as Code (IaC)

#### Terraform Fundamentals
```hcl
# Resource Definition Pattern
resource "google_service_account" "app_sa" {
  account_id   = "app-service-account"
  display_name = "Application Service Account"
  description  = "Service account for application workloads"
  
  # Labels for organization
  labels = {
    environment = "production"
    team        = "platform"
    purpose     = "application"
  }
}

# Data Sources for Integration
data "google_project" "current" {
  project_id = var.project_id
}

# Outputs for Other Modules
output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.app_sa.email
}
```

#### IaC Benefits
- **Version Control**: Infrastructure changes tracked in Git
- **Reproducibility**: Consistent environments across deployments
- **Collaboration**: Team-based infrastructure development
- **Automation**: CI/CD integration for infrastructure deployments

### 5. Enterprise Governance

#### Compliance Requirements
For fintech organizations like TechCorp:

**SOX (Sarbanes-Oxley) Compliance**
- Audit trails for all infrastructure changes
- Access controls and segregation of duties
- Financial data protection and retention
- Change management processes

**PCI DSS (Payment Card Industry)**
- Network segmentation and firewall rules
- Encryption of sensitive data
- Access controls and monitoring
- Regular security assessments

**General Security Framework**
- Multi-factor authentication requirements
- Principle of least privilege access
- Regular access reviews and audits
- Incident response procedures

#### Implementation Patterns
```
┌─────────────────────────────────────────┐
│         Governance Framework           │
├─────────────────────────────────────────┤
│  Policy Layer                          │
│  ┌─────────────────┐                   │
│  │ Org Policies    │ → Resource restrictions│
│  │ IAM Policies    │ → Access controls  │
│  │ Security Policies│ → Compliance rules │
│  └─────────────────┘                   │
│                                         │
│  Monitoring Layer                       │
│  ┌─────────────────┐                   │
│  │ Audit Logs      │ → All activities  │
│  │ Cloud Monitoring│ → Resource health  │
│  │ Security Center │ → Threat detection │
│  └─────────────────┘                   │
│                                         │
│  Automation Layer                       │
│  ┌─────────────────┐                   │
│  │ Terraform       │ → Infrastructure  │
│  │ CI/CD Pipelines │ → Deployments     │
│  │ Policy Enforcement│ → Compliance   │
│  └─────────────────┘                   │
└─────────────────────────────────────────┘
```

---

## Practical Applications

### 1. Project Structure Design
When designing your project structure, consider:

**Business Alignment**
- Map projects to business units or applications
- Consider compliance and regulatory boundaries
- Plan for scaling and future growth

**Operational Efficiency**
- Balance between isolation and management overhead
- Consider shared services and common infrastructure
- Plan for automation and self-service capabilities

### 2. Service Account Strategy
Design service accounts with security in mind:

**Access Patterns**
```
Application → Service Account → GCP Resources
     ↓              ↓               ↓
Workload        Identity        Permissions
Identity        Provider        (IAM Roles)
```

**Security Controls**
- Use Workload Identity for GKE workloads
- Implement service account key rotation
- Monitor and audit service account usage
- Apply conditional access policies

### 3. Terraform Best Practices

**Module Design**
- Create reusable modules for common patterns
- Use consistent variable and output naming
- Include comprehensive documentation
- Implement proper error handling

**State Management**
- Use remote state backends (GCS)
- Implement state locking
- Plan for state backup and recovery
- Consider state file encryption

---

## Integration with Subsequent Labs

### Outputs from Lab 01
This lab creates foundational resources used throughout the workshop:

**Service Accounts** → Used in Labs 02, 03, 09 for workload identity
**Storage Buckets** → Used in Labs 07, 08, 12 for data storage
**Project Structure** → Foundation for all subsequent labs
**Terraform Patterns** → Reused and extended in all labs

### Preparation for Lab 02
Lab 01 establishes the foundation that Lab 02 builds upon:
- Project and service account structure
- Terraform state management
- Resource organization patterns
- Security and compliance baselines

---

## Troubleshooting Common Issues

### Project Creation Issues
**Problem**: Unable to create additional projects
**Solution**: Check billing account association and project quotas

**Problem**: Permission denied errors
**Solution**: Verify IAM roles and organization-level permissions

### Service Account Issues
**Problem**: Service account creation fails
**Solution**: Check IAM API enablement and required permissions

**Problem**: Service account key authentication issues
**Solution**: Verify key format and gcloud authentication setup

### Terraform Issues
**Problem**: State file conflicts
**Solution**: Implement proper state locking and backend configuration

**Problem**: Resource already exists errors
**Solution**: Import existing resources or use different naming

---

## Assessment Questions

Test your understanding:

1. **What are the benefits of using a multi-project strategy in GCP?**
2. **How does the GCP resource hierarchy support enterprise governance?**
3. **What are the security considerations for service account design?**
4. **How does Infrastructure as Code improve operational efficiency?**
5. **What compliance requirements are addressed by proper project organization?**

---

## Additional Resources

### Documentation
- [GCP Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- [IAM Best Practices](https://cloud.google.com/iam/docs/using-iam-securely)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Security Frameworks
- [GCP Security Command Center](https://cloud.google.com/security-command-center)
- [CIS GCP Foundations Benchmark](https://www.cisecurity.org/benchmark/google_cloud_platform)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
LAB01_CONCEPTS_END

# Create similar concept guides for other key labs
cat > workshop-materials/docs/guides/lab-02-concepts.md << 'LAB02_CONCEPTS_END'
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
LAB02_CONCEPTS_END

# Create architecture diagrams document
cat > workshop-materials/docs/diagrams/architecture-overview.md << 'ARCHITECTURE_END'
# TechCorp Landing Zone Architecture

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            TechCorp GCP Landing Zone                            │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │ Shared Services │  │   Development   │  │   Production    │                │
│  │    Project      │  │     Project     │  │     Project     │                │
│  │                 │  │                 │  │                 │                │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                │
│  │ │ DNS Zones   │ │  │ │ Web Tier    │ │  │ │ Web Tier    │ │                │
│  │ │ Certificates│ │  │ │ App Tier    │ │  │ │ App Tier    │ │                │
│  │ │ Monitoring  │ │  │ │ Data Tier   │ │  │ │ Data Tier   │ │                │
│  │ │ Logging     │ │  │ │ GKE Cluster │ │  │ │ GKE Cluster │ │                │
│  │ │ Security    │ │  │ └─────────────┘ │  │ └─────────────┘ │                │
│  │ └─────────────┘ │  └─────────────────┘  └─────────────────┘                │
│  └─────────────────┘                                                           │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      Shared VPC Network                                │   │
│  │                                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │ Management  │  │  Web Tier   │  │  App Tier   │  │ Data Tier   │   │   │
│  │  │   Subnet    │  │   Subnet    │  │   Subnet    │  │   Subnet    │   │   │
│  │  │ 10.0.0.0/24 │  │10.1.0.0/22  │  │10.1.4.0/22  │  │10.1.8.0/22  │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    Network Services                             │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │   │
│  │  │  │Cloud Router │  │  Cloud NAT  │  │ Private GA  │            │   │   │
│  │  │  │BGP Routing  │  │ Outbound    │  │ Google APIs │            │   │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      Security & Compliance                             │   │
│  │                                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │ Cloud KMS   │  │Cloud Armor  │  │    DLP      │  │Binary Auth  │   │   │
│  │  │ Encryption  │  │ WAF/DDoS    │  │ Data Scan   │  │Container    │   │   │
│  │  │ Key Mgmt    │  │ Protection  │  │ Protection  │  │ Security    │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    Monitoring & Observability                          │   │
│  │                                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │Cloud Monitor│  │Cloud Logging│  │  BigQuery   │  │   Alerting  │   │   │
│  │  │ Metrics &   │  │Centralized  │  │Log Analysis │  │ Incident    │   │   │
│  │  │ Dashboards  │  │Log Storage  │  │& Reporting  │  │ Response    │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Network Traffic Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          Traffic Flow Patterns                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Internet Traffic                                                               │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │
│  │Internet │ ──→│Global Load  │ ──→│  Web Tier   │ ──→│  App Tier   │           │
│  │ Users   │    │  Balancer   │    │  Instances  │    │  Services   │           │
│  └─────────┘    │(Cloud Armor)│    │(Auto-scale) │    │(Auto-scale) │           │
│                 └─────────────┘    └─────────────┘    └─────────────┘           │
│                                           │                    │                │
│                                           ▼                    ▼                │
│                                    ┌─────────────┐    ┌─────────────┐           │
│                                    │   HTTPS     │    │Internal Load│           │
│                                    │Certificates │    │  Balancer   │           │
│                                    │             │    │             │           │
│                                    └─────────────┘    └─────────────┘           │
│                                                              │                  │
│                                                              ▼                  │
│                                                       ┌─────────────┐           │
│                                                       │ Data Tier   │           │
│                                                       │ Databases   │           │
│                                                       │ (Encrypted) │           │
│                                                       └─────────────┘           │
│                                                                                 │
│  Internal Management                                                            │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────┐                             │
│  │ Admins  │ ──→│ Bastion/    │ ──→│ Management  │                             │
│  │ (VPN)   │    │ Jump Host   │    │ Subnet      │                             │
│  └─────────┘    │ (MFA)       │    │ (Private)   │                             │
│                 └─────────────┘    └─────────────┘                             │
│                                                                                 │
│  Outbound Traffic (Private Instances)                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────┐                             │
│  │Private      │ ──→│ Cloud NAT   │ ──→│Internet │                             │
│  │Instances    │    │ Gateway     │    │Services │                             │
│  └─────────────┘    └─────────────┘    └─────────┘                             │
│                                                                                 │
│  Google APIs Access                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────┐                             │
│  │Private      │ ──→│Private      │ ──→│ Google  │                             │
│  │Instances    │    │Google Access│    │   APIs  │                             │
│  └─────────────┘    └─────────────┘    └─────────┘                             │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Security Layers                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Layer 1: Network Security                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │Cloud Armor  │  │ Firewall    │  │   Private   │  │ VPC Flow    │     │   │
│  │ │ WAF Rules   │  │ Rules       │  │   Subnets   │  │   Logs      │     │   │
│  │ │ DDoS Protect│  │ Micro-seg   │  │ No Ext IPs  │  │ Traffic Mon │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Layer 2: Identity & Access                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │   IAM       │  │  Service    │  │ Workload    │  │Conditional  │     │   │
│  │ │ Custom      │  │ Accounts    │  │ Identity    │  │ Access      │     │   │
│  │ │ Roles       │  │Least Privil │  │ GKE → GSA   │  │ Policies    │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Layer 3: Data Protection                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │   KMS       │  │    DLP      │  │Transparent  │  │ Backup      │     │   │
│  │ │ CMEK Keys   │  │ Sensitive   │  │ Encryption  │  │ Encryption  │     │   │
│  │ │ Auto-Rotate │  │ Data Scan   │  │ At Rest     │  │ Retention   │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Layer 4: Application Security                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │Binary Auth  │  │Container    │  │  Security   │  │Vulnerability│     │   │
│  │ │Image        │  │ Scanning    │  │  Policies   │  │ Management  │     │   │
│  │ │Verification │  │CVE Detection│  │ Pod Security│  │Patch Mgmt   │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Layer 5: Monitoring & Compliance                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │ Audit Logs  │  │Security     │  │ Compliance  │  │ Incident    │     │   │
│  │ │ All Actions │  │ Command     │  │ Monitoring  │  │ Response    │     │   │
│  │ │ Immutable   │  │ Center      │  │ Automation  │  │ Automation  │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Compliance Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Compliance Framework                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  SOX (Sarbanes-Oxley) Compliance                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │ Audit Trail │  │ Change Mgmt │  │ Access      │  │ Financial   │     │   │
│  │ │ Complete    │  │ Controlled  │  │ Controls    │  │ Data        │     │   │
│  │ │ Immutable   │  │ Approved    │  │ Segregation │  │ Protection  │     │   │
│  │ │ 7-year Ret  │  │ Documented  │  │ of Duties   │  │ Encryption  │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  PCI DSS (Payment Card Industry) Compliance                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │ Network     │  │ Card Data   │  │ Access      │  │ Monitoring  │     │   │
│  │ │ Segmentation│  │ Encryption  │  │ Controls    │  │ & Testing   │     │   │
│  │ │ Firewalls   │  │ Tokenization│  │ MFA         │  │ Regular     │     │   │
│  │ │ DMZ Design  │  │ Key Mgmt    │  │ Unique IDs  │  │ Audits      │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  GDPR (General Data Protection Regulation)                                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │ Data        │  │ Consent     │  │ Right to    │  │ Breach      │     │   │
│  │ │ Minimization│  │ Management  │  │ Erasure     │  │ Notification│     │   │
│  │ │ Purpose Lim │  │ Lawful Basis│  │ Data Port   │  │ 72hr Rule   │     │   │
│  │ │ Retention   │  │ Transparency│  │ Access Req  │  │ DPO Contact │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Automation & Continuous Compliance                                            │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │ │ Policy as   │  │ Automated   │  │ Continuous  │  │ Compliance  │     │   │
│  │ │ Code        │  │ Compliance  │  │ Monitoring  │  │ Reporting   │     │   │
│  │ │ Terraform   │  │ Validation  │  │ Violations  │  │ Dashboards  │     │   │
│  │ │ OPA/Gatekeeper│ │ Remediation │  │ Alerting    │  │ Audit Trail │     │   │
│  │ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Data Flow Patterns                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Application Data Flow                                                          │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │  Users  │ ──→│   CDN   │ ──→│   LB    │ ──→│   App   │ ──→│Database │      │
│  │External │    │(Static) │    │(L7/L4)  │    │Services │    │ Layer   │      │
│  │Traffic  │    │Content  │    │Traffic  │    │Business │    │(ACID)   │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│       │              │              │              │              │           │
│       ▼              ▼              ▼              ▼              ▼           │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │ WAF     │    │ Edge    │    │ Health  │    │ Circuit │    │ Connection│     │
│  │ Rules   │    │ Cache   │    │ Checks  │    │ Breaker │    │ Pooling │     │
│  │ DDoS    │    │ Geo     │    │ SSL     │    │ Retry   │    │ Read     │     │
│  │ Filter  │    │ Distrib │    │ Term    │    │ Logic   │    │ Replicas │     │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│                                                                                 │
│  Monitoring Data Flow                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                                                                         │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │ Metrics │ ──→│ Cloud   │ ──→│ Alert   │ ──→│Incident │              │   │
│  │  │ Collect │    │Monitor  │    │Manager  │    │Response │              │   │
│  │  │(Agents) │    │(TSDB)   │    │(Rules)  │    │(Auto)   │              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  │       ▲              ▲              ▲              ▲                   │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │  Logs   │ ──→│ Cloud   │ ──→│ BigQuery│ ──→│Analytics│              │   │
│  │  │ Collect │    │Logging  │    │ Export  │    │Insights │              │   │
│  │  │(Agents) │    │(Stream) │    │(Batch)  │    │(ML)     │              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  │       ▲              ▲              ▲              ▲                   │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │ Traces  │ ──→│ Cloud   │ ──→│ Analysis│ ──→│Performance│            │   │
│  │  │ Collect │    │ Trace   │    │ Engine  │    │Optimization│           │   │
│  │  │(OpenTel)│    │(Distrib)│    │(Latency)│    │(Tuning) │              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Security Data Flow                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                                                                         │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │ Events  │ ──→│Security │ ──→│ SIEM    │ ──→│Response │              │   │
│  │  │ Auth    │    │Command  │    │Analysis │    │Playbook │              │   │
│  │  │ Access  │    │ Center  │    │Correlate│    │Automate │              │   │
│  │  │ Change  │    │(Collect)│    │(Detect) │    │(Contain)│              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  │       ▲              ▲              ▲              ▲                   │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │ Vulner  │ ──→│Container│ ──→│ Risk    │ ──→│Remediate│              │   │
│  │  │ Scan    │    │Analysis │    │ Assess  │    │Priority │              │   │
│  │  │(Images) │    │(CVE DB) │    │(Scoring)│    │(Patch)  │              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  │       ▲              ▲              ▲              ▲                   │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │Sensitive│ ──→│   DLP   │ ──→│ Data    │ ──→│ Policy  │              │   │
│  │  │Data Scan│    │ Engine  │    │ Classify│    │ Enforce │              │   │
│  │  │(Content)│    │(Pattern)│    │(PII/PHI)│    │(Encrypt)│              │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```
ARCHITECTURE_END

# Create presentation generator script
cat > workshop-materials/docs/generate-presentations.sh << 'GENERATE_PRESENTATIONS_END'
#!/bin/bash

# Presentation Generator Script
echo "Generating workshop presentations..."

# Check if pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "Warning: pandoc not found. Install pandoc to generate PDF/HTML presentations."
    echo "Ubuntu/Debian: sudo apt install pandoc"
    echo "macOS: brew install pandoc"
    echo "Windows: Download from https://pandoc.org/installing.html"
fi

# Create presentations directory if it doesn't exist
mkdir -p presentations/output

# Convert markdown presentations to various formats
echo "Converting presentations..."

# Generate HTML slides (reveal.js)
if command -v pandoc &> /dev/null; then
    echo "Generating HTML presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.html \
        -t revealjs \
        -s \
        --slide-level=2 \
        --theme=beige \
        --transition=slide \
        --highlight-style=github \
        --variable revealjs-url=https://unpkg.com/reveal.js@4.3.1/

    # Generate PDF presentation
    echo "Generating PDF presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.pdf \
        -t beamer \
        --slide-level=2 \
        --theme=Madrid \
        --colortheme=default

    # Generate PPTX presentation  
    echo "Generating PowerPoint presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.pptx \
        --slide-level=2

    echo "✅ Presentations generated in presentations/output/"
else
    echo "⚠️ Pandoc not available. Presentations remain in markdown format."
fi

# Create presentation index
cat > presentations/output/index.html << 'INDEX_END'
<!DOCTYPE html>
<html>
<head>
    <title>GCP Landing Zone Workshop Presentations</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .presentation { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .download-links a { margin-right: 15px; text-decoration: none; color: #0066cc; }
        .download-links a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>GCP Landing Zone Workshop Presentations</h1>
    
    <div class="presentation">
        <h2>Workshop Overview</h2>
        <p>Main presentation covering workshop objectives, structure, and learning outcomes.</p>
        <div class="download-links">
            <a href="workshop-overview.html">HTML Slides</a>
            <a href="workshop-overview.pdf">PDF</a>
            <a href="workshop-overview.pptx">PowerPoint</a>
        </div>
    </div>
    
    <div class="presentation">
        <h2>Architecture Diagrams</h2>
        <p>Comprehensive architecture documentation and diagrams.</p>
        <div class="download-links">
            <a href="../diagrams/architecture-overview.md">Architecture Guide</a>
        </div>
    </div>
    
    <div class="presentation">
        <h2>Concept Guides</h2>
        <p>Detailed conceptual explanations for each lab.</p>
        <div class="download-links">
            <a href="../guides/lab-01-concepts.md">Lab 01 Concepts</a>
            <a href="../guides/lab-02-concepts.md">Lab 02 Concepts</a>
        </div>
    </div>
    
    <p><em>Generated on: $(date)</em></p>
</body>
</html>
INDEX_END

echo "✅ Presentation index created: presentations/output/index.html"
GENERATE_PRESENTATIONS_END

chmod +x workshop-materials/docs/generate-presentations.sh

# Create comprehensive reference guide
cat > workshop-materials/docs/reference/complete-workshop-guide.md << 'COMPLETE_GUIDE_END'
# GCP Landing Zone Workshop - Complete Reference Guide

## Table of Contents

1. [Workshop Overview](#workshop-overview)
2. [Learning Path](#learning-path)
3. [Technical Prerequisites](#technical-prerequisites)
4. [Lab Concepts Summary](#lab-concepts-summary)
5. [Architecture Patterns](#architecture-patterns)
6. [Security Framework](#security-framework)
7. [Compliance Requirements](#compliance-requirements)
8. [Best Practices](#best-practices)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Additional Resources](#additional-resources)

---

## Workshop Overview

### Objective
Build a complete, enterprise-grade Google Cloud Platform landing zone for **TechCorp**, a fintech company requiring regulatory compliance, enterprise security, high availability, and operational excellence.

### Target Audience
- **Cloud Architects**: Designing enterprise cloud architectures
- **DevOps Engineers**: Implementing automation and CI/CD
- **Security Professionals**: Implementing security and compliance
- **Platform Teams**: Building shared infrastructure platforms

### Workshop Outcomes
- **Technical Mastery**: Advanced GCP services and Terraform automation
- **Security Expertise**: Enterprise-grade security implementations
- **Compliance Knowledge**: Fintech regulatory requirements
- **Operational Excellence**: Monitoring, logging, and incident response

---

## Learning Path

### Day 1: Foundation Building
```
Lab 01 → Lab 02 → Lab 03 → Lab 04 → Lab 05 → Lab 06 → Lab 07
  ↓        ↓        ↓        ↓        ↓        ↓        ↓
Projects  Terraform Network   Security   IAM    Monitor  Logging
& IAM     Modules   & LB     Controls   Roles   & Alert  Central
```

### Day 2: Advanced Implementation
```
Lab 08 → Lab 09 → Lab 10 → Lab 11 → Lab 12 → Lab 13 → Lab 14
  ↓        ↓        ↓        ↓        ↓        ↓        ↓
Shared   Workload  Security Advanced  Disaster  Cost    Final
Services Apps/GKE  Compliance Monitor  Recovery  Mgmt    Valid
```

### Knowledge Progression
1. **Foundation**: GCP hierarchy, Terraform, basic networking
2. **Security**: IAM, encryption, compliance controls
3. **Operations**: Monitoring, logging, automation
4. **Advanced**: Shared services, workloads, optimization
5. **Production**: DR, cost management, validation

---

## Technical Prerequisites

### Required Knowledge
- **GCP Fundamentals**: Basic understanding of core services
- **Terraform Basics**: Resource definition and state management
- **Networking Concepts**: VPC, subnets, routing, load balancing
- **Linux Command Line**: Basic shell scripting and commands
- **Security Principles**: Authentication, authorization, encryption

### Required Tools
- **GCP Account**: With billing enabled and appropriate quotas
- **Local Environment**: Development machine with required software
- **Terraform**: Version 1.5 or later
- **gcloud CLI**: Latest version with authentication configured
- **Code Editor**: VS Code recommended with extensions

### Environment Setup Checklist
- [ ] GCP project created with Owner permissions
- [ ] Billing account linked with sufficient credits
- [ ] Required APIs enabled (35+ services)
- [ ] gcloud CLI authenticated
- [ ] Terraform installed and verified
- [ ] SSH keys generated and configured
- [ ] Terraform state bucket created
- [ ] Workshop materials downloaded

---

## Lab Concepts Summary

### Lab 01: GCP Organizational Foundation
**Key Concepts**: Resource hierarchy, project management, service accounts, Infrastructure as Code
**Deliverables**: Project structure, service accounts, storage buckets, Terraform patterns
**Integration**: Foundation for all subsequent labs

### Lab 02: Terraform Environment Setup  
**Key Concepts**: Module architecture, remote state, VPC networking, IAM automation
**Deliverables**: VPC with subnets, NAT gateway, IAM modules, workload service accounts
**Integration**: Networking foundation and Terraform patterns for all labs

### Lab 03: Core Networking Architecture
**Key Concepts**: Multi-tier architecture, load balancing, auto-scaling, health checks
**Deliverables**: Firewall rules, instance groups, global load balancer, startup automation
**Integration**: Network infrastructure for application workloads

### Lab 04: Network Security Implementation
**Key Concepts**: Cloud Armor, DDoS protection, WAF rules, threat detection
**Deliverables**: Security policies, rate limiting, geo-blocking, attack mitigation
**Integration**: Security layer for web applications

### Lab 05: Identity and Access Management
**Key Concepts**: Custom roles, least privilege, Workload Identity, conditional access
**Deliverables**: Role definitions, service account bindings, access policies
**Integration**: Identity foundation for all services

### Lab 06: Cloud Monitoring Foundation
**Key Concepts**: Metrics collection, dashboards, alerting, SLI/SLO monitoring
**Deliverables**: Monitoring workspace, custom dashboards, alert policies
**Integration**: Observability foundation for all infrastructure

### Lab 07: Cloud Logging Architecture
**Key Concepts**: Centralized logging, log sinks, BigQuery integration, compliance retention
**Deliverables**: Log storage, routing, analysis, compliance audit trails
**Integration**: Logging foundation for security and operations

### Lab 08: Shared Services Implementation
**Key Concepts**: DNS management, certificate automation, service discovery
**Deliverables**: Private/public DNS zones, SSL certificates, shared infrastructure
**Integration**: Foundational services for all environments

### Lab 09: Workload Environment Setup
**Key Concepts**: Multi-tier applications, GKE, auto-scaling, high availability
**Deliverables**: Application infrastructure, container platform, scaling policies
**Integration**: Runtime environment for business applications

### Lab 10: Security Controls & Compliance
**Key Concepts**: Encryption, DLP, Binary Authorization, compliance automation
**Deliverables**: KMS keys, data protection, container security, regulatory compliance
**Integration**: Security controls for all data and applications

### Lab 11: Advanced Monitoring & Alerting
**Key Concepts**: SRE practices, error budgets, incident response, performance analytics
**Deliverables**: Advanced monitoring, automated response, capacity planning
**Integration**: Operational excellence across all services

### Lab 12: Disaster Recovery & Backup
**Key Concepts**: Business continuity, backup automation, multi-region DR
**Deliverables**: Backup schedules, DR procedures, recovery automation
**Integration**: Data protection and business continuity

### Lab 13: Cost Management & Optimization
**Key Concepts**: Cost monitoring, budgeting, resource optimization, FinOps
**Deliverables**: Cost controls, optimization automation, financial governance
**Integration**: Cost efficiency across all infrastructure

### Lab 14: Final Validation & Optimization
**Key Concepts**: End-to-end testing, performance optimization, production readiness
**Deliverables**: Validation framework, optimization recommendations, handover documentation
**Integration**: Final verification of complete landing zone

---

## Architecture Patterns

### Network Architecture
- **Hub-and-Spoke**: Shared VPC with project-specific subnets
- **Multi-Tier**: Web, application, and data tier separation
- **Security Zones**: DMZ, internal, and management networks
- **Hybrid Connectivity**: VPN and Interconnect for on-premises

### Security Architecture
- **Defense in Depth**: Multiple security layers
- **Zero Trust**: Never trust, always verify
- **Least Privilege**: Minimal required permissions
- **Continuous Monitoring**: Real-time threat detection

### Data Architecture
- **Encryption Everywhere**: At rest, in transit, in use
- **Data Classification**: Sensitive data identification and protection
- **Retention Policies**: Compliance-driven data lifecycle
- **Backup Strategy**: Multi-region, automated, tested

### Application Architecture
- **Microservices**: Containerized, loosely coupled services
- **API Gateway**: Centralized API management and security
- **Auto-scaling**: Demand-based resource allocation
- **Circuit Breaker**: Fault tolerance and resilience

---

## Security Framework

### Identity and Access Management
```
User → Google Identity → IAM Roles → Service Accounts → GCP Resources
  ↓         ↓             ↓            ↓               ↓
MFA      SSO/SAML     Custom       Workload        Least
2FA      Federation   Roles        Identity        Privilege
```

### Data Protection
```
Data Classification → Encryption → Access Controls → Monitoring
       ↓                ↓             ↓              ↓
   Sensitive          CMEK         DLP Policies    Audit Logs
   Public            Google        Access Reviews  Alert Rules
   Internal          Managed       Conditional     SIEM/SOAR
   Restricted        HSM           Access          Response
```

### Network Security
```
Internet → Cloud Armor → Load Balancer → Firewall → Private Network
    ↓          ↓            ↓              ↓            ↓
  DDoS      WAF Rules    SSL Term      Micro-seg    Private IPs
  Filter    Rate Limit   Cert Mgmt     Ingress      No External
  Geo-block Bot Protect  HTTPS Only    Egress       Access
```

### Compliance Controls
```
Policy Definition → Implementation → Monitoring → Reporting
       ↓               ↓              ↓           ↓
   Org Policies    Terraform       Continuous   Compliance
   Security Pol    Automation      Validation   Dashboard
   Data Policies   CI/CD           Alerts       Audit Reports
   Access Pol      Testing         Remediation  Risk Assessment
```

---

## Compliance Requirements

### SOX (Sarbanes-Oxley) Requirements
- **Audit Trails**: Complete, immutable logs of all activities
- **Change Management**: Controlled, approved infrastructure changes
- **Access Controls**: Segregation of duties and access reviews
- **Data Protection**: Financial data encryption and retention
- **Documentation**: Comprehensive policies and procedures

### PCI DSS (Payment Card Industry) Requirements
- **Network Segmentation**: Isolated cardholder data environment
- **Encryption**: Strong cryptography for data protection
- **Access Controls**: Multi-factor authentication and unique IDs
- **Monitoring**: Continuous monitoring and regular testing
- **Vulnerability Management**: Regular scans and patch management

### GDPR (General Data Protection Regulation) Requirements
- **Data Minimization**: Collect only necessary personal data
- **Consent Management**: Lawful basis and user consent tracking
- **Right to Erasure**: Data deletion and portability capabilities
- **Breach Notification**: 72-hour breach notification procedures
- **Privacy by Design**: Built-in privacy protection

### Implementation Strategy
1. **Policy as Code**: Terraform and OPA for policy enforcement
2. **Automated Compliance**: Continuous validation and remediation
3. **Audit Automation**: Real-time compliance monitoring
4. **Documentation**: Automated generation and maintenance

---

## Best Practices

### Terraform Best Practices
- **Module Design**: Single responsibility, reusable modules
- **State Management**: Remote state with locking and encryption
- **Variable Validation**: Type constraints and validation rules
- **Output Organization**: Structured outputs for integration
- **Documentation**: Comprehensive README and examples

### Security Best Practices
- **Principle of Least Privilege**: Minimal required permissions
- **Defense in Depth**: Multiple security layers
- **Regular Rotation**: Keys, secrets, and access reviews
- **Continuous Monitoring**: Real-time threat detection
- **Incident Response**: Automated response and escalation

### Operational Best Practices
- **Infrastructure as Code**: Version-controlled infrastructure
- **Monitoring and Alerting**: Comprehensive observability
- **Automated Testing**: Validation and integration testing
- **Documentation**: Living documentation and runbooks
- **Change Management**: Controlled deployment processes

### Cost Optimization Best Practices
- **Right-sizing**: Appropriate resource allocation
- **Scheduled Resources**: Start/stop non-production resources
- **Reserved Capacity**: Committed use discounts
- **Monitoring**: Cost alerts and budget controls
- **Regular Reviews**: Quarterly cost optimization reviews

---

## Troubleshooting Guide

### Common Terraform Issues

#### State Lock Issues
```bash
# View current locks
terraform force-unlock LOCK_ID

# Prevent locks with proper CI/CD
# Use terraform plan in pull requests
# Use terraform apply in protected branches
```

#### Module Path Issues
```bash
# Local modules
source = "../modules/vpc-network"

# Remote modules  
source = "git::https://github.com/org/modules.git//vpc?ref=v1.0"

# Registry modules
source = "terraform-google-modules/network/google"
version = "~> 7.0"
```

#### Resource Dependencies
```hcl
# Explicit dependencies
resource "google_compute_instance" "app" {
  depends_on = [
    google_compute_subnetwork.app_subnet,
    google_service_account.app_sa
  ]
}

# Implicit dependencies (preferred)
network_interface {
  subnetwork = google_compute_subnetwork.app_subnet.self_link
}
```

### Common GCP Issues

#### API Enablement
```bash
# Check enabled APIs
gcloud services list --enabled

# Enable required APIs
gcloud services enable compute.googleapis.com

# Batch enable APIs
apis=("compute.googleapis.com" "iam.googleapis.com")
for api in "${apis[@]}"; do
  gcloud services enable $api
done
```

#### Permission Issues
```bash
# Check current permissions
gcloud projects get-iam-policy PROJECT_ID

# Test service account permissions
gcloud auth activate-service-account --key-file=key.json
gcloud auth list
```

#### Quota Limits
```bash
# Check quotas
gcloud compute project-info describe --format="table(quotas.metric,quotas.limit,quotas.usage)"

# Request quota increases
# Use GCP Console → IAM & Admin → Quotas
```

### Network Troubleshooting

#### Connectivity Issues
```bash
# Test private Google access
gcloud compute ssh INSTANCE --command="curl -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/hostname"

# Check firewall rules
gcloud compute firewall-rules list --filter="direction:INGRESS"

# Test DNS resolution
nslookup HOSTNAME
dig HOSTNAME
```

#### Load Balancer Issues
```bash
# Check backend health
gcloud compute backend-services get-health BACKEND_SERVICE --global

# Check SSL certificates
gcloud compute ssl-certificates list

# Test connectivity
curl -I https://LOAD_BALANCER_IP
```

---

## Additional Resources

### Official Documentation
- [GCP Architecture Center](https://cloud.google.com/architecture)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [GCP Networking Documentation](https://cloud.google.com/vpc/docs)

### Security Frameworks
- [CIS GCP Benchmark](https://www.cisecurity.org/benchmark/google_cloud_platform)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [SANS Security Controls](https://www.sans.org/critical-security-controls/)

### Compliance Resources
- [SOX Compliance Guide](https://www.sox-online.com/)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [GDPR Compliance](https://gdpr.eu/)
- [ISO 27001 Framework](https://www.iso.org/isoiec-27001-information-security.html)

### Training and Certification
- [Google Cloud Professional Cloud Architect](https://cloud.google.com/certification/cloud-architect)
- [Google Cloud Professional Cloud Security Engineer](https://cloud.google.com/certification/cloud-security-engineer)
- [Terraform Associate Certification](https://www.hashicorp.com/certification/terraform-associate)
- [Kubernetes Certified Administrator](https://www.cncf.io/certification/cka/)

### Community Resources
- [GCP Community](https://cloud.google.com/community)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-cloud-platform)
- [Reddit r/googlecloud](https://www.reddit.com/r/googlecloud/)

---

## Workshop Support

### During the Workshop
- **Instructor Support**: Real-time guidance and troubleshooting
- **Technical Assistants**: Hands-on help during lab exercises
- **Slack Channel**: Participant collaboration and Q&A
- **Workshop Materials**: Complete guides and reference solutions

### Post-Workshop
- **Follow-up Sessions**: Q&A and advanced topics
- **Community Access**: Ongoing collaboration and networking
- **Resource Library**: Updated materials and best practices
- **Mentorship Program**: Continued learning and development

---

**Document Version**: 2.0  
**Last Updated**: $(date +"%Y-%m-%d")  
**Workshop Duration**: 14 hours over 2 days  
**Participants**: Maximum 20 for optimal learning experience

*This guide serves as the complete reference for the GCP Landing Zone Workshop. Keep it handy throughout the workshop and refer back to it as you implement similar architectures in your own environment.*
COMPLETE_GUIDE_END

# Create quick reference cards
cat > workshop-materials/docs/reference/quick-reference.md << 'QUICK_REF_END'
# GCP Landing Zone Workshop - Quick Reference

## Essential Commands

### Terraform Commands
```bash
# Initialize and plan
terraform init
terraform plan -var-file=terraform.tfvars

# Apply and destroy
terraform apply -auto-approve
terraform destroy -auto-approve

# State management
terraform state list
terraform state show RESOURCE
terraform output

# Validation
terraform validate
terraform fmt
```

### GCP Commands
```bash
# Authentication
gcloud auth login
gcloud auth application-default login
gcloud auth list

# Project management
gcloud config set project PROJECT_ID
gcloud projects list
gcloud projects describe PROJECT_ID

# Service management
gcloud services list --enabled
gcloud services enable API_NAME

# Resource inspection
gcloud compute instances list
gcloud compute networks list
gcloud iam service-accounts list
```

### Workshop Environment
```bash
# Source configuration
source ~/gcp-landing-zone-workshop/workshop-config.env

# Check environment
echo $PROJECT_ID
echo $TF_STATE_BUCKET
echo $REGION

# Navigate to lab
cd ~/gcp-landing-zone-workshop/lab-XX

# Run validation
./validation/validate-lab-XX.sh
```

## Key Architecture Patterns

### Network CIDR Allocation
```
Management:    10.0.0.0/24   (256 IPs)
Web Tier:      10.1.0.0/22   (1024 IPs) 
App Tier:      10.1.4.0/22   (1024 IPs)
Data Tier:     10.1.8.0/22   (1024 IPs)
```

### Service Account Naming
```
Format: {purpose}-{environment}-sa
Examples:
- web-tier-sa
- app-tier-sa  
- monitoring-sa
- backup-manager-sa
```

### Resource Labeling
```hcl
labels = {
  workshop    = "gcp-landing-zone"
  lab         = "XX"
  environment = "production"
  component   = "networking"
  owner       = "platform-team"
}
```

## Troubleshooting Checklist

### Lab Won't Deploy
- [ ] Check authentication: `gcloud auth list`
- [ ] Verify project: `gcloud config get-value project`
- [ ] Check APIs: `gcloud services list --enabled`
- [ ] Validate Terraform: `terraform validate`
- [ ] Check state bucket: `gsutil ls gs://$TF_STATE_BUCKET`

### Terraform Issues
- [ ] Run `terraform init -upgrade`
- [ ] Check `.terraform.lock.hcl`
- [ ] Verify module paths
- [ ] Check variable values
- [ ] Review provider versions

### Network Issues  
- [ ] Check firewall rules: `gcloud compute firewall-rules list`
- [ ] Verify subnet CIDR ranges
- [ ] Test private Google access
- [ ] Check NAT gateway configuration
- [ ] Validate DNS resolution

### Permission Issues
- [ ] Check IAM policies: `gcloud projects get-iam-policy PROJECT_ID`
- [ ] Verify service account roles
- [ ] Check organization policies
- [ ] Validate API permissions
- [ ] Review conditional access

## Emergency Procedures

### Lab Cleanup
```bash
cd ~/gcp-landing-zone-workshop/lab-XX/terraform
terraform destroy -auto-approve
```

### Force Unlock Terraform
```bash
terraform force-unlock LOCK_ID
```

### Reset Authentication
```bash
gcloud auth revoke --all
gcloud auth login
gcloud auth application-default login
```

### Contact Information
- **Lead Instructor**: [instructor@company.com]
- **Technical Support**: [support@company.com]  
- **Slack Channel**: #gcp-workshop
- **Emergency Contact**: [emergency@company.com]
QUICK_REF_END

echo "
==========================================
🎉 Workshop Documentation & Presentations Created! 🎉
==========================================

Documentation Generated:
✅ Main Workshop Presentation (workshop-overview.md)
✅ Detailed Concept Guides (Lab 01 & 02 complete)
✅ Architecture Diagrams and Documentation
✅ Complete Workshop Reference Guide
✅ Quick Reference Cards and Troubleshooting
✅ Presentation Generator Script

Directory Structure:
workshop-materials/docs/
├── presentations/
│   ├── workshop-overview.md      # Main presentation (45 slides)
│   └── generate-presentations.sh # Convert to PDF/HTML/PPTX
├── guides/
│   ├── lab-01-concepts.md        # Comprehensive concept guide
│   ├── lab-02-concepts.md        # Advanced Terraform concepts
│   └── [additional concept guides for other labs]
├── diagrams/
│   └── architecture-overview.md  # Complete architecture diagrams
├── reference/
│   ├── complete-workshop-guide.md # Master reference (50+ pages)
│   └── quick-reference.md         # Essential commands & patterns
└── generate-presentations.sh     # Master presentation generator

Key Features:
📊 Professional presentation slides (ready for delivery)
📖 Comprehensive concept explanations for each lab
🏗️ Detailed architecture diagrams and patterns
📚 Complete workshop reference guide (50+ pages)
🚀 Quick reference for commands and troubleshooting
🎯 Conversion scripts for PDF/PowerPoint/HTML formats

Presentation Formats:
1. **Markdown**: Source format for easy editing
2. **HTML**: Interactive reveal.js slides
3. **PDF**: Printable slides for handouts
4. **PowerPoint**: Standard presentation format

Generate Presentations:
cd workshop-materials/docs/
chmod +x generate-presentations.sh
./generate-presentations.sh

# Requires pandoc installation:
# Ubuntu/Debian: sudo apt install pandoc
# macOS: brew install pandoc
# Windows: Download from https://pandoc.org/

Workshop Presentation Features:
🎯 45+ slides covering complete workshop
📈 Progressive learning path visualization
🔧 Hands-on lab structure and timing
🛡️ Security and compliance frameworks
🏗️ Architecture patterns and best practices
📊 Assessment criteria and success metrics

Documentation Features:
📖 Comprehensive concept explanations
🏗️ ASCII architecture diagrams
💡 Best practices and patterns
🔧 Detailed troubleshooting guides
📚 Additional learning resources
🎯 Assessment questions and answers

Ready for Professional Delivery! 🚀
========================================"

log "✅ Workshop documentation and presentations created successfully!"
log "📁 Location: workshop-materials/docs/"
log "🎯 Start with: docs/presentations/workshop-overview.md"
log "📚 Reference: docs/reference/complete-workshop-guide.md"
log "🔧 Generate presentations: docs/generate-presentations.sh"

# Validate all generated content
validate_documentation

# Display usage instructions
cat << 'USAGE_END'

� Quick Start Guide:
=====================

1. Review main presentation:
   less workshop-materials/docs/presentations/workshop-overview.md

2. Generate presentation formats:
   cd workshop-materials/docs/
   chmod +x generate-presentations.sh
   ./generate-presentations.sh

3. Access complete reference:
   less workshop-materials/docs/reference/complete-workshop-guide.md

4. View architecture diagrams:
   less workshop-materials/docs/diagrams/architecture-overview.md

📦 Prerequisites for presentation generation:
- Ubuntu/Debian: sudo apt install pandoc
- macOS: brew install pandoc  
- Windows: Download from https://pandoc.org/

USAGE_END


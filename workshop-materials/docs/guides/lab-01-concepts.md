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

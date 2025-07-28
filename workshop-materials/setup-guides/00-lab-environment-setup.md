# Lab Environment Setup Guide

## Overview
This comprehensive guide provides detailed instructions for setting up the lab environment for the GCP Landing Zone Workshop. This 2-day workshop will build a production-ready GCP Landing Zone for TechCorp, a fintech company.

## Prerequisites Check

### Participant Checklist
Before starting the workshop, ensure you have:

- [ ] **GCP Account**: Valid Google Cloud account with appropriate permissions
- [ ] **Individual Project**: Assigned participant project with Owner role
- [ ] **Billing Access**: Project linked to training billing account ($200 limit)
- [ ] **Local Environment**: Development machine meeting requirements
- [ ] **Software Installed**: All required tools installed and configured
- [ ] **Network Access**: Stable internet connection and API access
- [ ] **Workshop Materials**: Access to lab guides and Terraform templates

### System Requirements

#### Hardware Requirements
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 20GB free disk space
- **CPU**: Multi-core processor (2+ cores recommended)
- **Network**: Stable broadband connection (minimum 10 Mbps)

#### Operating System Support
- **Windows**: Windows 10/11 (with WSL2 for best experience)
- **macOS**: macOS 10.15 (Catalina) or later
- **Linux**: Ubuntu 18.04+, CentOS 7+, or equivalent

## Detailed Setup Instructions

### 1. GCP Project Access Verification

```bash
# Set your participant project ID (replace with your assigned project)
export PROJECT_ID="participant-project-XX"  # Replace XX with your number
export REGION="us-central1"
export ZONE="us-central1-a"

# Verify project access
gcloud config set project $PROJECT_ID
gcloud projects describe $PROJECT_ID

# Expected output: Project details with your participant project information
echo "Project verification complete for: $PROJECT_ID"
```

### 2. Required APIs Enablement

```bash
# Enable all required APIs for the workshop
echo "Enabling required GCP APIs..."

apis=(
    "compute.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "dns.googleapis.com"
    "logging.googleapis.com"
    "monitoring.googleapis.com"
    "storage-api.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudkms.googleapis.com"
    "securitycenter.googleapis.com"
    "cloudasset.googleapis.com"
    "servicenetworking.googleapis.com"
    "container.googleapis.com"
    "pubsub.googleapis.com"
    "bigquery.googleapis.com"
    "cloudscheduler.googleapis.com"
    "cloudfunctions.googleapis.com"
)

for api in "${apis[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --project=$PROJECT_ID
    if [ $? -eq 0 ]; then
        echo "✓ Successfully enabled $api"
    else
        echo "✗ Failed to enable $api"
    fi
done

echo "All APIs enablement process complete!"
```

## Workshop Schedule Overview

### Day 1: Foundation (Labs 01-07)
- **Lab 01**: GCP Organizational Foundation (45 min)
- **Lab 02**: Terraform Environment Setup (45 min)
- **Lab 03**: Core Networking Architecture (60 min)
- **Lab 04**: Network Security Implementation (60 min)
- **Lab 05**: Identity and Access Management (60 min)
- **Lab 06**: Cloud Monitoring Foundation (45 min)
- **Lab 07**: Cloud Logging Architecture (45 min)

### Day 2: Advanced Implementation (Labs 08-14)
- **Lab 08**: Shared Services Implementation (60 min)
- **Lab 09**: Workload Environment Setup (60 min)
- **Lab 10**: Security Controls & Compliance (60 min)
- **Lab 11**: Advanced Monitoring & Alerting (60 min)
- **Lab 12**: Disaster Recovery & Backup (45 min)
- **Lab 13**: Cost Management & Optimization (45 min)
- **Lab 14**: Final Validation & Optimization (60 min)

**Total Workshop Duration**: 14 hours over 2 days

Good luck with your GCP Landing Zone Workshop! 🚀

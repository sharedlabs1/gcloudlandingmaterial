# GCP Landing Zone Workshop - Complete Setup Guide

## Overview
This comprehensive guide provides detailed instructions for setting up your environment for the GCP Landing Zone Workshop. This 2-day workshop will build a production-ready GCP Landing Zone for TechCorp, a fintech company.

## Prerequisites Check

### Participant Checklist
Before starting the workshop, ensure you have:

- [ ] **GCP Account**: Valid Google Cloud account with appropriate permissions
- [ ] **Individual Project**: Assigned participant project with Owner role  
- [ ] **Billing Access**: Project linked to training billing account ($200 limit)
- [ ] **Local Environment**: Ubuntu/Linux development machine meeting requirements
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
- **Primary**: Ubuntu 20.04 LTS or later (recommended)
- **Alternative**: Other Linux distributions (CentOS 8+, Debian 10+)
- **Cloud Shell**: Google Cloud Shell (fallback option)

## Environment Setup

### Step 1: System Preparation (Ubuntu/Linux)

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    vim \
    nano \
    tree \
    htop

# Verify installation
echo "System preparation complete!"
```

### Step 2: Install Google Cloud SDK

```bash
# Add Google Cloud SDK repository
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Install Google Cloud SDK
sudo apt update
sudo apt install -y google-cloud-sdk

# Verify installation
gcloud version

# Install additional components
gcloud components install \
    kubectl \
    terraform \
    alpha \
    beta

echo "Google Cloud SDK installation complete!"
```

### Step 3: Install Terraform

```bash
# Install Terraform using official HashiCorp repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install -y terraform

# Verify installation
terraform version

# Install Terraform docs (optional)
go install github.com/terraform-docs/terraform-docs@latest

echo "Terraform installation complete!"
```

### Step 4: Install Docker (Optional - for containerized workloads)

```bash
# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation (may need to log out and back in)
docker --version

echo "Docker installation complete!"
```

### Step 5: Install Additional Tools

```bash
# Install Go (for some tools)
sudo apt install -y golang-go

# Install Node.js and npm (for some utilities)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python tools
sudo apt install -y python3 python3-pip python3-venv

# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Install text processing tools
sudo apt install -y jq yq

echo "Additional tools installation complete!"
```

## GCP Authentication and Project Setup

### Step 6: GCP Authentication

```bash
# **IMPORTANT**: Replace with your actual GCP credentials
# These are PLACEHOLDER values - you MUST replace them with your actual information

# Initialize gcloud authentication
gcloud auth login

# Set up application default credentials
gcloud auth application-default login

# Set your project configuration
export PROJECT_ID="YOUR_PROJECT_ID_HERE"  # REPLACE WITH YOUR ACTUAL PROJECT ID
export REGION="us-central1"
export ZONE="us-central1-a"
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT_ID"  # REPLACE WITH YOUR ACTUAL BILLING ACCOUNT

# Configure gcloud
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Verify authentication and project access
gcloud auth list
gcloud projects describe $PROJECT_ID
gcloud billing projects describe $PROJECT_ID

echo "GCP authentication complete!"
```

### Step 7: Create Workshop Environment Variables

```bash
# Create workshop configuration file
mkdir -p ~/gcp-landing-zone-workshop
cd ~/gcp-landing-zone-workshop

# Create workshop configuration
cat > workshop-config.env << 'EOF'
# Workshop Configuration - Update with your actual values
export PROJECT_ID="YOUR_PROJECT_ID_HERE"
export REGION="us-central1"
export ZONE="us-central1-a"
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT_ID"

# Workshop specific variables
export WORKSHOP_USER=$(whoami)
export WORKSHOP_HOME="$HOME/gcp-landing-zone-workshop"
export TERRAFORM_VERSION="1.5.0"
export PARTICIPANT_ID="${PROJECT_ID##*-}"

# Terraform state bucket (will be created)
export TF_STATE_BUCKET="${PROJECT_ID}-terraform-state"

# Common tags for all resources
export COMMON_TAGS="workshop=gcp-landing-zone,participant=${PARTICIPANT_ID},created-by=terraform"

# Workshop timestamps
export WORKSHOP_START_DATE=$(date +%Y%m%d)
export WORKSHOP_START_TIME=$(date +%H%M%S)

echo "Workshop environment configured!"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Participant: $PARTICIPANT_ID"
EOF

# Source the configuration
source workshop-config.env

echo "Workshop environment variables created!"
```

### Step 8: Enable Required GCP APIs

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
    "serviceusage.googleapis.com"
    "cloudidentity.googleapis.com"
    "admin.googleapis.com"
    "cloudsql.googleapis.com"
    "redis.googleapis.com"
    "memcache.googleapis.com"
    "file.googleapis.com"
    "vpcaccess.googleapis.com"
    "networkmanagement.googleapis.com"
    "orgpolicy.googleapis.com"
    "accesscontextmanager.googleapis.com"
    "binaryauthorization.googleapis.com"
    "containerscanning.googleapis.com"
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

### Step 9: Create Terraform State Bucket

```bash
# Create Terraform state bucket
echo "Creating Terraform state bucket..."

# Create bucket for Terraform state
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$TF_STATE_BUCKET

# Enable versioning
gsutil versioning set on gs://$TF_STATE_BUCKET

# Set bucket policy
gsutil iam ch user:$(gcloud config get-value account):objectAdmin gs://$TF_STATE_BUCKET

echo "✓ Terraform state bucket created: gs://$TF_STATE_BUCKET"
```

### Step 10: Workshop Directory Structure

```bash
# Create workshop directory structure
cd ~/gcp-landing-zone-workshop

# Create directory structure for all labs
mkdir -p lab-{01..14}/{terraform,scripts,docs,outputs,validation}

# Create shared directories
mkdir -p {shared,templates,utils,backups}

# Create quick reference files
cat > README.md << 'EOF'
# GCP Landing Zone Workshop

## Directory Structure
- lab-01 through lab-14: Individual lab directories
- shared: Shared configurations and utilities
- templates: Terraform templates and snippets
- utils: Workshop utility scripts
- backups: Configuration backups

## Getting Started
1. Source the workshop configuration: `source workshop-config.env`
2. Navigate to lab directory: `cd lab-01`
3. Follow the lab guide instructions

## Lab Progress Tracking
- [ ] Lab 01: GCP Organizational Foundation
- [ ] Lab 02: Terraform Environment Setup
- [ ] Lab 03: Core Networking Architecture
- [ ] Lab 04: Network Security Implementation
- [ ] Lab 05: Identity and Access Management
- [ ] Lab 06: Cloud Monitoring Foundation
- [ ] Lab 07: Cloud Logging Architecture
- [ ] Lab 08: Shared Services Implementation
- [ ] Lab 09: Workload Environment Setup
- [ ] Lab 10: Security Controls & Compliance
- [ ] Lab 11: Advanced Monitoring & Alerting
- [ ] Lab 12: Disaster Recovery & Backup
- [ ] Lab 13: Cost Management & Optimization
- [ ] Lab 14: Final Validation & Optimization

## Support
- Workshop documentation: docs/
- Troubleshooting: Check individual lab validation scripts
- Contact: Workshop instructor or support team
EOF

echo "✓ Workshop directory structure created!"
```

### Step 11: Create Validation Scripts

```bash
# Create general validation script
cat > validate-setup.sh << 'EOF'
#!/bin/bash

echo "=== GCP Landing Zone Workshop - Setup Validation ==="
echo "Started at: $(date)"
echo

# Source workshop configuration
source workshop-config.env

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

# Check system requirements
echo "Checking system requirements..."
check_status $? "System requirements checked"

# Check required tools
echo "Checking required tools..."
command -v gcloud >/dev/null 2>&1
check_status $? "Google Cloud SDK installed"

command -v terraform >/dev/null 2>&1
check_status $? "Terraform installed"

command -v docker >/dev/null 2>&1
check_status $? "Docker installed"

command -v kubectl >/dev/null 2>&1
check_status $? "kubectl installed"

command -v jq >/dev/null 2>&1
check_status $? "jq installed"

# Check GCP authentication
echo "Checking GCP authentication..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"
check_status $? "GCP authentication active"

# Check project access
echo "Checking project access..."
gcloud projects describe $PROJECT_ID >/dev/null 2>&1
check_status $? "Project access verified"

# Check billing
echo "Checking billing configuration..."
gcloud billing projects describe $PROJECT_ID >/dev/null 2>&1
check_status $? "Billing configuration verified"

# Check APIs
echo "Checking API enablement..."
apis_to_check=("compute.googleapis.com" "iam.googleapis.com" "storage-api.googleapis.com")
for api in "${apis_to_check[@]}"; do
    gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"
    check_status $? "API enabled: $api"
done

# Check Terraform state bucket
echo "Checking Terraform state bucket..."
gsutil ls gs://$TF_STATE_BUCKET >/dev/null 2>&1
check_status $? "Terraform state bucket accessible"

# Check workshop directory structure
echo "Checking workshop directory structure..."
[ -d "$WORKSHOP_HOME" ]
check_status $? "Workshop directory exists"

[ -f "$WORKSHOP_HOME/workshop-config.env" ]
check_status $? "Workshop configuration file exists"

# Summary
echo
echo "=== Setup Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"
echo "Total checks: $((validation_passed + validation_failed))"

if [ $validation_failed -eq 0 ]; then
    echo
    echo "🎉 Workshop setup validation PASSED!"
    echo "You are ready to begin the workshop."
    
    # Create validation timestamp
    echo "$(date -Iseconds)" > .setup-validated
    
    exit 0
else
    echo
    echo "❌ Workshop setup validation FAILED."
    echo "Please review and fix the issues above before starting the workshop."
    exit 1
fi
EOF

chmod +x validate-setup.sh

echo "✓ Validation script created!"
```

### Step 12: Create Utility Scripts

```bash
# Create utility scripts
mkdir -p utils

# Create project cleanup script
cat > utils/cleanup-projects.sh << 'EOF'
#!/bin/bash

echo "=== Project Cleanup Script ==="
echo "This script will clean up workshop projects."
echo "WARNING: This will delete all workshop resources!"
echo

source ../workshop-config.env

read -p "Are you sure you want to delete all workshop projects? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# List projects to be deleted
projects_to_delete=(
    "${PROJECT_ID}-shared"
    "${PROJECT_ID}-dev"
    "${PROJECT_ID}-staging"
    "${PROJECT_ID}-prod-sim"
)

for project in "${projects_to_delete[@]}"; do
    echo "Deleting project: $project"
    gcloud projects delete $project --quiet
done

echo "Cleanup complete!"
EOF

# Create backup script
cat > utils/backup-configs.sh << 'EOF'
#!/bin/bash

echo "=== Configuration Backup Script ==="
source ../workshop-config.env

backup_dir="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $backup_dir

# Backup Terraform configurations
for lab in lab-{01..14}; do
    if [ -d "$lab/terraform" ]; then
        cp -r "$lab/terraform" "$backup_dir/$lab-terraform"
        echo "✓ Backed up $lab terraform configuration"
    fi
done

# Backup workshop configuration
cp workshop-config.env "$backup_dir/"

echo "✓ Backup complete: $backup_dir"
EOF

chmod +x utils/*.sh

echo "✓ Utility scripts created!"
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

## Pre-Workshop Checklist

### ✅ Environment Setup
- [ ] System prepared with all required tools
- [ ] Google Cloud SDK installed and configured
- [ ] Terraform installed and verified
- [ ] Docker installed (optional)
- [ ] Workshop directory structure created

### ✅ GCP Configuration
- [ ] GCP account authenticated
- [ ] Project access verified
- [ ] Billing configuration confirmed
- [ ] All required APIs enabled
- [ ] Terraform state bucket created

### ✅ Workshop Materials
- [ ] Workshop configuration file created
- [ ] Validation scripts created and tested
- [ ] Utility scripts available
- [ ] Lab guides accessible
- [ ] Backup and cleanup procedures understood

### ✅ Final Validation
- [ ] Setup validation script passes all checks
- [ ] Workshop environment variables configured
- [ ] Ready to begin Lab 01

## Important Notes

### 🚨 Security Considerations
- **Never commit credentials to version control**
- **Use service accounts for automation**
- **Enable audit logging for all activities**
- **Follow least privilege principle**

### 💡 Best Practices
- **Save work frequently** - Each lab builds on previous ones
- **Document changes** - Keep notes of customizations
- **Test thoroughly** - Run validation scripts after each lab
- **Ask questions** - Don't hesitate to seek help

### 🔧 Troubleshooting
- **Quota issues**: Check project quotas and request increases
- **API issues**: Verify APIs are enabled and accessible
- **Permission issues**: Check IAM roles and permissions
- **Network issues**: Verify firewall rules and connectivity

## Getting Started

1. **Complete this setup guide** - Ensure all steps are completed
2. **Run validation** - Execute `./validate-setup.sh` and ensure all checks pass
3. **Source configuration** - Always run `source workshop-config.env` before starting work
4. **Begin Lab 01** - Navigate to `lab-01` directory and follow the lab guide

## Support and Resources

### Workshop Support
- **Instructor**: Available during workshop hours
- **Documentation**: Comprehensive lab guides and references
- **Validation Scripts**: Automated testing for each lab
- **Troubleshooting**: Common issues and solutions documented

### External Resources
- **GCP Documentation**: https://cloud.google.com/docs
- **Terraform Documentation**: https://www.terraform.io/docs
- **Best Practices**: GCP Well-Architected Framework

---

**Good luck with your GCP Landing Zone Workshop!** 🚀

Remember to:
- ✅ Complete all setup steps before starting
- ✅ Keep your credentials secure
- ✅ Document your progress
- ✅ Have fun learning!

---

*Workshop Setup Guide v1.0*
*Last updated: $(date)*

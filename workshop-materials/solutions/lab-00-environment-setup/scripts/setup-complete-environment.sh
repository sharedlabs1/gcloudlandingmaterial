#!/bin/bash

# Complete GCP Landing Zone Workshop Environment Setup
echo "=== Complete Workshop Environment Setup ==="

# Set workshop configuration
export PROJECT_ID="${PROJECT_ID:-your-project-id}"
export REGION="${REGION:-us-central1}"
export ZONE="${ZONE:-us-central1-a}"
export TF_STATE_BUCKET="${TF_STATE_BUCKET:-tf-state-${PROJECT_ID}-$(date +%s)}"

# Validate required variables
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-project-id" ]; then
    echo "Please set PROJECT_ID environment variable"
    exit 1
fi

echo "Setting up workshop for project: $PROJECT_ID"

# Enable all required APIs
echo "Enabling all required APIs..."
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
    "dlp.googleapis.com"
    "binaryauthorization.googleapis.com"
    "containeranalysis.googleapis.com"
    "certificatemanager.googleapis.com"
)

for api in "${apis[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --project=$PROJECT_ID
done

# Create Terraform state bucket
echo "Creating Terraform state bucket..."
gsutil mb gs://$TF_STATE_BUCKET 2>/dev/null || echo "Bucket already exists"
gsutil versioning set on gs://$TF_STATE_BUCKET

# Set up authentication
echo "Configuring authentication..."
gcloud auth application-default login --no-launch-browser

# Create workshop directory structure
echo "Creating workshop directory structure..."
mkdir -p ~/workshop-materials/{lab-{01..14}/{terraform,scripts,docs,outputs,validation},shared-modules,outputs}

# Create workshop config
cat > ~/workshop-materials/workshop-config.env << CONFIG_END
# GCP Landing Zone Workshop Configuration
export PROJECT_ID="$PROJECT_ID"
export REGION="$REGION"
export ZONE="$ZONE"
export TF_STATE_BUCKET="$TF_STATE_BUCKET"
export WORKSHOP_HOME="$(cd ~/workshop-materials && pwd)"

# TechCorp Configuration
export COMPANY_NAME="TechCorp"
export DOMAIN_NAME="techcorp.internal"
export ENVIRONMENT_PREFIX="tc"

# Workshop Participant Info
export PARTICIPANT_ID="participant-${PROJECT_ID##*-}"
export WORKSHOP_DATE="$(date +%Y-%m-%d)"
CONFIG_END

echo "✅ Workshop environment setup completed!"
echo "Next steps:"
echo "1. cd ~/workshop-materials/solutions"
echo "2. Start with Lab 01: cd lab-01-gcp-organizational-foundation/terraform"
echo "3. Follow the README.md in each lab folder for instructions"

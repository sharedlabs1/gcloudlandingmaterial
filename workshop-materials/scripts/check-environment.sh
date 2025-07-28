#!/bin/bash

# Workshop Environment Check Script
echo "=== GCP Landing Zone Workshop Environment Check ==="
echo "Started at: $(date)"
echo

# Check required environment variables
required_vars=("PROJECT_ID" "REGION" "ZONE" "TF_STATE_BUCKET")
missing_vars=0

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "✗ Missing required environment variable: $var"
        ((missing_vars++))
    else
        echo "✓ $var = ${!var}"
    fi
done

if [ $missing_vars -gt 0 ]; then
    echo
    echo "❌ Missing $missing_vars required environment variables"
    echo "Please source workshop-config.env and try again"
    exit 1
fi

# Check gcloud authentication
echo
echo "Checking gcloud authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "✓ gcloud authenticated as: $(gcloud config get-value account)"
else
    echo "✗ gcloud not authenticated"
    echo "Run: gcloud auth login"
    exit 1
fi

# Check project access
echo "Checking project access..."
if gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo "✓ Project accessible: $PROJECT_ID"
else
    echo "✗ Cannot access project: $PROJECT_ID"
    exit 1
fi

# Check Terraform installation
echo "Checking Terraform installation..."
if command -v terraform &>/dev/null; then
    terraform_version=$(terraform version | head -n1 | cut -d' ' -f2)
    echo "✓ Terraform installed: $terraform_version"
else
    echo "✗ Terraform not installed"
    exit 1
fi

# Check state bucket access
echo "Checking Terraform state bucket..."
if gsutil ls gs://$TF_STATE_BUCKET &>/dev/null; then
    echo "✓ State bucket accessible: gs://$TF_STATE_BUCKET"
else
    echo "✗ Cannot access state bucket: gs://$TF_STATE_BUCKET"
    exit 1
fi

echo
echo "🎉 Environment check passed! Ready to start workshop."

#!/bin/bash

# Master Deployment Script for All Workshop Labs
set -e

echo "=== GCP Landing Zone Workshop - Complete Deployment ==="

# Check prerequisites
if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID environment variable not set"
    echo "Please run: export PROJECT_ID=your-project-id"
    exit 1
fi

if [ -z "$TF_STATE_BUCKET" ]; then
    echo "Error: TF_STATE_BUCKET environment variable not set"
    echo "Please run: export TF_STATE_BUCKET=your-bucket-name"
    exit 1
fi

echo "Deploying to project: $PROJECT_ID"
echo "Using state bucket: $TF_STATE_BUCKET"

# Create terraform.tfvars for each lab
create_tfvars() {
    local lab_dir=$1
    cat > "$lab_dir/terraform/terraform.tfvars" << TFVARS_END
project_id = "$PROJECT_ID"
region     = "us-central1"
tf_state_bucket = "$TF_STATE_BUCKET"
TFVARS_END
}

# Deploy labs in sequence
labs=(
    "lab-01-gcp-organizational-foundation"
    "lab-02-terraform-environment-setup"
    "lab-03-core-networking-architecture"
    "lab-07-cloud-logging-architecture"
    "lab-10-security-controls-&-compliance"
    "lab-15-pam-firewall-configuration"
)

echo "Deploying complete solutions..."
successful_deployments=0
failed_deployments=0

for lab in "${labs[@]}"; do
    echo
    echo "=================================================="
    echo "Deploying $lab"
    echo "=================================================="
    
    if [ -d "$lab" ]; then
        cd "$lab"
        
        # Create terraform.tfvars
        create_tfvars "$(pwd)"
        
        # Deploy
        if ./scripts/deploy.sh; then
            echo "✅ $lab deployed successfully"
            ((successful_deployments++))
            
            # Validate
            if ./scripts/validate.sh; then
                echo "✅ $lab validation passed"
            else
                echo "⚠️ $lab validation failed"
            fi
        else
            echo "❌ $lab deployment failed"
            ((failed_deployments++))
        fi
        
        cd ..
    else
        echo "❌ Directory not found: $lab"
        ((failed_deployments++))
    fi
done

echo
echo "=== Deployment Summary ==="
echo "✅ Successful: $successful_deployments"
echo "❌ Failed: $failed_deployments"
echo "Complete solutions deployed: ${#labs[@]}"

if [ $failed_deployments -eq 0 ]; then
    echo
    echo "🎉 All complete solutions deployed successfully!"
    echo "Template labs (04-06, 08-09, 11-14) require manual implementation."
else
    echo
    echo "⚠️ Some deployments failed. Check logs and retry."
fi

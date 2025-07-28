#!/bin/bash

# Lab 11 Deployment Script
set -e

echo "Deploying Lab 11: Advanced Monitoring & Alerting"

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Check prerequisites
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found. Copy from terraform.tfvars.example and configure."
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo "Validating configuration..."
terraform validate

# Plan deployment
echo "Creating deployment plan..."
terraform plan -out=lab11.tfplan

# Apply with confirmation
read -p "Apply Lab 11 configuration? (y/N): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "Applying configuration..."
    terraform apply lab11.tfplan
    echo "✅ Lab 11 deployment completed successfully!"
else
    echo "Deployment cancelled."
    exit 1
fi

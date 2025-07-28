#!/bin/bash

# Lab 13 Deployment Script
set -e

echo "Deploying Lab 13: Cost Management & Optimization"

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
terraform plan -out=lab13.tfplan

# Apply with confirmation
read -p "Apply Lab 13 configuration? (y/N): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "Applying configuration..."
    terraform apply lab13.tfplan
    echo "✅ Lab 13 deployment completed successfully!"
else
    echo "Deployment cancelled."
    exit 1
fi

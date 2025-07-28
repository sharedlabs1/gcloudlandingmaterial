#!/bin/bash

# Lab 04 Deployment Script
set -e

echo "Deploying Lab 04: Network Security Implementation"

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
terraform plan -out=lab04.tfplan

# Apply with confirmation
read -p "Apply Lab 04 configuration? (y/N): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "Applying configuration..."
    terraform apply lab04.tfplan
    echo "✅ Lab 04 deployment completed successfully!"
else
    echo "Deployment cancelled."
    exit 1
fi

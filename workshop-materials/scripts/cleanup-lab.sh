#!/bin/bash

# Lab Cleanup Script
if [ $# -ne 1 ]; then
    echo "Usage: $0 <lab_number>"
    echo "Example: $0 01"
    exit 1
fi

LAB_NUM=$1
LAB_DIR="~/gcp-landing-zone-workshop/lab-$LAB_NUM"

echo "=== Cleaning up Lab $LAB_NUM ==="
echo "Lab directory: $LAB_DIR"

read -p "Are you sure you want to cleanup Lab $LAB_NUM? This will destroy all resources! (y/N): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

cd $LAB_DIR/terraform 2>/dev/null || {
    echo "Error: Lab directory not found"
    exit 1
}

echo "Destroying Terraform resources..."
terraform destroy -auto-approve

echo "Cleaning up local files..."
rm -f terraform.tfplan
rm -f terraform.tfstate*
rm -rf .terraform/

echo "✓ Lab $LAB_NUM cleanup completed"

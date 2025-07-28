#!/bin/bash

# Lab 08 Validation Script
echo "=== Lab 08 Validation ==="

validation_passed=0
validation_failed=0

check_status() {
    if [ $1 -eq 0 ]; then
        echo "✓ $2"
        ((validation_passed++))
    else
        echo "✗ $2"
        ((validation_failed++))
    fi
}

# Basic project validation
echo "Validating basic setup..."
gcloud projects describe $PROJECT_ID &>/dev/null
check_status $? "Project access verified"

# Check Lab 08 specific resources
echo "Validating Lab 08 resources..."
gsutil ls gs://${PROJECT_ID}-lab-08-resources &>/dev/null
check_status $? "Lab 08 bucket exists"

# Check Terraform outputs
if [ -f "../terraform/terraform.tfstate" ]; then
    cd ../terraform
    terraform output -json > /tmp/lab08_outputs.json
    check_status $? "Terraform outputs accessible"
    cd - > /dev/null
fi

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"

if [ $validation_failed -eq 0 ]; then
    echo "🎉 Lab 08 validation PASSED!"
    exit 0
else
    echo "❌ Lab 08 validation FAILED"
    exit 1
fi

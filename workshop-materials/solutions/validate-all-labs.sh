#!/bin/bash

# Master Validation Script for All Workshop Labs
echo "=== GCP Landing Zone Workshop - Complete Validation ==="

total_labs=0
passed_labs=0
failed_labs=0

# Complete solutions to validate
complete_labs=(
    "lab-01-gcp-organizational-foundation"
    "lab-02-terraform-environment-setup"
    "lab-03-core-networking-architecture"
    "lab-07-cloud-logging-architecture"
    "lab-10-security-controls-&-compliance"
    "lab-15-pam-firewall-configuration"
)

echo "Validating complete solutions..."

for lab in "${complete_labs[@]}"; do
    echo
    echo "Validating $lab..."
    ((total_labs++))
    
    if [ -d "$lab" ] && [ -f "$lab/scripts/validate.sh" ]; then
        cd "$lab"
        if ./scripts/validate.sh > /dev/null 2>&1; then
            echo "✅ $lab validation passed"
            ((passed_labs++))
        else
            echo "❌ $lab validation failed"
            ((failed_labs++))
        fi
        cd ..
    else
        echo "⚠️ $lab validation script not found"
        ((failed_labs++))
    fi
done

echo
echo "=== Validation Summary ==="
echo "✅ Passed: $passed_labs"
echo "❌ Failed: $failed_labs"
echo "Total complete solutions: $total_labs"

completion_rate=$((passed_labs * 100 / total_labs))
echo "Completion Rate: ${completion_rate}%"

echo
echo "📋 Template Solutions Available:"
echo "- Lab 04: Network Security Implementation"
echo "- Lab 05: Identity and Access Management"
echo "- Lab 06: Cloud Monitoring Foundation"
echo "- Lab 08: Shared Services Implementation"
echo "- Lab 09: Workload Environment Setup"
echo "- Lab 11: Advanced Monitoring & Alerting"
echo "- Lab 12: Disaster Recovery & Backup"
echo "- Lab 13: Cost Management & Optimization"
echo "- Lab 14: Final Validation & Optimization"

if [ $failed_labs -eq 0 ]; then
    echo
    echo "🎉 All complete solution validations passed!"
    echo "Template solutions ready for implementation!"
else
    echo
    echo "⚠️ Some validations failed. Review and fix issues."
fi

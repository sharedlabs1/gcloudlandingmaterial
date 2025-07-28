# Lab 11: Advanced Monitoring & Alerting

## Lab Overview

**Duration**: 60 minutes 
**Difficulty**: Advanced  
**Prerequisites**: Successful completion of previous labs

### Lab Description
Configure comprehensive monitoring with SLIs, SLOs, error budgets, advanced alerting, and automated incident response for TechCorp's production systems.

### Business Context
As part of TechCorp's cloud transformation initiative, this lab focuses on building enterprise-grade infrastructure that meets fintech compliance requirements while enabling rapid development and deployment capabilities.

## Learning Objectives

After completing this lab, you will be able to:

• Implement SRE practices with SLIs, SLOs, and error budgets
• Configure advanced alerting with anomaly detection
• Set up automated incident response and escalation
• Implement performance analytics and capacity planning
• Configure business metrics monitoring and reporting

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

**Site Reliability Engineering**: SLI/SLO methodology, error budgets, and reliability engineering practices.

**Advanced Alerting**: Multi-signal alerting, anomaly detection, and intelligent noise reduction.

**Incident Response**: Automated incident detection, escalation, and response workflows.

**Performance Analytics**: Advanced performance monitoring, capacity planning, and optimization.

### Architecture Diagram
```
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab 11 Components
```

## Pre-Lab Setup

### Environment Verification
```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-11

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Lab: 11"
echo "Current directory: $(pwd)"

# Check prerequisites from previous labs
if [ "11" != "01" ]; then
    echo "Checking previous lab outputs..."
    ls -la ../lab-10/outputs/
fi
```

### Required Variables
```bash
# Set lab-specific variables
export LAB_PREFIX="lab11"
export TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export LAB_USER=$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}
```

## Lab Implementation

### Implementation Steps

```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-11/terraform

# Create main configuration for this lab
cat > main.tf << 'MAIN_END'
# Lab 11: Advanced Monitoring & Alerting
# Implementation details will be provided in the complete workshop

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Get previous lab outputs
data "terraform_remote_state" "previous_labs" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-10/terraform/state"
  }
}

# Lab-specific resources will be added here
MAIN_END

echo "✓ Lab 11 configuration initialized"
```

**Note**: Complete implementation details for this lab will be provided during the workshop session.

## Expected Deliverables

Upon successful completion of this lab, you should have:

• Successfully configured resources for Advanced Monitoring & Alerting
• Validation scripts passing all checks
• Comprehensive documentation completed
• Integration with previous lab components verified

## Validation and Testing

### Automated Validation
```bash
# Create comprehensive validation script
cat > validation/validate-lab-11.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab 11 Validation Script ==="
echo "Started at: $(date)"
echo "Project: $PROJECT_ID"
echo

# Source workshop configuration
source ../../workshop-config.env

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

# Lab 11 validation placeholder
echo "Validating Lab 11: Advanced Monitoring & Alerting"
echo "✓ Basic validation passed"
((validation_passed++))

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"
echo "Total checks: $((validation_passed + validation_failed))"

if [ $validation_failed -eq 0 ]; then
    echo
    echo "🎉 Lab 11 validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-11-validation.json << VALIDATION_JSON_END
{
  "lab": "11",
  "status": "PASSED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID"
}
VALIDATION_JSON_END
    
    exit 0
else
    echo
    echo "❌ Lab 11 validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-11-validation.json << VALIDATION_JSON_END
{
  "lab": "11",
  "status": "FAILED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID"
}
VALIDATION_JSON_END
    
    exit 1
fi
VALIDATION_SCRIPT_END

chmod +x validation/validate-lab-11.sh

# Run validation
echo "Running Lab 11 validation..."
cd validation
./validate-lab-11.sh
cd ..
```

### Manual Verification Steps
1. **Visual Inspection**: Check GCP Console for created resources
2. **Functional Testing**: Verify resource functionality and connectivity
3. **Security Review**: Confirm security controls are properly configured
4. **Documentation**: Ensure all configurations are documented

## Troubleshooting

### Common Issues and Solutions

Common troubleshooting steps and solutions for Advanced Monitoring & Alerting will be provided during the workshop.

### Getting Help
- **Immediate Support**: Raise hand for instructor assistance
- **Documentation**: Reference GCP documentation and Terraform provider docs
- **Community**: Check Stack Overflow and GCP Community forums
- **Logs**: Review Terraform logs and GCP audit logs for error details

## Lab Completion Checklist

### Technical Deliverables
- [ ] All Terraform resources deployed successfully
- [ ] Validation script passes all checks
- [ ] Resources are properly tagged and labeled
- [ ] Security best practices implemented
- [ ] Monitoring and logging configured (where applicable)
- [ ] Documentation updated

### Knowledge Transfer
- [ ] Understand the purpose of each component created
- [ ] Can explain the architecture to others
- [ ] Know how to troubleshoot common issues
- [ ] Familiar with relevant GCP services and features

### File Organization
- [ ] Terraform configurations saved in terraform/ directory
- [ ] Scripts saved in scripts/ directory
- [ ] Documentation saved in docs/ directory
- [ ] Outputs saved in outputs/ directory
- [ ] Validation results saved and accessible

## Output Artifacts

```bash
# Save all lab outputs for future reference
mkdir -p outputs

# Terraform outputs
if [ -f terraform/terraform.tfstate ]; then
    terraform -chdir=terraform output -json > outputs/terraform-outputs.json
    echo "✓ Terraform outputs saved"
fi

# Resource inventories
gcloud compute instances list --format=json > outputs/compute-instances.json 2>/dev/null || echo "No compute instances"
gcloud iam service-accounts list --format=json > outputs/service-accounts.json 2>/dev/null || echo "No service accounts"
gcloud compute networks list --format=json > outputs/networks.json 2>/dev/null || echo "No networks"
gcloud compute firewall-rules list --format=json > outputs/firewall-rules.json 2>/dev/null || echo "No firewall rules"

# Configuration backups
cp -r terraform/ outputs/ 2>/dev/null || echo "No terraform directory to backup"
cp -r scripts/ outputs/ 2>/dev/null || echo "No scripts directory to backup"

# Create lab summary
cat > outputs/lab-11-summary.md << 'LAB_SUMMARY_END'
# Lab 11 Summary

## Completed: $(date)
## Project: $PROJECT_ID
## Participant: $LAB_USER

### Resources Created
- [List of resources created in this lab]

### Key Learnings
- [Key technical concepts learned]

### Next Steps
- Proceed to Lab 12
- Review outputs for integration with subsequent labs

### Files Generated
$(ls -la outputs/)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
```

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

```bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab 11:"
    cat outputs/terraform-outputs.json | jq -r 'to_entries[] | "\(.key): \(.value.value)"'
fi
```

### Dependencies for Future Labs
- **Lab 12**: Will use [specific outputs] from this lab
- **Integration Points**: [How this lab integrates with overall architecture]

## Next Steps

### Next Steps
- Complete validation of all lab components
- Review outputs for integration with subsequent labs
- Proceed to Lab 12 after validation passes

### Key Takeaways
- Advanced GCP service configurations
- Enterprise security and compliance implementations
- Operational excellence practices

### Preparation for Next Lab
1. **Ensure all validation passes**: Fix any failed checks before proceeding
2. **Review outputs**: Understand what was created and why
3. **Take a break**: Complex labs require mental breaks between sessions
4. **Ask questions**: Clarify any concepts before moving forward

---

## Additional Resources

### Documentation References
- **GCP Documentation**: [Relevant GCP service documentation]
- **Terraform Provider**: [Relevant Terraform provider documentation]
- **Best Practices**: [Links to architectural best practices]

### Code Samples
- **GitHub Repository**: [Workshop repository with complete solutions]
- **Reference Architectures**: [GCP reference architecture examples]

---

**Lab 11 Complete** ✅

**Estimated Time for Completion**: 60 minutes
**Next Lab**: Lab 12 - [Next lab title]

*Remember to save all outputs and configurations before proceeding to the next lab!*


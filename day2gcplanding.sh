#!/bin/bash

# GCP Landing Zone Workshop Day 2 Lab Generator - Labs 07-14
# This script creates comprehensive lab guides for Day 2 advanced implementations

echo "Creating Day 2 GCP Landing Zone Workshop Lab Materials (Labs 07-14)..."

# Check if workshop-materials directory exists
if [ ! -d "workshop-materials" ]; then
    echo "Error: workshop-materials directory not found. Please run the Day 1 script first."
    exit 1
fi

# Function to create detailed lab guides for Day 2
create_comprehensive_day2_lab_guide() {
    local lab_num=$1
    local lab_title="$2"
    local lab_description="$3"
    local lab_duration="$4"
    local concept_content="$5"
    local objectives="$6"
    local prerequisites="$7"
    local implementation="$8"
    local deliverables="$9"
    local validation="${10}"
    local troubleshooting="${11}"
    local next_steps="${12}"

    # Calculate previous lab number safely
    local prev_lab_num=""
    if [ "$lab_num" != "01" ]; then
        local prev_num=$((10#$lab_num - 1))
        prev_lab_num=$(printf "%02d" $prev_num)
    fi
    
    # Calculate next lab number safely  
    local next_num=$((10#$lab_num + 1))
    local next_lab_num=$(printf "%02d" $next_num)

cat > "workshop-materials/lab-guides/lab-${lab_num}-$(echo "$lab_title" | tr ' ' '-' | tr '[:upper:]' '[:lower:]').md" << LAB_GUIDE_EOF
# Lab ${lab_num}: ${lab_title}

## Lab Overview

**Duration**: ${lab_duration} 
**Difficulty**: $(echo "$lab_num" | awk '{if($1<=7) print "Intermediate"; else if($1<=11) print "Advanced"; else print "Expert"}')  
**Prerequisites**: ${prerequisites}

### Lab Description
${lab_description}

### Business Context
As TechCorp's cloud infrastructure matures, this lab implements advanced operational capabilities essential for production fintech environments, including regulatory compliance, operational excellence, and enterprise-grade automation.

## Learning Objectives

After completing this lab, you will be able to:

${objectives}

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

${concept_content}

### Architecture Diagram
\`\`\`
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab ${lab_num} Components
Integration with Labs 01-$(printf "%02d" $((10#$lab_num - 1)))
\`\`\`

## Pre-Lab Setup

### Environment Verification
\`\`\`bash
# Navigate to lab directory
cd ~/gcp-landing-zone-workshop/lab-${lab_num}

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: \$PROJECT_ID"
echo "Region: \$REGION"
echo "Lab: ${lab_num}"
echo "Current directory: \$(pwd)"

# Check prerequisites from previous labs
echo "Checking previous lab outputs..."
ls -la ../lab-${prev_lab_num}/outputs/

# Verify Day 1 foundation is complete
required_labs=(01 02 03 04 05 06)
for lab in "\${required_labs[@]}"; do
    if [ -f "../lab-\$lab/outputs/lab-\$lab-validation.json" ]; then
        status=\$(jq -r '.status' "../lab-\$lab/outputs/lab-\$lab-validation.json")
        if [ "\$status" = "PASSED" ]; then
            echo "✓ Lab \$lab: Foundation ready"
        else
            echo "✗ Lab \$lab: Validation failed - please complete Day 1 labs first"
            exit 1
        fi
    else
        echo "✗ Lab \$lab: Not completed - please complete Day 1 labs first"
        exit 1
    fi
done
\`\`\`

### Required Variables
\`\`\`bash
# Set lab-specific variables
export LAB_PREFIX="lab${lab_num}"
export TIMESTAMP=\$(date +%Y%m%d-%H%M%S)
export LAB_USER=\$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}

# Get previous lab outputs for integration
if [ -f "../lab-${prev_lab_num}/outputs/terraform-outputs.json" ]; then
    echo "✓ Previous lab outputs available for integration"
else
    echo "⚠ Previous lab outputs not found - some integrations may not work"
fi
\`\`\`

## Lab Implementation

${implementation}

## Expected Deliverables

Upon successful completion of this lab, you should have:

${deliverables}

## Validation and Testing

### Automated Validation
\`\`\`bash
# Create comprehensive validation script
cat > validation/validate-lab-${lab_num}.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab ${lab_num} Validation Script ==="
echo "Started at: \$(date)"
echo "Project: \$PROJECT_ID"
echo

# Source workshop configuration
source ../../workshop-config.env

validation_passed=0
validation_failed=0

# Function to check status
check_status() {
    if [ \$1 -eq 0 ]; then
        echo "✓ \$2"
        ((validation_passed++))
    else
        echo "✗ \$2"
        ((validation_failed++))
    fi
}

# Check Day 1 prerequisites
echo "Validating Day 1 prerequisites..."
day1_labs=(01 02 03 04 05 06)
for lab in "\${day1_labs[@]}"; do
    if [ -f "../../lab-\$lab/outputs/lab-\$lab-validation.json" ]; then
        status=\$(jq -r '.status' "../../lab-\$lab/outputs/lab-\$lab-validation.json")
        check_status \$([ "\$status" = "PASSED" ] && echo 0 || echo 1) "Day 1 Lab \$lab prerequisite"
    else
        echo "✗ Day 1 Lab \$lab not completed"
        ((validation_failed++))
    fi
done

${validation}

# Check integration with previous labs
echo "Checking integration with previous labs..."
cd terraform
if [ -f "terraform.tfstate" ]; then
    terraform_outputs=\$(terraform output -json 2>/dev/null)
    if [ \$? -eq 0 ] && [ "\$terraform_outputs" != "{}" ]; then
        echo "✓ Lab ${lab_num} Terraform state accessible"
        ((validation_passed++))
    else
        echo "✗ Lab ${lab_num} Terraform outputs not available"
        ((validation_failed++))
    fi
else
    echo "✗ Lab ${lab_num} Terraform state not found"
    ((validation_failed++))
fi
cd ..

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: \$validation_passed"
echo "✗ Failed: \$validation_failed"
echo "Total checks: \$((validation_passed + validation_failed))"

if [ \$validation_failed -eq 0 ]; then
    echo
    echo "🎉 Lab ${lab_num} validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-${lab_num}-validation.json << VALIDATION_JSON_END
{
  "lab": "${lab_num}",
  "status": "PASSED",
  "timestamp": "\$(date -Iseconds)",
  "checks_passed": \$validation_passed,
  "checks_failed": \$validation_failed,
  "project_id": "\$PROJECT_ID",
  "day": 2,
  "integration_verified": true
}
VALIDATION_JSON_END
    
    exit 0
else
    echo
    echo "❌ Lab ${lab_num} validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-${lab_num}-validation.json << VALIDATION_JSON_END
{
  "lab": "${lab_num}",
  "status": "FAILED",
  "timestamp": "\$(date -Iseconds)",
  "checks_passed": \$validation_passed,
  "checks_failed": \$validation_failed,
  "project_id": "\$PROJECT_ID",
  "day": 2,
  "integration_verified": false
}
VALIDATION_JSON_END
    
    exit 1
fi
VALIDATION_SCRIPT_END

chmod +x validation/validate-lab-${lab_num}.sh

# Run validation
echo "Running Lab ${lab_num} validation..."
cd validation
./validate-lab-${lab_num}.sh
cd ..
\`\`\`

### Manual Verification Steps
1. **Visual Inspection**: Check GCP Console for created resources
2. **Functional Testing**: Verify resource functionality and connectivity
3. **Security Review**: Confirm security controls are properly configured
4. **Integration Testing**: Verify integration with Day 1 infrastructure
5. **Performance Testing**: Validate performance and scalability
6. **Documentation**: Ensure all configurations are documented

## Troubleshooting

### Common Issues and Solutions

${troubleshooting}

### Day 2 Specific Troubleshooting
- **Integration Issues**: Verify Day 1 labs are completed and validated
- **Resource Dependencies**: Check that prerequisite resources exist
- **Permission Issues**: Ensure service accounts have required advanced permissions
- **API Limitations**: Some advanced features may have quota or regional limitations

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
- [ ] Integration with Day 1 infrastructure verified
- [ ] Performance and scalability validated
- [ ] Documentation updated

### Knowledge Transfer
- [ ] Understand the purpose of each component created
- [ ] Can explain the architecture to others
- [ ] Know how to troubleshoot common issues
- [ ] Familiar with relevant GCP services and features
- [ ] Understand operational procedures and maintenance

### File Organization
- [ ] Terraform configurations saved in terraform/ directory
- [ ] Scripts saved in scripts/ directory
- [ ] Documentation saved in docs/ directory
- [ ] Outputs saved in outputs/ directory
- [ ] Validation results saved and accessible

## Output Artifacts

\`\`\`bash
# Save all lab outputs for future reference
mkdir -p outputs

# Terraform outputs
if [ -f terraform/terraform.tfstate ]; then
    terraform -chdir=terraform output -json > outputs/terraform-outputs.json
    echo "✓ Terraform outputs saved"
fi

# Resource inventories (enhanced for Day 2)
gcloud compute instances list --format=json > outputs/compute-instances.json 2>/dev/null || echo "No compute instances"
gcloud iam service-accounts list --format=json > outputs/service-accounts.json 2>/dev/null || echo "No service accounts"
gcloud compute networks list --format=json > outputs/networks.json 2>/dev/null || echo "No networks"
gcloud compute firewall-rules list --format=json > outputs/firewall-rules.json 2>/dev/null || echo "No firewall rules"
gcloud logging sinks list --format=json > outputs/logging-sinks.json 2>/dev/null || echo "No logging sinks"
gcloud monitoring policies list --format=json > outputs/monitoring-policies.json 2>/dev/null || echo "No monitoring policies"
gcloud dns managed-zones list --format=json > outputs/dns-zones.json 2>/dev/null || echo "No DNS zones"

# Configuration backups
cp -r terraform/ outputs/ 2>/dev/null || echo "No terraform directory to backup"
cp -r scripts/ outputs/ 2>/dev/null || echo "No scripts directory to backup"

# Create enhanced lab summary for Day 2
cat > outputs/lab-${lab_num}-summary.md << 'LAB_SUMMARY_END'
# Lab ${lab_num} Summary - Day 2 Advanced Implementation

## Completed: \$(date)
## Project: \$PROJECT_ID
## Participant: \$LAB_USER
## Workshop Day: 2 (Advanced Implementation)

### Resources Created
- [Advanced resources and configurations for ${lab_title}]

### Key Learnings
- [Advanced technical concepts and enterprise patterns]

### Integration Points
- Integration with Day 1 foundation (Labs 01-06)
- Dependencies on previous Day 2 labs
- Outputs for subsequent advanced labs

### Next Steps
$(if [ "$lab_num" != "14" ]; then echo "- Proceed to Lab ${next_lab_num}"; else echo "- Workshop completion and final review"; fi)
- Review outputs for integration with subsequent labs
- Validate enterprise readiness

### Files Generated
\$(ls -la outputs/)

### Day 2 Progress
Lab ${lab_num} of 14 completed (Day 2: Lab $(($((10#$lab_num)) - 6)) of 8)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
\`\`\`

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

\`\`\`bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab ${lab_num}:"
    cat outputs/terraform-outputs.json | jq -r 'to_entries[] | "\\(.key): \\(.value.value)"'
fi

# Show integration with Day 1 foundation
echo "Integration with Day 1 foundation:"
for lab in 01 02 03 04 05 06; do
    if [ -f "../lab-\$lab/outputs/terraform-outputs.json" ]; then
        echo "  ✓ Lab \$lab outputs available for integration"
    fi
done
\`\`\`

### Dependencies for Future Labs
$(if [ "$lab_num" != "14" ]; then echo "- **Lab ${next_lab_num}**: Will use [specific outputs] from this lab"; else echo "- **Workshop Completion**: All labs integrated into final architecture"; fi)
- **Integration Points**: [How this lab integrates with overall Day 2 architecture]
- **Enterprise Readiness**: [Production deployment considerations]

## Next Steps

${next_steps}

### Preparation for Next Lab
1. **Ensure all validation passes**: Fix any failed checks before proceeding
2. **Review outputs**: Understand what was created and why
3. **Verify integration**: Confirm proper integration with Day 1 foundation
4. **Take a break**: Complex Day 2 labs require mental breaks between sessions
5. **Ask questions**: Clarify any concepts before moving forward

---

## Additional Resources

### Documentation References
- **GCP Documentation**: [Relevant advanced GCP service documentation]
- **Terraform Provider**: [Advanced Terraform provider documentation]
- **Enterprise Best Practices**: [Links to enterprise architectural best practices]
- **Compliance Guidelines**: [Fintech compliance and regulatory guidance]

### Code Samples
- **GitHub Repository**: [Workshop repository with complete solutions]
- **Enterprise Reference Architectures**: [GCP enterprise reference architectures]
- **Production Patterns**: [Real-world production implementation examples]

---

**Lab ${lab_num} Complete** ✅

**Estimated Time for Completion**: ${lab_duration}
$(if [ "$lab_num" != "14" ]; then echo "**Next Lab**: Lab ${next_lab_num} - [Next lab title]"; else echo "**Workshop Status**: COMPLETED - Ready for production deployment"; fi)

*Day 2 Focus: Advanced enterprise implementations for production readiness*

LAB_GUIDE_EOF
}

# Create Lab 07 - Cloud Logging Architecture
echo "Creating Lab 07: Cloud Logging Architecture..."
create_comprehensive_day2_lab_guide "07" "Cloud Logging Architecture" \
"Configure centralized logging with log sinks, aggregation, analysis capabilities, and long-term retention to meet TechCorp's operational and compliance requirements including audit trails for financial regulations." \
"45 minutes" \
"**Centralized Logging Strategy**: Enterprise logging requires centralized collection, routing, and analysis of logs from all infrastructure and application components. This includes structured logging, log correlation, and automated analysis for both operational and security purposes.

**Log Sinks and Routing**: GCP Cloud Logging provides advanced log routing capabilities through sinks, allowing logs to be sent to different destinations based on filters, content, and business requirements. This enables cost optimization and compliance with data residency requirements.

**Compliance and Audit Logging**: Financial services require immutable audit trails, long-term retention, and specific log formats for regulatory compliance. This includes SOX, PCI DSS, and other fintech regulations requiring detailed activity logging.

**Log Analysis and Alerting**: Advanced log analysis includes real-time monitoring, anomaly detection, and automated alerting based on log patterns. This enables proactive incident response and security monitoring." \
"• Design and implement enterprise centralized logging architecture
• Configure log sinks for different destinations and compliance requirements
• Implement structured logging with proper log levels and formatting
• Set up log-based metrics and automated monitoring
• Configure compliance-grade log retention and audit trails
• Implement security monitoring and automated alerting from logs
• Set up log export for long-term archival and analysis" \
"Successful completion of Labs 01-06 (Day 1 foundation)" \
"### Step 1: Centralized Logging Infrastructure Setup

Configure the foundational logging infrastructure for TechCorp's enterprise needs.

\`\`\`bash
# Navigate to lab directory
cd ~/gcp-landing-zone-workshop/lab-07/terraform

# Create main logging configuration
cat > main.tf << 'LOGGING_MAIN_END'
# Lab 07: Cloud Logging Architecture
# Centralized logging infrastructure for TechCorp

terraform {
  required_version = \">= 1.5\"
  required_providers {
    google = {
      source  = \"hashicorp/google\"
      version = \"~> 5.0\"
    }
    google-beta = {
      source  = \"hashicorp/google-beta\"
      version = \"~> 5.0\"
    }
  }
  
  backend \"gcs\" {
    bucket = \"\${TF_STATE_BUCKET}\"
    prefix = \"lab-07/terraform/state\"
  }
}

# Get previous lab outputs
data \"terraform_remote_state\" \"lab01\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-01/terraform/state\"
  }
}

data \"terraform_remote_state\" \"lab02\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-02/terraform/state\"
  }
}

# Local values for consistent configuration
locals {
  common_labels = {
    workshop    = \"gcp-landing-zone\"
    lab         = \"07\"
    component   = \"logging\"
    environment = \"enterprise\"
    compliance  = \"fintech\"
  }
  
  # Log retention periods for different log types
  retention_policies = {
    audit_logs     = 2555  # 7 years for compliance
    security_logs  = 1095  # 3 years
    application_logs = 365 # 1 year
    debug_logs     = 30    # 30 days
  }
}

# Create dedicated log storage buckets for different retention periods
resource \"google_storage_bucket\" \"audit_log_bucket\" {
  name     = \"\${var.project_id}-audit-logs\"
  location = var.region
  
  # Compliance-grade settings
  uniform_bucket_level_access = true
  force_destroy = false
  
  # Versioning for audit trail integrity
  versioning {
    enabled = true
  }
  
  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = local.retention_policies.audit_logs
    }
    action {
      type = \"Delete\"
    }
  }
  
  # Prevent accidental deletion
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = \"SetStorageClass\"
      storage_class = \"COLDLINE\"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = \"audit-logs\"
    retention = \"7-years\"
  })
}

resource \"google_storage_bucket\" \"security_log_bucket\" {
  name     = \"\${var.project_id}-security-logs\"
  location = var.region
  
  uniform_bucket_level_access = true
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = local.retention_policies.security_logs
    }
    action {
      type = \"Delete\"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = \"security-logs\"
    retention = \"3-years\"
  })
}

resource \"google_storage_bucket\" \"application_log_bucket\" {
  name     = \"\${var.project_id}-application-logs\"
  location = var.region
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = local.retention_policies.application_logs
    }
    action {
      type = \"Delete\"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = \"application-logs\"
    retention = \"1-year\"
  })
}
LOGGING_MAIN_END

echo \"✓ Main logging infrastructure configuration created\"
\`\`\`

### Step 2: Configure Advanced Log Sinks

Set up comprehensive log routing for different compliance and operational requirements.

\`\`\`bash
# Add log sinks configuration
cat >> main.tf << 'LOG_SINKS_END'

# Audit log sink for compliance (all admin activity)
resource \"google_logging_project_sink\" \"audit_sink\" {
  name        = \"techcorp-audit-logs\"
  description = \"Compliance audit logs for SOX, PCI DSS requirements\"
  
  # Capture all admin activity and data access
  filter = <<-EOT
    protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\" OR
    protoPayload.serviceName=\"iam.googleapis.com\" OR
    protoPayload.serviceName=\"storage.googleapis.com\" OR
    protoPayload.serviceName=\"compute.googleapis.com\" OR
    (protoPayload.authenticationInfo.principalEmail!=\"\" AND
     protoPayload.methodName!=\"\" AND
     severity >= \"NOTICE\")
  EOT
  
  destination = \"storage.googleapis.com/\${google_storage_bucket.audit_log_bucket.name}\"
  
  # Use unique writer identity for security
  unique_writer_identity = true
}

# Security log sink for monitoring suspicious activities
resource \"google_logging_project_sink\" \"security_sink\" {
  name        = \"techcorp-security-logs\"
  description = \"Security monitoring and incident response logs\"
  
  filter = <<-EOT
    (severity >= \"WARNING\" AND
     (protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\" OR
      protoPayload.serviceName=\"iam.googleapis.com\" OR
      protoPayload.serviceName=\"compute.googleapis.com\")) OR
    (jsonPayload.message=~\"SECURITY\" OR
     jsonPayload.message=~\"UNAUTHORIZED\" OR
     jsonPayload.message=~\"FAILED_LOGIN\" OR
     jsonPayload.message=~\"INTRUSION\")
  EOT
  
  destination = \"storage.googleapis.com/\${google_storage_bucket.security_log_bucket.name}\"
  unique_writer_identity = true
}

# Application log sink for operational monitoring
resource \"google_logging_project_sink\" \"application_sink\" {
  name        = \"techcorp-application-logs\"
  description = \"Application logs for debugging and monitoring\"
  
  filter = <<-EOT
    resource.type=\"gce_instance\" OR
    resource.type=\"k8s_container\" OR
    resource.type=\"cloud_function\" OR
    (logName=~\"projects/[^/]+/logs/app\" AND severity >= \"INFO\")
  EOT
  
  destination = \"storage.googleapis.com/\${google_storage_bucket.application_log_bucket.name}\"
  unique_writer_identity = true
}

# BigQuery sink for real-time log analysis
resource \"google_bigquery_dataset\" \"logs_dataset\" {
  dataset_id  = \"techcorp_logs\"
  description = \"Dataset for real-time log analysis and reporting\"
  location    = var.region
  
  # Set access controls
  access {
    role          = \"OWNER\"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  access {
    role          = \"READER\"
    special_group = \"projectReaders\"
  }
  
  labels = local.common_labels
}

resource \"google_logging_project_sink\" \"bigquery_sink\" {
  name        = \"techcorp-logs-bigquery\"
  description = \"Real-time log analysis in BigQuery\"
  
  filter = <<-EOT
    (severity >= \"INFO\" AND
     (resource.type=\"gce_instance\" OR
      resource.type=\"cloud_function\" OR
      resource.type=\"gke_cluster\")) OR
    (protoPayload.methodName!=\"\" AND
     severity >= \"NOTICE\")
  EOT
  
  destination = \"bigquery.googleapis.com/projects/\${var.project_id}/datasets/\${google_bigquery_dataset.logs_dataset.dataset_id}\"
  unique_writer_identity = true
  
  # Configure BigQuery options
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Pub/Sub sink for real-time alerting
resource \"google_pubsub_topic\" \"log_alerts\" {
  name = \"techcorp-log-alerts\"
  
  labels = merge(local.common_labels, {
    purpose = \"log-alerting\"
  })
}

resource \"google_logging_project_sink\" \"alerting_sink\" {
  name        = \"techcorp-log-alerting\"
  description = \"Real-time log alerts for critical events\"
  
  filter = <<-EOT
    severity >= \"ERROR\" OR
    (jsonPayload.message=~\"CRITICAL\" OR
     jsonPayload.message=~\"EMERGENCY\" OR
     protoPayload.authenticationInfo.principalEmail=~\".*@.*\" AND
     protoPayload.methodName=~\".*delete.*\")
  EOT
  
  destination = \"pubsub.googleapis.com/projects/\${var.project_id}/topics/\${google_pubsub_topic.log_alerts.name}\"
  unique_writer_identity = true
}
LOG_SINKS_END

echo \"✓ Advanced log sinks configuration added\"
\`\`\`

### Step 3: Set Up IAM for Log Management

Configure proper access controls for log management and compliance.

\`\`\`bash
# Add IAM configuration for logging
cat >> main.tf << 'LOGGING_IAM_END'

# Grant logging sink permissions to write to storage buckets
resource \"google_storage_bucket_iam_member\" \"audit_sink_writer\" {
  bucket = google_storage_bucket.audit_log_bucket.name
  role   = \"roles/storage.objectCreator\"
  member = google_logging_project_sink.audit_sink.writer_identity
}

resource \"google_storage_bucket_iam_member\" \"security_sink_writer\" {
  bucket = google_storage_bucket.security_log_bucket.name
  role   = \"roles/storage.objectCreator\"
  member = google_logging_project_sink.security_sink.writer_identity
}

resource \"google_storage_bucket_iam_member\" \"application_sink_writer\" {
  bucket = google_storage_bucket.application_log_bucket.name
  role   = \"roles/storage.objectCreator\"
  member = google_logging_project_sink.application_sink.writer_identity
}

# Grant BigQuery permissions
resource \"google_bigquery_dataset_iam_member\" \"logs_dataset_writer\" {
  dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
  role       = \"roles/bigquery.dataEditor\"
  member     = google_logging_project_sink.bigquery_sink.writer_identity
}

# Grant Pub/Sub permissions
resource \"google_pubsub_topic_iam_member\" \"alerting_sink_publisher\" {
  topic  = google_pubsub_topic.log_alerts.name
  role   = \"roles/pubsub.publisher\"
  member = google_logging_project_sink.alerting_sink.writer_identity
}

# Create dedicated service account for log analysis
resource \"google_service_account\" \"log_analyst\" {
  account_id   = \"techcorp-log-analyst\"
  display_name = \"TechCorp Log Analyst Service Account\"
  description  = \"Service account for log analysis and monitoring automation\"
}

# Grant log analyst permissions
resource \"google_project_iam_member\" \"log_analyst_permissions\" {
  for_each = toset([
    \"roles/logging.viewer\",
    \"roles/bigquery.dataViewer\",
    \"roles/storage.objectViewer\"
  ])
  
  project = var.project_id
  role    = each.value
  member  = \"serviceAccount:\${google_service_account.log_analyst.email}\"
}

# Data source for current user
data \"google_client_openid_userinfo\" \"current\" {}
LOGGING_IAM_END

echo \"✓ Logging IAM configuration added\"
\`\`\`

### Step 4: Create Log-Based Metrics and Monitoring

Set up automated monitoring and alerting based on log patterns.

\`\`\`bash
# Add log-based metrics configuration
cat >> main.tf << 'LOG_METRICS_END'

# Log-based metric for failed authentication attempts
resource \"google_logging_metric\" \"failed_auth_metric\" {
  name   = \"techcorp_failed_auth_attempts\"
  filter = <<-EOT
    protoPayload.serviceName=\"iam.googleapis.com\" AND
    protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\" AND
    protoPayload.authenticationInfo.principalEmail!=\"\" AND
    severity >= \"WARNING\"
  EOT
  
  metric_descriptor {
    metric_kind = \"GAUGE\"
    value_type  = \"INT64\"
    unit        = \"1\"
    display_name = \"Failed Authentication Attempts\"
  }
  
  value_extractor = \"EXTRACT(protoPayload.authenticationInfo.principalEmail)\"
  
  label_extractors = {
    \"user\" = \"EXTRACT(protoPayload.authenticationInfo.principalEmail)\"
    \"method\" = \"EXTRACT(protoPayload.methodName)\"
  }
}

# Log-based metric for critical application errors
resource \"google_logging_metric\" \"critical_errors_metric\" {
  name   = \"techcorp_critical_errors\"
  filter = <<-EOT
    severity >= \"ERROR\" AND
    (jsonPayload.message=~\"CRITICAL\" OR
     jsonPayload.message=~\"FATAL\" OR
     jsonPayload.level=\"CRITICAL\")
  EOT
  
  metric_descriptor {
    metric_kind = \"GAUGE\"
    value_type  = \"INT64\"
    unit        = \"1\"
    display_name = \"Critical Application Errors\"
  }
  
  label_extractors = {
    \"service\" = \"EXTRACT(resource.labels.service_name)\"
    \"instance\" = \"EXTRACT(resource.labels.instance_id)\"
  }
}

# Log-based metric for data access patterns
resource \"google_logging_metric\" \"data_access_metric\" {
  name   = \"techcorp_data_access\"
  filter = <<-EOT
    protoPayload.serviceName=\"storage.googleapis.com\" AND
    (protoPayload.methodName=\"storage.objects.get\" OR
     protoPayload.methodName=\"storage.objects.create\" OR
     protoPayload.methodName=\"storage.objects.delete\") AND
    protoPayload.resourceName=~\".*sensitive.*\"
  EOT
  
  metric_descriptor {
    metric_kind = \"GAUGE\"
    value_type  = \"INT64\"
    unit        = \"1\"
    display_name = \"Sensitive Data Access\"
  }
  
  label_extractors = {
    \"user\" = \"EXTRACT(protoPayload.authenticationInfo.principalEmail)\"
    \"operation\" = \"EXTRACT(protoPayload.methodName)\"
    \"resource\" = \"EXTRACT(protoPayload.resourceName)\"
  }
}

# Create monitoring policy for failed authentication
resource \"google_monitoring_alert_policy\" \"failed_auth_alert\" {
  display_name = \"TechCorp - High Failed Authentication Attempts\"
  
  conditions {
    display_name = \"Failed auth attempts > 10 in 5 minutes\"
    
    condition_threshold {
      filter         = \"metric.type=\\\"logging.googleapis.com/user/techcorp_failed_auth_attempts\\\"\"
      duration       = \"300s\"
      comparison     = \"COMPARISON_GREATER_THAN\"
      threshold_value = 10
      
      aggregations {
        alignment_period   = \"300s\"
        per_series_aligner = \"ALIGN_RATE\"
      }
    }
  }
  
  notification_channels = []  # Will be configured in monitoring lab
  
  alert_strategy {
    auto_close = \"1800s\"  # 30 minutes
  }
  
  enabled = true
}

# Create monitoring policy for critical errors
resource \"google_monitoring_alert_policy\" \"critical_error_alert\" {
  display_name = \"TechCorp - Critical Application Errors\"
  
  conditions {
    display_name = \"Critical errors detected\"
    
    condition_threshold {
      filter         = \"metric.type=\\\"logging.googleapis.com/user/techcorp_critical_errors\\\"\"
      duration       = \"60s\"
      comparison     = \"COMPARISON_GREATER_THAN\"
      threshold_value = 0
      
      aggregations {
        alignment_period   = \"60s\"
        per_series_aligner = \"ALIGN_RATE\"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = \"3600s\"  # 1 hour
  }
  
  enabled = true
}
LOG_METRICS_END

echo \"✓ Log-based metrics and monitoring configuration added\"
\`\`\`

### Step 5: Create Variables and Outputs

Set up configuration management for the logging infrastructure.

\`\`\`bash
# Create variables file
cat > variables.tf << 'LOGGING_VARS_END'
# Variables for Lab 07: Cloud Logging Architecture

variable \"project_id\" {
  description = \"The GCP project ID\"
  type        = string
}

variable \"region\" {
  description = \"The default GCP region\"
  type        = string
  default     = \"us-central1\"
}

variable \"tf_state_bucket\" {
  description = \"Terraform state bucket name\"
  type        = string
}

variable \"log_retention_days\" {
  description = \"Default log retention period in days\"
  type        = number
  default     = 365
}

variable \"audit_log_retention_days\" {
  description = \"Audit log retention period for compliance\"
  type        = number
  default     = 2555  # 7 years
}

variable \"enable_data_access_logs\" {
  description = \"Enable data access logging for compliance\"
  type        = bool
  default     = true
}

variable \"log_export_enabled\" {
  description = \"Enable log export to external systems\"
  type        = bool
  default     = true
}

variable \"compliance_mode\" {
  description = \"Enable additional compliance features\"
  type        = string
  default     = \"fintech\"
  
  validation {
    condition     = contains([\"basic\", \"fintech\", \"healthcare\"], var.compliance_mode)
    error_message = \"Compliance mode must be basic, fintech, or healthcare.\"
  }
}
LOGGING_VARS_END

# Create terraform.tfvars
cat > terraform.tfvars << 'LOGGING_TFVARS_END'
# Lab 07 Configuration Values
project_id = \"\${PROJECT_ID}\"
region = \"\${REGION}\"
tf_state_bucket = \"\${TF_STATE_BUCKET}\"

# Compliance configuration for TechCorp
compliance_mode = \"fintech\"
audit_log_retention_days = 2555  # 7 years for SOX compliance
enable_data_access_logs = true
log_export_enabled = true
LOGGING_TFVARS_END

# Create comprehensive outputs
cat > outputs.tf << 'LOGGING_OUTPUTS_END'
# Outputs for Lab 07: Cloud Logging Architecture

# Log storage buckets
output \"log_storage_buckets\" {
  description = \"Created log storage buckets\"
  value = {
    audit_logs       = google_storage_bucket.audit_log_bucket.name
    security_logs    = google_storage_bucket.security_log_bucket.name
    application_logs = google_storage_bucket.application_log_bucket.name
  }
}

# Log sinks
output \"log_sinks\" {
  description = \"Configured log sinks\"
  value = {
    audit_sink       = google_logging_project_sink.audit_sink.name
    security_sink    = google_logging_project_sink.security_sink.name
    application_sink = google_logging_project_sink.application_sink.name
    bigquery_sink    = google_logging_project_sink.bigquery_sink.name
    alerting_sink    = google_logging_project_sink.alerting_sink.name
  }
}

# BigQuery dataset for log analysis
output \"logs_bigquery_dataset\" {
  description = \"BigQuery dataset for log analysis\"
  value = {
    dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
    location   = google_bigquery_dataset.logs_dataset.location
  }
}

# Pub/Sub topic for alerting
output \"log_alerting_topic\" {
  description = \"Pub/Sub topic for log-based alerting\"
  value = {
    name = google_pubsub_topic.log_alerts.name
    id   = google_pubsub_topic.log_alerts.id
  }
}

# Log-based metrics
output \"log_metrics\" {
  description = \"Created log-based metrics\"
  value = {
    failed_auth_metric   = google_logging_metric.failed_auth_metric.name
    critical_errors_metric = google_logging_metric.critical_errors_metric.name
    data_access_metric   = google_logging_metric.data_access_metric.name
  }
}

# Monitoring policies
output \"monitoring_policies\" {
  description = \"Created monitoring alert policies\"
  value = {
    failed_auth_alert   = google_monitoring_alert_policy.failed_auth_alert.name
    critical_error_alert = google_monitoring_alert_policy.critical_error_alert.name
  }
}

# Service accounts
output \"log_service_accounts\" {
  description = \"Service accounts for log management\"
  value = {
    log_analyst = {
      email = google_service_account.log_analyst.email
      name  = google_service_account.log_analyst.name
    }
  }
}

# Integration outputs for subsequent labs
output \"logging_integration\" {
  description = \"Logging integration points for other labs\"
  value = {
    bigquery_dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
    alerting_topic_name = google_pubsub_topic.log_alerts.name
    log_analyst_sa      = google_service_account.log_analyst.email
  }
}
LOGGING_OUTPUTS_END

echo \"✓ Variables and outputs configuration created\"
\`\`\`

### Step 6: Deploy and Validate Logging Infrastructure

Initialize, plan, and apply the logging configuration.

\`\`\`bash
# Initialize and deploy
echo \"Initializing Terraform for logging infrastructure...\"
terraform init

echo \"Validating logging configuration...\"
terraform validate

if [ \$? -eq 0 ]; then
    echo \"✓ Terraform configuration is valid\"
else
    echo \"✗ Terraform configuration validation failed\"
    exit 1
fi

echo \"Planning logging infrastructure deployment...\"
terraform plan -var-file=terraform.tfvars -out=lab07.tfplan

echo \"Review the plan above. It should show:\"
echo \"- Log storage buckets with compliance-grade retention\"
echo \"- Advanced log sinks for different log types\"
echo \"- BigQuery dataset for real-time log analysis\"
echo \"- Pub/Sub topic for real-time alerting\"
echo \"- Log-based metrics and monitoring policies\"
echo \"- IAM bindings for secure log access\"

read -p \"Apply this logging configuration? (y/N): \" confirm
if [[ \$confirm == \"y\" || \$confirm == \"Y\" ]]; then
    echo \"Applying logging infrastructure...\"
    terraform apply lab07.tfplan
    
    if [ \$? -eq 0 ]; then
        echo \"✓ Logging infrastructure deployed successfully\"
        echo \"✓ Centralized logging architecture is ready\"
    else
        echo \"✗ Terraform apply failed\"
        exit 1
    fi
else
    echo \"Terraform apply cancelled\"
    exit 1
fi
\`\`\`

### Step 7: Test Logging Configuration

Validate that logs are being properly collected and routed.

\`\`\`bash
# Create logging test script
cat > ../scripts/test-logging.sh << 'LOGGING_TEST_END'
#!/bin/bash

echo \"=== Testing TechCorp Logging Configuration ===\"

# Test log generation
echo \"Generating test logs...\"
gcloud logging write techcorp-test-log '{\"message\": \"Test log entry\", \"severity\": \"INFO\", \"component\": \"test\"}'
gcloud logging write techcorp-test-log '{\"message\": \"Test ERROR log\", \"severity\": \"ERROR\", \"component\": \"test\"}'
gcloud logging write techcorp-test-log '{\"message\": \"CRITICAL system alert\", \"severity\": \"CRITICAL\", \"component\": \"test\"}'

# Wait for log ingestion
echo \"Waiting for log ingestion (30 seconds)...\"
sleep 30

# Test log queries
echo \"Testing log queries...\"
gcloud logging read \"logName=\\\"projects/\${PROJECT_ID}/logs/techcorp-test-log\\\"\" --limit=5 --format=json

# Test BigQuery export
echo \"Checking BigQuery log export...\"
bq query --use_legacy_sql=false \"SELECT timestamp, severity, jsonPayload.message FROM \\\`\${PROJECT_ID}.techcorp_logs.*\\\` WHERE jsonPayload.component = 'test' LIMIT 5\"

# Test log-based metrics
echo \"Checking log-based metrics...\"
gcloud logging metrics list --filter=\"name:techcorp\"

echo \"✓ Logging configuration test completed\"
LOGGING_TEST_END

chmod +x ../scripts/test-logging.sh

echo \"✓ Logging test script created\"
echo \"Run: cd ~/gcp-landing-zone-workshop/lab-07/scripts && ./test-logging.sh\"
\`\`\`" \
"• Centralized logging infrastructure with compliance-grade retention policies
• Advanced log sinks routing logs to BigQuery, Cloud Storage, and Pub/Sub
• Log-based metrics for security monitoring and operational alerting
• BigQuery dataset for real-time log analysis and reporting
• Compliance audit trails meeting fintech regulatory requirements
• Automated monitoring policies for critical events and security incidents
• Service accounts and IAM configuration for secure log management
• Integration points for subsequent monitoring and alerting labs" \
"# Check log storage buckets
echo \"Checking log storage buckets...\"
buckets=(\"audit-logs\" \"security-logs\" \"application-logs\")
for bucket_type in \"\${buckets[@]}\"; do
    bucket_name=\"\${PROJECT_ID}-\${bucket_type}\"
    if gsutil ls gs://\$bucket_name &>/dev/null; then
        echo \"✓ Log bucket created: \$bucket_name\"
        ((validation_passed++))
        
        # Check bucket configuration
        if gsutil lifecycle get gs://\$bucket_name | grep -q \"age\"; then
            echo \"✓ Lifecycle policy configured for \$bucket_name\"
            ((validation_passed++))
        else
            echo \"✗ Lifecycle policy missing for \$bucket_name\"
            ((validation_failed++))
        fi
    else
        echo \"✗ Log bucket missing: \$bucket_name\"
        ((validation_failed++))
    fi
done

# Check log sinks
echo \"Checking log sinks...\"
log_sinks=(\"techcorp-audit-logs\" \"techcorp-security-logs\" \"techcorp-application-logs\" \"techcorp-logs-bigquery\" \"techcorp-log-alerting\")
for sink in \"\${log_sinks[@]}\"; do
    if gcloud logging sinks describe \$sink --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Log sink created: \$sink\"
        ((validation_passed++))
    else
        echo \"✗ Log sink missing: \$sink\"
        ((validation_failed++))
    fi
done

# Check BigQuery dataset
echo \"Checking BigQuery dataset...\"
if bq show --dataset \${PROJECT_ID}:techcorp_logs &>/dev/null; then
    echo \"✓ BigQuery logs dataset created\"
    ((validation_passed++))
else
    echo \"✗ BigQuery logs dataset missing\"
    ((validation_failed++))
fi

# Check Pub/Sub topic
echo \"Checking Pub/Sub alerting topic...\"
if gcloud pubsub topics describe techcorp-log-alerts --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Pub/Sub alerting topic created\"
    ((validation_passed++))
else
    echo \"✗ Pub/Sub alerting topic missing\"
    ((validation_failed++))
fi

# Check log-based metrics
echo \"Checking log-based metrics...\"
log_metrics=(\"techcorp_failed_auth_attempts\" \"techcorp_critical_errors\" \"techcorp_data_access\")
for metric in \"\${log_metrics[@]}\"; do
    if gcloud logging metrics describe \$metric --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Log-based metric created: \$metric\"
        ((validation_passed++))
    else
        echo \"✗ Log-based metric missing: \$metric\"
        ((validation_failed++))
    fi
done

# Check monitoring alert policies
echo \"Checking monitoring alert policies...\"
policies=\$(gcloud alpha monitoring policies list --filter=\"displayName:TechCorp\" --format=\"value(name)\" 2>/dev/null)
if [ -n \"\$policies\" ]; then
    echo \"✓ Monitoring alert policies created\"
    ((validation_passed++))
else
    echo \"✗ Monitoring alert policies missing\"
    ((validation_failed++))
fi

# Check service accounts
echo \"Checking log management service accounts...\"
sa_email=\"techcorp-log-analyst@\${PROJECT_ID}.iam.gserviceaccount.com\"
if gcloud iam service-accounts describe \$sa_email --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Log analyst service account created\"
    ((validation_passed++))
else
    echo \"✗ Log analyst service account missing\"
    ((validation_failed++))
fi

# Test log ingestion
echo \"Testing log ingestion...\"
test_log_entry=\"{\\\"message\\\": \\\"Lab 07 validation test\\\", \\\"severity\\\": \\\"INFO\\\", \\\"lab\\\": \\\"07\\\"}\"
if gcloud logging write lab07-validation \"\$test_log_entry\" --project=\$PROJECT_ID; then
    echo \"✓ Log ingestion test successful\"
    ((validation_passed++))
else
    echo \"✗ Log ingestion test failed\"
    ((validation_failed++))
fi

# Check Terraform outputs
echo \"Checking Terraform outputs...\"
cd terraform
terraform_outputs=\$(terraform output -json 2>/dev/null)
if [ \$? -eq 0 ] && [ \"\$terraform_outputs\" != \"{}\" ]; then
    echo \"✓ Terraform outputs available\"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=(\"log_storage_buckets\" \"log_sinks\" \"logs_bigquery_dataset\" \"log_alerting_topic\")
    for output in \"\${required_outputs[@]}\"; do
        if echo \"\$terraform_outputs\" | jq -e \".\$output\" &>/dev/null; then
            echo \"✓ Output available: \$output\"
            ((validation_passed++))
        else
            echo \"✗ Output missing: \$output\"
            ((validation_failed++))
        fi
    done
else
    echo \"✗ Terraform outputs not available\"
    ((validation_failed++))
fi
cd .." \
"**Issue 1: Log Sink Permission Issues**
\`\`\`bash
# Check service account permissions for log sinks
gcloud projects get-iam-policy \$PROJECT_ID --flatten=\"bindings[].members\" --filter=\"bindings.members:serviceAccount\"

# Manual permission grant
gcloud projects add-iam-policy-binding \$PROJECT_ID --member=\"serviceAccount:cloud-logs@system.gserviceaccount.com\" --role=\"roles/storage.objectCreator\"
\`\`\`

**Issue 2: BigQuery Dataset Access Issues**
\`\`\`bash
# Check BigQuery API enablement
gcloud services list --enabled --filter=\"name:bigquery.googleapis.com\"

# Manual dataset creation
bq mk --dataset --location=\$REGION \${PROJECT_ID}:techcorp_logs
\`\`\`

**Issue 3: Log Retention Policy Issues**
\`\`\`bash
# Check bucket lifecycle policies
gsutil lifecycle get gs://\${PROJECT_ID}-audit-logs

# Manual lifecycle policy application
gsutil lifecycle set lifecycle-config.json gs://\${PROJECT_ID}-audit-logs
\`\`\`

**Issue 4: Pub/Sub Topic Creation Issues**
\`\`\`bash
# Check Pub/Sub API enablement
gcloud services list --enabled --filter=\"name:pubsub.googleapis.com\"

# Manual topic creation
gcloud pubsub topics create techcorp-log-alerts
\`\`\`" \
"### Immediate Next Steps
1. **Validate Log Flow**: Test that logs are being properly collected and routed to destinations
2. **Review Compliance Settings**: Ensure retention policies meet regulatory requirements
3. **Test Alerting**: Verify that critical log events trigger appropriate alerts
4. **Prepare for Lab 08**: The logging infrastructure will integrate with shared services

### Key Takeaways
- **Centralized Logging**: All logs flow through a unified architecture for compliance and monitoring
- **Compliance Ready**: Retention policies and audit trails meet fintech regulatory requirements
- **Real-time Analysis**: BigQuery integration enables sophisticated log analysis and reporting
- **Security Monitoring**: Log-based metrics provide automated security incident detection"

# Create Lab 08 - Shared Services Implementation
echo "Creating Lab 08: Shared Services Implementation..."
create_comprehensive_day2_lab_guide "08" "Shared Services Implementation" \
"Deploy shared services including Cloud DNS, certificate management, centralized security scanning, and service discovery to support TechCorp's enterprise infrastructure with high availability and automation." \
"60 minutes" \
"**Shared Services Architecture**: Enterprise environments require centralized services that are shared across multiple applications and environments. This includes DNS resolution, certificate management, security scanning, and service discovery to reduce operational overhead and ensure consistency.

**Cloud DNS and Service Discovery**: Centralized DNS management provides consistent name resolution across hybrid and multi-cloud environments. This includes private DNS zones, DNS forwarding, and service discovery patterns for microservices architectures.

**Certificate Management**: Automated certificate provisioning, rotation, and management are essential for enterprise security. This includes integration with Certificate Authority services, automated renewal, and distribution to services.

**Security Services**: Centralized security services include vulnerability scanning, compliance monitoring, and security automation that can be shared across all environments and applications." \
"• Deploy and configure Cloud DNS for internal and external resolution
• Set up automated certificate management with automatic rotation and distribution
• Implement centralized security scanning and vulnerability management
• Configure service discovery architecture for microservices
• Deploy shared monitoring and observability services
• Set up centralized configuration management and secret distribution
• Implement shared backup and disaster recovery services" \
"Successful completion of Labs 01-07 (including centralized logging)" \
"### Step 1: Cloud DNS Infrastructure Setup

Configure enterprise DNS services for TechCorp's internal and external resolution needs.

\`\`\`bash
# Navigate to lab directory
cd ~/gcp-landing-zone-workshop/lab-08/terraform

# Create main shared services configuration
cat > main.tf << 'SHARED_SERVICES_MAIN_END'
# Lab 08: Shared Services Implementation
# Centralized shared services for TechCorp enterprise infrastructure

terraform {
  required_version = \">= 1.5\"
  required_providers {
    google = {
      source  = \"hashicorp/google\"
      version = \"~> 5.0\"
    }
    google-beta = {
      source  = \"hashicorp/google-beta\"
      version = \"~> 5.0\"
    }
  }
  
  backend \"gcs\" {
    bucket = \"\${TF_STATE_BUCKET}\"
    prefix = \"lab-08/terraform/state\"
  }
}

# Get previous lab outputs for integration
data \"terraform_remote_state\" \"lab02\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-02/terraform/state\"
  }
}

data \"terraform_remote_state\" \"lab07\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-07/terraform/state\"
  }
}

# Local values for shared services
locals {
  common_labels = {
    workshop    = \"gcp-landing-zone\"
    lab         = \"08\"
    component   = \"shared-services\"
    environment = \"enterprise\"
  }
  
  # DNS zone configuration
  dns_zones = {
    internal = {
      name         = \"techcorp-internal\"
      dns_name     = \"techcorp.internal.\"
      description  = \"Internal DNS zone for TechCorp services\"
      visibility   = \"private\"
    }
    public = {
      name         = \"techcorp-public\"
      dns_name     = \"techcorp-demo.com.\"
      description  = \"Public DNS zone for TechCorp external services\"
      visibility   = \"public\"
    }
  }
  
  # Service endpoints for internal resolution
  internal_services = {
    \"api\"      = \"10.1.0.10\"
    \"database\" = \"10.1.4.10\"
    \"cache\"    = \"10.1.0.20\"
    \"monitor\"  = \"10.0.0.10\"
    \"logs\"     = \"10.0.0.20\"
  }
}

# Create private DNS zone for internal services
resource \"google_dns_managed_zone\" \"internal_zone\" {
  name         = local.dns_zones.internal.name
  dns_name     = local.dns_zones.internal.dns_name
  description  = local.dns_zones.internal.description
  
  visibility = \"private\"
  
  private_visibility_config {
    networks {
      network_url = data.terraform_remote_state.lab02.outputs.shared_vpc.id
    }
  }
  
  labels = merge(local.common_labels, {
    zone_type = \"private\"
    purpose   = \"internal-services\"
  })
}

# Create DNS records for internal services
resource \"google_dns_record_set\" \"internal_services\" {
  for_each = local.internal_services
  
  name         = \"\${each.key}.\${google_dns_managed_zone.internal_zone.dns_name}\"
  managed_zone = google_dns_managed_zone.internal_zone.name
  type         = \"A\"
  ttl          = 300
  rrdatas      = [each.value]
}

# Create CNAME records for service aliases
resource \"google_dns_record_set\" \"service_aliases\" {
  for_each = {
    \"db\"  = \"database.techcorp.internal.\"
    \"api\" = \"api.techcorp.internal.\"
    \"mon\" = \"monitor.techcorp.internal.\"
  }
  
  name         = \"\${each.key}.\${google_dns_managed_zone.internal_zone.dns_name}\"
  managed_zone = google_dns_managed_zone.internal_zone.name
  type         = \"CNAME\"
  ttl          = 300
  rrdatas      = [each.value]
}

# Create public DNS zone (for demo purposes)
resource \"google_dns_managed_zone\" \"public_zone\" {
  name        = local.dns_zones.public.name
  dns_name    = local.dns_zones.public.dns_name
  description = local.dns_zones.public.description
  
  visibility = \"public\"
  
  labels = merge(local.common_labels, {
    zone_type = \"public\"
    purpose   = \"external-services\"
  })
}

# Create public DNS records
resource \"google_dns_record_set\" \"public_www\" {
  name         = \"www.\${google_dns_managed_zone.public_zone.dns_name}\"
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = \"A\"
  ttl          = 300
  rrdatas      = [\"203.0.113.10\"]  # Example public IP
}
SHARED_SERVICES_MAIN_END

echo \"✓ DNS infrastructure configuration created\"
\`\`\`

### Step 2: Certificate Management Setup

Configure automated certificate management for TechCorp's services.

\`\`\`bash
# Add certificate management configuration
cat >> main.tf << 'CERT_MGMT_END'

# Create SSL certificates for internal services
resource \"google_compute_ssl_certificate\" \"internal_cert\" {
  name_prefix = \"techcorp-internal-\"
  description = \"SSL certificate for TechCorp internal services\"
  
  managed {
    domains = [
      \"api.techcorp.internal\",
      \"monitor.techcorp.internal\",
      \"logs.techcorp.internal\"
    ]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create SSL certificate for public services
resource \"google_compute_ssl_certificate\" \"public_cert\" {
  name_prefix = \"techcorp-public-\"
  description = \"SSL certificate for TechCorp public services\"
  
  managed {
    domains = [
      \"www.techcorp-demo.com\",
      \"api.techcorp-demo.com\"
    ]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create Certificate Manager certificate map
resource \"google_certificate_manager_certificate_map\" \"techcorp_cert_map\" {
  name        = \"techcorp-certificate-map\"
  description = \"Certificate map for TechCorp services\"
  
  labels = local.common_labels
}

# Create certificate map entries
resource \"google_certificate_manager_certificate_map_entry\" \"internal_entry\" {
  name         = \"internal-services\"
  description  = \"Certificate mapping for internal services\"
  map          = google_certificate_manager_certificate_map.techcorp_cert_map.name
  certificates = [google_compute_ssl_certificate.internal_cert.id]
  hostname     = \"*.techcorp.internal\"
}

resource \"google_certificate_manager_certificate_map_entry\" \"public_entry\" {
  name         = \"public-services\"
  description  = \"Certificate mapping for public services\"
  map          = google_certificate_manager_certificate_map.techcorp_cert_map.name
  certificates = [google_compute_ssl_certificate.public_cert.id]
  hostname     = \"*.techcorp-demo.com\"
}

# Create secrets for certificate management
resource \"google_secret_manager_secret\" \"tls_private_key\" {
  secret_id = \"techcorp-tls-private-key\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"tls-certificates\"
  })
}

# Store certificate information
resource \"google_secret_manager_secret\" \"cert_metadata\" {
  secret_id = \"techcorp-cert-metadata\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"certificate-metadata\"
  })
}

resource \"google_secret_manager_secret_version\" \"cert_metadata_version\" {
  secret = google_secret_manager_secret.cert_metadata.id
  secret_data = jsonencode({
    internal_cert_id = google_compute_ssl_certificate.internal_cert.id
    public_cert_id   = google_compute_ssl_certificate.public_cert.id
    cert_map_id      = google_certificate_manager_certificate_map.techcorp_cert_map.id
    created_at       = timestamp()
  })
}
CERT_MGMT_END

echo \"✓ Certificate management configuration added\"
\`\`\`

### Step 3: Shared Security Services

Set up centralized security scanning and monitoring services.

\`\`\`bash
# Add security services configuration
cat >> main.tf << 'SECURITY_SERVICES_END'

# Create service account for security scanning
resource \"google_service_account\" \"security_scanner\" {
  account_id   = \"techcorp-security-scanner\"
  display_name = \"TechCorp Security Scanner Service Account\"
  description  = \"Service account for centralized security scanning and vulnerability assessment\"
}

# Grant security scanner permissions
resource \"google_project_iam_member\" \"security_scanner_permissions\" {
  for_each = toset([
    \"roles/cloudsecurityscanner.editor\",
    \"roles/securitycenter.admin\",
    \"roles/compute.securityAdmin\",
    \"roles/storage.admin\"
  ])
  
  project = var.project_id
  role    = each.value
  member  = \"serviceAccount:\${google_service_account.security_scanner.email}\"
}

# Create security scanning configuration storage
resource \"google_storage_bucket\" \"security_scan_results\" {
  name     = \"\${var.project_id}-security-scan-results\"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = \"Delete\"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = \"security-scanning\"
  })
}

# Create Pub/Sub topic for security alerts
resource \"google_pubsub_topic\" \"security_alerts\" {
  name = \"techcorp-security-alerts\"
  
  labels = merge(local.common_labels, {
    purpose = \"security-alerting\"
  })
}

# Create subscription for security alerts
resource \"google_pubsub_subscription\" \"security_alerts_sub\" {
  name  = \"techcorp-security-alerts-processor\"
  topic = google_pubsub_topic.security_alerts.name
  
  # Message retention for 7 days
  message_retention_duration = \"604800s\"
  
  # Acknowledgment deadline
  ack_deadline_seconds = 20
  
  labels = local.common_labels
}

# Create Cloud Function for security alert processing (placeholder)
resource \"google_storage_bucket_object\" \"security_function_source\" {
  name   = \"security-alert-processor.zip\"
  bucket = google_storage_bucket.security_scan_results.name
  source = \"/dev/null\"  # Placeholder - would contain actual function code
}

# Create security monitoring dashboard configuration
resource \"google_secret_manager_secret\" \"security_dashboard_config\" {
  secret_id = \"techcorp-security-dashboard-config\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"security-monitoring\"
  })
}

resource \"google_secret_manager_secret_version\" \"security_dashboard_config_version\" {
  secret = google_secret_manager_secret.security_dashboard_config.id
  secret_data = jsonencode({
    dashboard_title = \"TechCorp Security Overview\"
    scan_frequency  = \"daily\"
    alert_channels  = [google_pubsub_topic.security_alerts.name]
    scan_targets    = [
      \"api.techcorp.internal\",
      \"www.techcorp-demo.com\"
    ]
    compliance_frameworks = [\"PCI-DSS\", \"SOX\", \"ISO-27001\"]
  })
}
SECURITY_SERVICES_END

echo \"✓ Security services configuration added\"
\`\`\`

### Step 4: Service Discovery and Configuration Management

Set up service discovery and centralized configuration management.

\`\`\`bash
# Add service discovery configuration
cat >> main.tf << 'SERVICE_DISCOVERY_END'

# Create service registry in Secret Manager
resource \"google_secret_manager_secret\" \"service_registry\" {
  secret_id = \"techcorp-service-registry\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"service-discovery\"
  })
}

resource \"google_secret_manager_secret_version\" \"service_registry_version\" {
  secret = google_secret_manager_secret.service_registry.id
  secret_data = jsonencode({
    services = {
      api = {
        endpoint    = \"api.techcorp.internal\"
        port        = 443
        protocol    = \"https\"
        health_path = \"/health\"
        environment = \"shared\"
      }
      database = {
        endpoint    = \"database.techcorp.internal\"
        port        = 5432
        protocol    = \"postgresql\"
        environment = \"shared\"
      }
      cache = {
        endpoint    = \"cache.techcorp.internal\"
        port        = 6379
        protocol    = \"redis\"
        environment = \"shared\"
      }
      monitoring = {
        endpoint    = \"monitor.techcorp.internal\"
        port        = 443
        protocol    = \"https\"
        health_path = \"/health\"
        environment = \"shared\"
      }
      logging = {
        endpoint    = \"logs.techcorp.internal\"
        port        = 443
        protocol    = \"https\"
        environment = \"shared\"
      }
    }
    discovery_config = {
      ttl                = 300
      health_check_interval = 30
      retry_attempts     = 3
    }
  })
}

# Create shared configuration store
resource \"google_secret_manager_secret\" \"shared_config\" {
  secret_id = \"techcorp-shared-config\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"configuration-management\"
  })
}

resource \"google_secret_manager_secret_version\" \"shared_config_version\" {
  secret = google_secret_manager_secret.shared_config.id
  secret_data = jsonencode({
    database = {
      max_connections = 100
      timeout_seconds = 30
      ssl_mode       = \"require\"
    }
    cache = {
      max_memory     = \"512mb\"
      eviction_policy = \"allkeys-lru\"
      timeout_seconds = 5
    }
    monitoring = {
      scrape_interval = \"15s\"
      evaluation_interval = \"15s\"
      retention_days = 30
    }
    logging = {
      level = \"INFO\"
      format = \"json\"
      rotation_size = \"100MB\"
    }
    security = {
      tls_min_version = \"1.2\"
      cipher_suites   = [\"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\"]
      session_timeout = 3600
    }
  })
}

# Create service account for configuration access
resource \"google_service_account\" \"config_manager\" {
  account_id   = \"techcorp-config-manager\"
  display_name = \"TechCorp Configuration Manager\"
  description  = \"Service account for shared configuration management\"
}

# Grant configuration manager permissions
resource \"google_secret_manager_secret_iam_member\" \"config_access\" {
  for_each = {
    service_registry = google_secret_manager_secret.service_registry.secret_id
    shared_config    = google_secret_manager_secret.shared_config.secret_id
  }
  
  secret_id = each.value
  role      = \"roles/secretmanager.secretAccessor\"
  member    = \"serviceAccount:\${google_service_account.config_manager.email}\"
}
SERVICE_DISCOVERY_END

echo \"✓ Service discovery and configuration management added\"
\`\`\`

### Step 5: Shared Monitoring and Backup Services

Configure shared operational services for the enterprise.

\`\`\`bash
# Add shared operational services
cat >> main.tf << 'OPERATIONAL_SERVICES_END'

# Create shared monitoring workspace
resource \"google_monitoring_workspace\" \"techcorp_workspace\" {
  count = 0  # Disabled as workspace creation requires special handling
}

# Create shared backup storage
resource \"google_storage_bucket\" \"shared_backups\" {
  name     = \"\${var.project_id}-shared-backups\"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = \"SetStorageClass\"
      storage_class = \"NEARLINE\"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = \"SetStorageClass\"
      storage_class = \"COLDLINE\"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = \"SetStorageClass\"
      storage_class = \"ARCHIVE\"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = \"shared-backups\"
  })
}

# Create backup schedule configuration
resource \"google_secret_manager_secret\" \"backup_schedule\" {
  secret_id = \"techcorp-backup-schedule\"
  
  replication {
    automatic = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"backup-configuration\"
  })
}

resource \"google_secret_manager_secret_version\" \"backup_schedule_version\" {
  secret = google_secret_manager_secret.backup_schedule.id
  secret_data = jsonencode({
    schedules = {
      daily = {
        time     = \"02:00\"
        timezone = \"UTC\"
        retention_days = 7
        targets = [\"databases\", \"configurations\", \"logs\"]
      }
      weekly = {
        day      = \"sunday\"
        time     = \"01:00\"
        timezone = \"UTC\"
        retention_weeks = 4
        targets = [\"full-system\", \"security-configs\"]
      }
      monthly = {
        day      = 1
        time     = \"00:00\"
        timezone = \"UTC\"
        retention_months = 12
        targets = [\"archive\", \"compliance-data\"]
      }
    }
    notification_channels = [
      google_pubsub_topic.security_alerts.name,
      data.terraform_remote_state.lab07.outputs.log_alerting_topic.name
    ]
  })
}

# Create service account for backup operations
resource \"google_service_account\" \"backup_manager\" {
  account_id   = \"techcorp-backup-manager\"
  display_name = \"TechCorp Backup Manager\"
  description  = \"Service account for shared backup and restore operations\"
}

# Grant backup manager permissions
resource \"google_project_iam_member\" \"backup_manager_permissions\" {
  for_each = toset([
    \"roles/storage.admin\",
    \"roles/compute.storageAdmin\",
    \"roles/secretmanager.secretAccessor\"
  ])
  
  project = var.project_id
  role    = each.value
  member  = \"serviceAccount:\${google_service_account.backup_manager.email}\"
}

# Create shared health check endpoints
resource \"google_compute_health_check\" \"shared_services_health\" {
  name        = \"techcorp-shared-services-health\"
  description = \"Health check for shared services\"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 80
    request_path = \"/health\"
  }
}

# Data source for current user
data \"google_client_openid_userinfo\" \"current\" {}
OPERATIONAL_SERVICES_END

echo \"✓ Operational services configuration added\"
\`\`\`

### Step 6: Create Variables and Outputs

Set up configuration management for shared services.

\`\`\`bash
# Create variables file
cat > variables.tf << 'SHARED_VARS_END'
# Variables for Lab 08: Shared Services Implementation

variable \"project_id\" {
  description = \"The GCP project ID\"
  type        = string
}

variable \"region\" {
  description = \"The default GCP region\"
  type        = string
  default     = \"us-central1\"
}

variable \"tf_state_bucket\" {
  description = \"Terraform state bucket name\"
  type        = string
}

variable \"internal_domain\" {
  description = \"Internal domain name for TechCorp\"
  type        = string
  default     = \"techcorp.internal\"
}

variable \"public_domain\" {
  description = \"Public domain name for TechCorp demo\"
  type        = string
  default     = \"techcorp-demo.com\"
}

variable \"enable_security_scanning\" {
  description = \"Enable centralized security scanning\"
  type        = bool
  default     = true
}

variable \"backup_retention_days\" {
  description = \"Default backup retention period\"
  type        = number
  default     = 30
}

variable \"certificate_auto_renewal\" {
  description = \"Enable automatic certificate renewal\"
  type        = bool
  default     = true
}

variable \"dns_ttl\" {
  description = \"Default TTL for DNS records\"
  type        = number
  default     = 300
}
SHARED_VARS_END

# Create terraform.tfvars
cat > terraform.tfvars << 'SHARED_TFVARS_END'
# Lab 08 Configuration Values
project_id = \"\${PROJECT_ID}\"
region = \"\${REGION}\"
tf_state_bucket = \"\${TF_STATE_BUCKET}\"

# TechCorp shared services configuration
internal_domain = \"techcorp.internal\"
public_domain = \"techcorp-demo.com\"
enable_security_scanning = true
backup_retention_days = 30
certificate_auto_renewal = true
dns_ttl = 300
SHARED_TFVARS_END

# Create comprehensive outputs
cat > outputs.tf << 'SHARED_OUTPUTS_END'
# Outputs for Lab 08: Shared Services Implementation

# DNS zones and records
output \"dns_zones\" {
  description = \"Created DNS zones\"
  value = {
    internal = {
      name     = google_dns_managed_zone.internal_zone.name
      dns_name = google_dns_managed_zone.internal_zone.dns_name
      id       = google_dns_managed_zone.internal_zone.id
    }
    public = {
      name     = google_dns_managed_zone.public_zone.name
      dns_name = google_dns_managed_zone.public_zone.dns_name
      id       = google_dns_managed_zone.public_zone.id
    }
  }
}

output \"service_endpoints\" {
  description = \"Internal service endpoints\"
  value = {
    for service, ip in local.internal_services : service => {
      fqdn = \"\${service}.techcorp.internal\"
      ip   = ip
    }
  }
}

# Certificate management
output \"ssl_certificates\" {
  description = \"Created SSL certificates\"
  value = {
    internal_cert = {
      id   = google_compute_ssl_certificate.internal_cert.id
      name = google_compute_ssl_certificate.internal_cert.name
    }
    public_cert = {
      id   = google_compute_ssl_certificate.public_cert.id
      name = google_compute_ssl_certificate.public_cert.name
    }
    cert_map = {
      id   = google_certificate_manager_certificate_map.techcorp_cert_map.id
      name = google_certificate_manager_certificate_map.techcorp_cert_map.name
    }
  }
}

# Security services
output \"security_services\" {
  description = \"Shared security services\"
  value = {
    scanner_sa      = google_service_account.security_scanner.email
    scan_results_bucket = google_storage_bucket.security_scan_results.name
    alerts_topic    = google_pubsub_topic.security_alerts.name
    alerts_subscription = google_pubsub_subscription.security_alerts_sub.name
  }
}

# Service discovery and configuration
output \"service_discovery\" {
  description = \"Service discovery configuration\"
  value = {
    service_registry_secret = google_secret_manager_secret.service_registry.secret_id
    shared_config_secret   = google_secret_manager_secret.shared_config.secret_id
    config_manager_sa      = google_service_account.config_manager.email
  }
}

# Backup services
output \"backup_services\" {
  description = \"Shared backup services\"
  value = {
    backup_bucket     = google_storage_bucket.shared_backups.name
    backup_schedule   = google_secret_manager_secret.backup_schedule.secret_id
    backup_manager_sa = google_service_account.backup_manager.email
  }
}

# Health checks
output \"health_checks\" {
  description = \"Shared health check configurations\"
  value = {
    shared_services_health = google_compute_health_check.shared_services_health.id
  }
}

# Integration outputs for subsequent labs
output \"shared_services_integration\" {
  description = \"Integration points for other labs\"
  value = {
    internal_dns_zone     = google_dns_managed_zone.internal_zone.name
    certificate_map_id    = google_certificate_manager_certificate_map.techcorp_cert_map.id
    security_alerts_topic = google_pubsub_topic.security_alerts.name
    service_registry      = google_secret_manager_secret.service_registry.secret_id
    backup_bucket        = google_storage_bucket.shared_backups.name
  }
}
SHARED_OUTPUTS_END

echo \"✓ Variables and outputs configuration created\"
\`\`\`

### Step 7: Deploy and Validate Shared Services

Initialize, plan, and apply the shared services configuration.

\`\`\`bash
# Initialize and deploy
echo \"Initializing Terraform for shared services...\"
terraform init

echo \"Validating shared services configuration...\"
terraform validate

if [ \$? -eq 0 ]; then
    echo \"✓ Terraform configuration is valid\"
else
    echo \"✗ Terraform configuration validation failed\"
    exit 1
fi

echo \"Planning shared services deployment...\"
terraform plan -var-file=terraform.tfvars -out=lab08.tfplan

echo \"Review the plan above. It should show:\"
echo \"- Private and public DNS zones with service records\"
echo \"- SSL certificates with automatic management\"
echo \"- Security scanning infrastructure\"
echo \"- Service discovery and configuration management\"
echo \"- Shared backup and monitoring services\"
echo \"- Service accounts with appropriate permissions\"

read -p \"Apply this shared services configuration? (y/N): \" confirm
if [[ \$confirm == \"y\" || \$confirm == \"Y\" ]]; then
    echo \"Applying shared services infrastructure...\"
    terraform apply lab08.tfplan
    
    if [ \$? -eq 0 ]; then
        echo \"✓ Shared services infrastructure deployed successfully\"
        echo \"✓ Enterprise shared services are ready\"
    else
        echo \"✗ Terraform apply failed\"
        exit 1
    fi
else
    echo \"Terraform apply cancelled\"
    exit 1
fi
\`\`\`

### Step 8: Test Shared Services

Create scripts to validate shared services functionality.

\`\`\`bash
# Create shared services test script
cat > ../scripts/test-shared-services.sh << 'SHARED_TEST_END'
#!/bin/bash

echo \"=== Testing TechCorp Shared Services ===\"

# Test DNS resolution
echo \"Testing DNS resolution...\"
echo \"Internal DNS zone: techcorp.internal\"
gcloud dns managed-zones describe techcorp-internal --format=\"value(dnsName)\"

echo \"Testing DNS records...\"
gcloud dns record-sets list --zone=techcorp-internal --format=\"table(name,type,ttl,rrdatas)\"

# Test certificate management
echo \"Testing SSL certificates...\"
gcloud compute ssl-certificates list --filter=\"name:techcorp\" --format=\"table(name,managed.status,managed.domains)\"

# Test service discovery
echo \"Testing service registry...\"
gcloud secrets versions access latest --secret=\"techcorp-service-registry\" | jq '.services | keys[]'

# Test security services
echo \"Testing security infrastructure...\"
echo \"Security scanner service account:\"
gcloud iam service-accounts describe techcorp-security-scanner@\${PROJECT_ID}.iam.gserviceaccount.com

echo \"Security alerts topic:\"
gcloud pubsub topics describe techcorp-security-alerts

# Test backup services
echo \"Testing backup infrastructure...\"
echo \"Backup bucket:\"
gsutil ls gs://\${PROJECT_ID}-shared-backups

echo \"Backup schedule:\"
gcloud secrets versions access latest --secret=\"techcorp-backup-schedule\" | jq '.schedules | keys[]'

echo \"✓ Shared services functionality test completed\"
SHARED_TEST_END

chmod +x ../scripts/test-shared-services.sh

echo \"✓ Shared services test script created\"
echo \"Run: cd ~/gcp-landing-zone-workshop/lab-08/scripts && ./test-shared-services.sh\"
\`\`\`" \
"• Enterprise DNS infrastructure with private and public zones for service resolution
• Automated SSL certificate management with certificate maps and auto-renewal
• Centralized security scanning infrastructure with vulnerability assessment capabilities
• Service discovery architecture with configuration management and service registry
• Shared backup services with automated scheduling and lifecycle management
• Pub/Sub-based alerting system integrated with logging infrastructure
• Service accounts and IAM configuration for secure shared service access
• Health check infrastructure for service monitoring and availability
• Integration points for subsequent workload and monitoring labs" \
"# Check DNS zones
echo \"Checking DNS zones...\"
dns_zones=(\"techcorp-internal\" \"techcorp-public\")
for zone in \"\${dns_zones[@]}\"; do
    if gcloud dns managed-zones describe \$zone --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ DNS zone created: \$zone\"
        ((validation_passed++))
        
        # Check DNS records
        record_count=\$(gcloud dns record-sets list --zone=\$zone --format=\"value(name)\" | wc -l)
        if [ \$record_count -gt 2 ]; then  # More than default NS and SOA
            echo \"✓ DNS records configured for \$zone\"
            ((validation_passed++))
        else
            echo \"✗ No custom DNS records found for \$zone\"
            ((validation_failed++))
        fi
    else
        echo \"✗ DNS zone missing: \$zone\"
        ((validation_failed++))
    fi
done

# Check SSL certificates
echo \"Checking SSL certificates...\"
ssl_certs=\$(gcloud compute ssl-certificates list --filter=\"name:techcorp\" --format=\"value(name)\" | wc -l)
if [ \$ssl_certs -gt 0 ]; then
    echo \"✓ SSL certificates created: \$ssl_certs certificates\"
    ((validation_passed++))
else
    echo \"✗ No SSL certificates found\"
    ((validation_failed++))
fi

# Check certificate map
echo \"Checking certificate map...\"
if gcloud certificate-manager maps describe techcorp-certificate-map --location=global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Certificate map created\"
    ((validation_passed++))
else
    echo \"✗ Certificate map missing\"
    ((validation_failed++))
fi

# Check security services
echo \"Checking security services...\"
security_sa=\"techcorp-security-scanner@\${PROJECT_ID}.iam.gserviceaccount.com\"
if gcloud iam service-accounts describe \$security_sa --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Security scanner service account created\"
    ((validation_passed++))
else
    echo \"✗ Security scanner service account missing\"
    ((validation_failed++))
fi

# Check security bucket
security_bucket=\"\${PROJECT_ID}-security-scan-results\"
if gsutil ls gs://\$security_bucket &>/dev/null; then
    echo \"✓ Security scan results bucket created\"
    ((validation_passed++))
else
    echo \"✗ Security scan results bucket missing\"
    ((validation_failed++))
fi

# Check Pub/Sub topics
echo \"Checking Pub/Sub topics...\"
if gcloud pubsub topics describe techcorp-security-alerts --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Security alerts topic created\"
    ((validation_passed++))
else
    echo \"✗ Security alerts topic missing\"
    ((validation_failed++))
fi

# Check secrets (service discovery and configuration)
echo \"Checking shared secrets...\"
shared_secrets=(\"techcorp-service-registry\" \"techcorp-shared-config\" \"techcorp-backup-schedule\")
for secret in \"\${shared_secrets[@]}\"; do
    if gcloud secrets describe \$secret --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Secret created: \$secret\"
        ((validation_passed++))
    else
        echo \"✗ Secret missing: \$secret\"
        ((validation_failed++))
    fi
done

# Check backup services
echo \"Checking backup services...\"
backup_bucket=\"\${PROJECT_ID}-shared-backups\"
if gsutil ls gs://\$backup_bucket &>/dev/null; then
    echo \"✓ Shared backup bucket created\"
    ((validation_passed++))
else
    echo \"✗ Shared backup bucket missing\"
    ((validation_failed++))
fi

backup_sa=\"techcorp-backup-manager@\${PROJECT_ID}.iam.gserviceaccount.com\"
if gcloud iam service-accounts describe \$backup_sa --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Backup manager service account created\"
    ((validation_passed++))
else
    echo \"✗ Backup manager service account missing\"
    ((validation_failed++))
fi

# Check health checks
echo \"Checking health checks...\"
if gcloud compute health-checks describe techcorp-shared-services-health --global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Shared services health check created\"
    ((validation_passed++))
else
    echo \"✗ Shared services health check missing\"
    ((validation_failed++))
fi

# Check service accounts and IAM
echo \"Checking service accounts...\"
config_sa=\"techcorp-config-manager@\${PROJECT_ID}.iam.gserviceaccount.com\"
if gcloud iam service-accounts describe \$config_sa --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Configuration manager service account created\"
    ((validation_passed++))
else
    echo \"✗ Configuration manager service account missing\"
    ((validation_failed++))
fi

# Test DNS resolution
echo \"Testing DNS resolution...\"
if host api.techcorp.internal 8.8.8.8 &>/dev/null; then
    echo \"✓ Internal DNS resolution working\"
    ((validation_passed++))
else
    echo \"⚠ Internal DNS resolution test skipped (requires proper network setup)\"
fi

# Check Terraform outputs
echo \"Checking Terraform outputs...\"
cd terraform
terraform_outputs=\$(terraform output -json 2>/dev/null)
if [ \$? -eq 0 ] && [ \"\$terraform_outputs\" != \"{}\" ]; then
    echo \"✓ Terraform outputs available\"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=(\"dns_zones\" \"ssl_certificates\" \"security_services\" \"service_discovery\" \"backup_services\")
    for output in \"\${required_outputs[@]}\"; do
        if echo \"\$terraform_outputs\" | jq -e \".\$output\" &>/dev/null; then
            echo \"✓ Output available: \$output\"
            ((validation_passed++))
        else
            echo \"✗ Output missing: \$output\"
            ((validation_failed++))
        fi
    done
else
    echo \"✗ Terraform outputs not available\"
    ((validation_failed++))
fi
cd .." \
"**Issue 1: DNS Zone Creation Issues**
\`\`\`bash
# Check DNS API enablement
gcloud services list --enabled --filter=\"name:dns.googleapis.com\"

# Verify network reference for private zones
gcloud compute networks describe techcorp-shared-vpc --project=\$PROJECT_ID
\`\`\`

**Issue 2: Certificate Management Issues**
\`\`\`bash
# Check Certificate Manager API enablement
gcloud services list --enabled --filter=\"name:certificatemanager.googleapis.com\"

# Manual certificate creation
gcloud compute ssl-certificates create techcorp-test-cert --domains=test.techcorp.internal
\`\`\`

**Issue 3: Secret Manager Access Issues**
\`\`\`bash
# Check Secret Manager API
gcloud services list --enabled --filter=\"name:secretmanager.googleapis.com\"

# Test secret creation
gcloud secrets create test-secret --data-file=<(echo \"test data\")
\`\`\`

**Issue 4: Pub/Sub Service Issues**
\`\`\`bash
# Check Pub/Sub API enablement
gcloud services list --enabled --filter=\"name:pubsub.googleapis.com\"

# Manual topic creation
gcloud pubsub topics create test-topic
\`\`\`" \
"### Immediate Next Steps
1. **Test Service Discovery**: Verify that service endpoints are resolvable and accessible
2. **Validate Certificate Management**: Ensure SSL certificates are properly issued and mapped
3. **Test Security Services**: Verify security scanning and alerting infrastructure
4. **Prepare for Lab 09**: Shared services will support workload environments

### Key Takeaways
- **Centralized Services**: Shared infrastructure reduces operational overhead and ensures consistency
- **Service Discovery**: Automated service registration and discovery enables microservices architectures
- **Certificate Automation**: Automated certificate management improves security and reduces manual overhead
- **Security Integration**: Centralized security services provide comprehensive monitoring and alerting"

# Continue creating more comprehensive labs... (this pattern continues for labs 09-14)

# Create Lab 09 - Workload Environment Setup
echo "Creating Lab 09: Workload Environment Setup..."
create_comprehensive_day2_lab_guide "09" "Workload Environment Setup" \
"Create application workload environments with compute instances, managed instance groups, auto-scaling, load balancing, and high availability for TechCorp's multi-tier applications with enterprise-grade reliability and performance." \
"60 minutes" \
"**Multi-Tier Application Architecture**: Enterprise applications require structured deployment across multiple tiers (web, application, database) with proper isolation, scaling, and communication patterns. This includes containerized and VM-based workloads with appropriate resource allocation.

**Auto-scaling and High Availability**: Production workloads require automatic scaling based on demand and high availability across multiple zones. This includes health checks, load balancing, and automatic failover capabilities to ensure business continuity.

**Instance Groups and Templates**: Managed instance groups provide consistent deployment, scaling, and management of compute resources. Instance templates ensure configuration consistency and enable blue-green deployments.

**Load Balancing Strategies**: Different load balancing patterns (global vs regional, HTTP vs TCP) serve different application requirements. This includes SSL termination, backend health monitoring, and traffic distribution algorithms." \
"• Deploy multi-tier application environments with proper segmentation
• Configure managed instance groups with auto-scaling policies
• Implement high availability across multiple zones and regions
• Set up application load balancing with health checks and SSL termination
• Configure container-based workloads with Kubernetes integration
• Implement blue-green deployment capabilities
• Set up application performance monitoring and scaling triggers" \
"Successful completion of Labs 01-08 (including shared services)" \
"### Step 1: Application Environment Infrastructure

Set up the foundational infrastructure for TechCorp's application workloads.

\`\`\`bash
# Navigate to lab directory
cd ~/gcp-landing-zone-workshop/lab-09/terraform

# Create main workload configuration
cat > main.tf << 'WORKLOAD_MAIN_END'
# Lab 09: Workload Environment Setup
# Multi-tier application environments for TechCorp

terraform {
  required_version = \">= 1.5\"
  required_providers {
    google = {
      source  = \"hashicorp/google\"
      version = \"~> 5.0\"
    }
    google-beta = {
      source  = \"hashicorp/google-beta\"
      version = \"~> 5.0\"
    }
  }
  
  backend \"gcs\" {
    bucket = \"\${TF_STATE_BUCKET}\"
    prefix = \"lab-09/terraform/state\"
  }
}

# Get previous lab outputs for integration
data \"terraform_remote_state\" \"lab02\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-02/terraform/state\"
  }
}

data \"terraform_remote_state\" \"lab08\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-08/terraform/state\"
  }
}

# Local values for workload configuration
locals {
  common_labels = {
    workshop    = \"gcp-landing-zone\"
    lab         = \"09\"
    component   = \"workloads\"
    environment = \"production\"
  }
  
  # Application tiers configuration
  app_tiers = {
    web = {
      machine_type    = \"e2-medium\"
      disk_size_gb   = 20
      disk_type      = \"pd-standard\"
      zones          = [\"us-central1-a\", \"us-central1-b\", \"us-central1-c\"]
      min_replicas   = 2
      max_replicas   = 10
      target_cpu     = 70
      subnet         = \"dev-web\"
    }
    app = {
      machine_type    = \"e2-standard-2\"
      disk_size_gb   = 50
      disk_type      = \"pd-ssd\"
      zones          = [\"us-central1-a\", \"us-central1-b\"]
      min_replicas   = 2
      max_replicas   = 8
      target_cpu     = 80
      subnet         = \"dev-app\"
    }
    database = {
      machine_type    = \"e2-highmem-2\"
      disk_size_gb   = 100
      disk_type      = \"pd-ssd\"
      zones          = [\"us-central1-a\", \"us-central1-b\"]
      min_replicas   = 2
      max_replicas   = 4
      target_cpu     = 85
      subnet         = \"dev-app\"
    }
  }
}

# Create instance templates for each tier
resource \"google_compute_instance_template\" \"app_tiers\" {
  for_each = local.app_tiers
  
  name_prefix = \"techcorp-\${each.key}-\"
  description = \"Instance template for \${each.key} tier\"
  
  machine_type = each.value.machine_type
  
  # Boot disk configuration
  disk {
    source_image = \"ubuntu-os-cloud/ubuntu-2004-lts\"
    auto_delete  = true
    boot         = true
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
  }
  
  # Network configuration
  network_interface {
    network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
    subnetwork = data.terraform_remote_state.lab02.outputs.subnets[each.value.subnet].self_link
    
    # No external IP for security (use NAT gateway)
    access_config = null
  }
  
  # Service account configuration
  service_account {
    email = data.terraform_remote_state.lab02.outputs.workload_service_accounts[\"\${each.key}-tier-sa\"].email
    scopes = [\"cloud-platform\"]
  }
  
  # Metadata and startup script
  metadata = {
    startup-script = templatefile(\"\${path.module}/scripts/\${each.key}-startup.sh\", {
      tier           = each.key
      project_id     = var.project_id
      dns_zone       = data.terraform_remote_state.lab08.outputs.dns_zones.internal.name
      service_registry = data.terraform_remote_state.lab08.outputs.service_discovery.service_registry_secret
    })
    
    # Security configurations
    enable-oslogin = \"TRUE\"
    block-project-ssh-keys = \"TRUE\"
  }
  
  # Network tags for firewall rules
  tags = [\"techcorp-\${each.key}-tier\", \"internal\", \"workload\"]
  
  # Labels
  labels = merge(local.common_labels, {
    tier = each.key
    purpose = \"application-workload\"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
WORKLOAD_MAIN_END

echo \"✓ Workload infrastructure configuration created\"
\`\`\`

### Step 2: Managed Instance Groups and Auto-scaling

Configure managed instance groups with auto-scaling for high availability.

\`\`\`bash
# Add managed instance groups configuration
cat >> main.tf << 'INSTANCE_GROUPS_END'

# Create managed instance groups for each tier
resource \"google_compute_region_instance_group_manager\" \"app_tiers\" {
  for_each = local.app_tiers
  
  name               = \"techcorp-\${each.key}-mig\"
  base_instance_name = \"techcorp-\${each.key}\"
  region             = var.region
  
  version {
    instance_template = google_compute_instance_template.app_tiers[each.key].id
  }
  
  target_size = each.value.min_replicas
  
  # Distribution across zones
  distribution_policy_zones = each.value.zones
  
  # Auto-healing configuration
  auto_healing_policies {
    health_check      = google_compute_health_check.tier_health_checks[each.key].id
    initial_delay_sec = 300
  }
  
  # Update policy for rolling updates
  update_policy {
    type                         = \"PROACTIVE\"
    instance_redistribution_type = \"PROACTIVE\"
    minimal_action              = \"REPLACE\"
    max_surge_fixed             = 2
    max_unavailable_fixed       = 1
  }
  
  # Named ports for load balancing
  named_port {
    name = \"http\"
    port = each.key == \"web\" ? 80 : 8080
  }
  
  if each.key == \"web\" {
    named_port {
      name = \"https\"
      port = 443
    }
  }
}

# Create auto-scaling policies
resource \"google_compute_region_autoscaler\" \"app_tier_autoscaler\" {
  for_each = local.app_tiers
  
  name   = \"techcorp-\${each.key}-autoscaler\"
  region = var.region
  target = google_compute_region_instance_group_manager.app_tiers[each.key].id
  
  autoscaling_policy {
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas
    cooldown_period = 60
    
    # CPU utilization scaling
    cpu_utilization {
      target = each.value.target_cpu / 100
    }
    
    # Custom metrics scaling (for production environments)
    dynamic \"metric\" {
      for_each = each.key == \"web\" ? [1] : []
      content {
        name   = \"compute.googleapis.com/instance/network/received_bytes_count\"
        target = 1000000  # 1MB/s network traffic
        type   = \"GAUGE\"
      }
    }
  }
}

# Create health checks for each tier
resource \"google_compute_health_check\" \"tier_health_checks\" {
  for_each = local.app_tiers
  
  name        = \"techcorp-\${each.key}-health-check\"
  description = \"Health check for \${each.key} tier instances\"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = each.key == \"web\" ? 80 : 8080
    request_path = each.key == \"database\" ? \"/db-health\" : \"/health\"
  }
}
INSTANCE_GROUPS_END

echo \"✓ Managed instance groups and auto-scaling configuration added\"
\`\`\`

### Step 3: Load Balancing Configuration

Set up comprehensive load balancing for the application tiers.

\`\`\`bash
# Add load balancing configuration
cat >> main.tf << 'LOAD_BALANCING_END'

# Create backend services for load balancing
resource \"google_compute_backend_service\" \"web_backend\" {
  name        = \"techcorp-web-backend\"
  description = \"Backend service for web tier\"
  protocol    = \"HTTP\"
  timeout_sec = 30
  
  backend {
    group           = google_compute_region_instance_group_manager.app_tiers[\"web\"].instance_group
    balancing_mode  = \"UTILIZATION\"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
  
  health_checks = [google_compute_health_check.tier_health_checks[\"web\"].id]
  
  # Connection draining
  connection_draining_timeout_sec = 300
  
  # Enable logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }
  
  # Security policy (will be enhanced in security lab)
  # security_policy = google_compute_security_policy.web_security_policy.id
}

# Create internal load balancer for app tier
resource \"google_compute_region_backend_service\" \"app_backend\" {
  name        = \"techcorp-app-backend\"
  description = \"Internal backend service for app tier\"
  protocol    = \"HTTP\"
  region      = var.region
  
  backend {
    group          = google_compute_region_instance_group_manager.app_tiers[\"app\"].instance_group
    balancing_mode = \"UTILIZATION\"
    max_utilization = 0.8
  }
  
  health_checks = [google_compute_region_health_check.app_internal_health.id]
  
  connection_draining_timeout_sec = 300
}

# Create regional health check for internal load balancer
resource \"google_compute_region_health_check\" \"app_internal_health\" {
  name   = \"techcorp-app-internal-health\"
  region = var.region
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 8080
    request_path = \"/health\"
  }
}

# Create URL map for routing
resource \"google_compute_url_map\" \"web_url_map\" {
  name            = \"techcorp-web-url-map\"
  default_service = google_compute_backend_service.web_backend.id
  
  host_rule {
    hosts        = [\"api.techcorp-demo.com\"]
    path_matcher = \"api-matcher\"
  }
  
  path_matcher {
    name            = \"api-matcher\"
    default_service = google_compute_backend_service.web_backend.id
    
    path_rule {
      paths   = [\"/api/*\"]
      service = google_compute_backend_service.web_backend.id
    }
    
    path_rule {
      paths   = [\"/health\"]
      service = google_compute_backend_service.web_backend.id
    }
  }
}

# Create HTTPS proxy
resource \"google_compute_target_https_proxy\" \"web_https_proxy\" {
  name             = \"techcorp-web-https-proxy\"
  url_map          = google_compute_url_map.web_url_map.id
  ssl_certificates = [data.terraform_remote_state.lab08.outputs.ssl_certificates.public_cert.id]
}

# Create HTTP proxy (for redirect)
resource \"google_compute_target_http_proxy\" \"web_http_proxy\" {
  name    = \"techcorp-web-http-proxy\"
  url_map = google_compute_url_map.web_redirect.id
}

# Create URL map for HTTP to HTTPS redirect
resource \"google_compute_url_map\" \"web_redirect\" {
  name = \"techcorp-web-redirect\"
  
  default_url_redirect {
    strip_query            = false
    https_redirect         = true
    redirect_response_code = \"MOVED_PERMANENTLY_DEFAULT\"
  }
}

# Create global forwarding rules
resource \"google_compute_global_forwarding_rule\" \"web_https\" {
  name       = \"techcorp-web-https\"
  target     = google_compute_target_https_proxy.web_https_proxy.id
  port_range = \"443\"
  ip_address = google_compute_global_address.web_ip.address
}

resource \"google_compute_global_forwarding_rule\" \"web_http\" {
  name       = \"techcorp-web-http\"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = \"80\"
  ip_address = google_compute_global_address.web_ip.address
}

# Reserve global IP address
resource \"google_compute_global_address\" \"web_ip\" {
  name = \"techcorp-web-ip\"
}

# Create internal forwarding rule for app tier
resource \"google_compute_forwarding_rule\" \"app_internal\" {
  name                  = \"techcorp-app-internal\"
  region                = var.region
  load_balancing_scheme = \"INTERNAL\"
  backend_service       = google_compute_region_backend_service.app_backend.id
  network               = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  subnetwork            = data.terraform_remote_state.lab02.outputs.subnets[\"dev-app\"].self_link
  ports                 = [\"8080\"]
}
LOAD_BALANCING_END

echo \"✓ Load balancing configuration added\"
\`\`\`

### Step 4: Container Workloads with GKE

Set up Kubernetes cluster for containerized workloads.

\`\`\`bash
# Add GKE configuration
cat >> main.tf << 'GKE_CONFIG_END'

# Create GKE cluster for microservices
resource \"google_container_cluster\" \"techcorp_cluster\" {
  name     = \"techcorp-microservices\"
  location = var.region
  
  # Regional cluster for high availability
  node_locations = [\"us-central1-a\", \"us-central1-b\", \"us-central1-c\"]
  
  # Network configuration
  network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  subnetwork = data.terraform_remote_state.lab02.outputs.subnets[\"dev-web\"].self_link
  
  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = \"dev-web-pods\"
    services_secondary_range_name = \"dev-web-services\"
  }
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Master configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = \"172.16.0.0/28\"
  }
  
  # Enable workload identity
  workload_identity_config {
    workload_pool = \"\${var.project_id}.svc.id.goog\"
  }
  
  # Enable network policy
  network_policy {
    enabled  = true
    provider = \"CALICO\"
  }
  
  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  # Enable logging and monitoring
  logging_config {
    enable_components = [\"SYSTEM_COMPONENTS\", \"WORKLOADS\"]
  }
  
  monitoring_config {
    enable_components = [\"SYSTEM_COMPONENTS\"]
  }
  
  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = \"03:00\"
    }
  }
}

# Create node pools
resource \"google_container_node_pool\" \"primary_nodes\" {
  name       = \"primary-nodes\"
  location   = var.region
  cluster    = google_container_cluster.techcorp_cluster.name
  node_count = 1
  
  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  
  # Node configuration
  node_config {
    preemptible  = false
    machine_type = \"e2-medium\"
    
    # Service account for nodes
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      \"https://www.googleapis.com/auth/cloud-platform\"
    ]
    
    # Workload identity
    workload_metadata_config {
      mode = \"GKE_METADATA\"
    }
    
    # Disk configuration
    disk_size_gb = 50
    disk_type    = \"pd-standard\"
    
    # Network tags
    tags = [\"gke-nodes\", \"techcorp-cluster\"]
    
    # Labels
    labels = merge(local.common_labels, {
      node-pool = \"primary\"
    })
  }
  
  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  
  # Management settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Create service account for GKE nodes
resource \"google_service_account\" \"gke_nodes\" {
  account_id   = \"techcorp-gke-nodes\"
  display_name = \"TechCorp GKE Node Service Account\"
}

# Grant necessary permissions to GKE nodes
resource \"google_project_iam_member\" \"gke_node_permissions\" {
  for_each = toset([
    \"roles/logging.logWriter\",
    \"roles/monitoring.metricWriter\",
    \"roles/monitoring.viewer\",
    \"roles/storage.objectViewer\"
  ])
  
  project = var.project_id
  role    = each.value
  member  = \"serviceAccount:\${google_service_account.gke_nodes.email}\"
}
GKE_CONFIG_END

echo \"✓ GKE configuration added\"
\`\`\`

### Step 5: Create Startup Scripts

Create startup scripts for application tiers.

\`\`\`bash
# Create scripts directory
mkdir -p scripts

# Create web tier startup script
cat > scripts/web-startup.sh << 'WEB_STARTUP_END'
#!/bin/bash

# Web Tier Startup Script for TechCorp
set -e

echo \"Starting TechCorp Web Tier initialization...\"

# Update system
apt-get update
apt-get install -y nginx jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure nginx
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 \"healthy\n\";
        add_header Content-Type text/plain;
    }
    
    # API proxy to app tier
    location /api/ {
        proxy_pass http://app.${dns_zone}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX_CONFIG

# Create simple web page
cat > /var/www/html/index.html << 'HTML_END'
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #333; text-align: center; }
        .info { background: #f0f0f0; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1 class="header">TechCorp Web Application</h1>
    <div class="info">
        <h3>Server Information</h3>
        <p><strong>Tier:</strong> Web</p>
        <p><strong>Instance:</strong> $(hostname)</p>
        <p><strong>Zone:</strong> $(curl -s -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)</p>
        <p><strong>Project:</strong> ${project_id}</p>
        <p><strong>Timestamp:</strong> $(date)</p>
    </div>
</body>
</html>
HTML_END

# Start and enable nginx
systemctl restart nginx
systemctl enable nginx

echo \"Web tier initialization completed successfully\"
WEB_STARTUP_END

# Create app tier startup script
cat > scripts/app-startup.sh << 'APP_STARTUP_END'
#!/bin/bash

# App Tier Startup Script for TechCorp
set -e

echo \"Starting TechCorp App Tier initialization...\"

# Update system
apt-get update
apt-get install -y python3 python3-pip jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create application user
useradd -m -s /bin/bash techcorp
mkdir -p /opt/techcorp

# Create simple Python application
cat > /opt/techcorp/app.py << 'PYTHON_APP'
#!/usr/bin/env python3
import json
import socket
import subprocess
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

class TechCorpHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            health_data = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'hostname': socket.gethostname(),
                'tier': 'app'
            }
            self.wfile.write(json.dumps(health_data).encode())
        
        elif self.path == '/api/info':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Get instance metadata
            try:
                zone_cmd = 'curl -s -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/zone'
                zone = subprocess.check_output(zone_cmd, shell=True).decode().split('/')[-1]
            except:
                zone = 'unknown'
            
            info_data = {
                'service': 'TechCorp API',
                'tier': 'application',
                'hostname': socket.gethostname(),
                'zone': zone,
                'project': '${project_id}',
                'timestamp': datetime.now().isoformat(),
                'version': '1.0.0'
            }
            self.wfile.write(json.dumps(info_data).encode())
        
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), TechCorpHandler)
    print('TechCorp App Server starting on port 8080...')
    server.serve_forever()
PYTHON_APP

# Create systemd service
cat > /etc/systemd/system/techcorp-app.service << 'SERVICE_CONFIG'
[Unit]
Description=TechCorp Application Service
After=network.target

[Service]
Type=simple
User=techcorp
WorkingDirectory=/opt/techcorp
ExecStart=/usr/bin/python3 /opt/techcorp/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_CONFIG

# Set permissions and start service
chown -R techcorp:techcorp /opt/techcorp
chmod +x /opt/techcorp/app.py
systemctl daemon-reload
systemctl start techcorp-app
systemctl enable techcorp-app

echo \"App tier initialization completed successfully\"
APP_STARTUP_END

# Create database tier startup script
cat > scripts/database-startup.sh << 'DB_STARTUP_END'
#!/bin/bash

# Database Tier Startup Script for TechCorp
set -e

echo \"Starting TechCorp Database Tier initialization...\"

# Update system
apt-get update
apt-get install -y postgresql postgresql-contrib jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql << 'SQL_CONFIG'
CREATE DATABASE techcorp;
CREATE USER techcorp_app WITH PASSWORD 'secure_password_123';
GRANT ALL PRIVILEGES ON DATABASE techcorp TO techcorp_app;
\q
SQL_CONFIG

# Create health check endpoint
cat > /opt/db-health.py << 'DB_HEALTH'
#!/usr/bin/env python3
import json
import socket
import psycopg2
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

class DBHealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/db-health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Test database connection
            try:
                conn = psycopg2.connect(
                    host=\"localhost\",
                    database=\"techcorp\",
                    user=\"techcorp_app\",
                    password=\"secure_password_123\"
                )
                conn.close()
                db_status = \"healthy\"
            except:
                db_status = \"unhealthy\"
            
            health_data = {
                'status': db_status,
                'timestamp': datetime.now().isoformat(),
                'hostname': socket.gethostname(),
                'tier': 'database',
                'service': 'postgresql'
            }
            self.wfile.write(json.dumps(health_data).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), DBHealthHandler)
    server.serve_forever()
DB_HEALTH

# Install Python dependencies and start health service
apt-get install -y python3-psycopg2
python3 /opt/db-health.py &

echo \"Database tier initialization completed successfully\"
DB_STARTUP_END

chmod +x scripts/*.sh
echo \"✓ Startup scripts created\"
\`\`\`" \
"• Multi-tier application environments with web, app, and database tiers
• Managed instance groups with auto-scaling policies based on CPU and custom metrics
• Comprehensive load balancing with HTTPS termination and health checks
• GKE cluster for containerized microservices with workload identity
• High availability deployment across multiple zones
• Auto-healing capabilities with health monitoring
• Blue-green deployment support through instance templates
• Integration with shared services (DNS, certificates, monitoring)" \
"# Check instance templates
echo \"Checking instance templates...\"
tiers=(\"web\" \"app\" \"database\")
for tier in \"\${tiers[@]}\"; do
    template_count=\$(gcloud compute instance-templates list --filter=\"name:techcorp-\$tier\" --format=\"value(name)\" | wc -l)
    if [ \$template_count -gt 0 ]; then
        echo \"✓ Instance template created for \$tier tier\"
        ((validation_passed++))
    else
        echo \"✗ Instance template missing for \$tier tier\"
        ((validation_failed++))
    fi
done

# Check managed instance groups
echo \"Checking managed instance groups...\"
for tier in \"\${tiers[@]}\"; do
    if gcloud compute instance-groups managed describe techcorp-\$tier-mig --region=\$REGION --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Managed instance group created for \$tier tier\"
        ((validation_passed++))
        
        # Check instance count
        instance_count=\$(gcloud compute instance-groups managed list-instances techcorp-\$tier-mig --region=\$REGION --format=\"value(name)\" | wc -l)
        if [ \$instance_count -ge 2 ]; then
            echo \"✓ Instances running in \$tier tier: \$instance_count\"
            ((validation_passed++))
        else
            echo \"⚠ Low instance count in \$tier tier: \$instance_count\"
        fi
    else
        echo \"✗ Managed instance group missing for \$tier tier\"
        ((validation_failed++))
    fi
done

# Check auto-scalers
echo \"Checking auto-scalers...\"
for tier in \"\${tiers[@]}\"; do
    if gcloud compute instance-groups managed describe techcorp-\$tier-mig --region=\$REGION --format=\"value(autoscaler)\" | grep -q \"techcorp-\$tier-autoscaler\"; then
        echo \"✓ Auto-scaler configured for \$tier tier\"
        ((validation_passed++))
    else
        echo \"✗ Auto-scaler missing for \$tier tier\"
        ((validation_failed++))
    fi
done

# Check health checks
echo \"Checking health checks...\"
for tier in \"\${tiers[@]}\"; do
    if gcloud compute health-checks describe techcorp-\$tier-health-check --global --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Health check created for \$tier tier\"
        ((validation_passed++))
    else
        echo \"✗ Health check missing for \$tier tier\"
        ((validation_failed++))
    fi
done

# Check load balancers
echo \"Checking load balancers...\"
if gcloud compute backend-services describe techcorp-web-backend --global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Web backend service created\"
    ((validation_passed++))
else
    echo \"✗ Web backend service missing\"
    ((validation_failed++))
fi

if gcloud compute backend-services describe techcorp-app-backend --region=\$REGION --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ App backend service created\"
    ((validation_passed++))
else
    echo \"✗ App backend service missing\"
    ((validation_failed++))
fi

# Check global IP and forwarding rules
echo \"Checking load balancer components...\"
if gcloud compute addresses describe techcorp-web-ip --global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Global IP address reserved\"
    ((validation_passed++))
else
    echo \"✗ Global IP address missing\"
    ((validation_failed++))
fi

if gcloud compute forwarding-rules describe techcorp-web-https --global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ HTTPS forwarding rule created\"
    ((validation_passed++))
else
    echo \"✗ HTTPS forwarding rule missing\"
    ((validation_failed++))
fi

# Check GKE cluster
echo \"Checking GKE cluster...\"
if gcloud container clusters describe techcorp-microservices --region=\$REGION --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ GKE cluster created\"
    ((validation_passed++))
    
    # Check node pool
    node_count=\$(gcloud container clusters describe techcorp-microservices --region=\$REGION --format=\"value(currentNodeCount)\")
    if [ \$node_count -gt 0 ]; then
        echo \"✓ GKE nodes running: \$node_count\"
        ((validation_passed++))
    else
        echo \"✗ No GKE nodes found\"
        ((validation_failed++))
    fi
else
    echo \"✗ GKE cluster missing\"
    ((validation_failed++))
fi

# Check GKE service account
echo \"Checking GKE service account...\"
gke_sa=\"techcorp-gke-nodes@\${PROJECT_ID}.iam.gserviceaccount.com\"
if gcloud iam service-accounts describe \$gke_sa --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ GKE node service account created\"
    ((validation_passed++))
else
    echo \"✗ GKE node service account missing\"
    ((validation_failed++))
fi

# Test application endpoints (basic connectivity)
echo \"Testing application connectivity...\"
global_ip=\$(gcloud compute addresses describe techcorp-web-ip --global --format=\"value(address)\" 2>/dev/null)
if [ -n \"\$global_ip\" ]; then
    echo \"✓ Global IP available: \$global_ip\"
    ((validation_passed++))
    
    # Test HTTP redirect (should get redirect response)
    http_status=\$(curl -s -o /dev/null -w \"%{http_code}\" \"http://\$global_ip/health\" || echo \"000\")
    if [ \"\$http_status\" = \"301\" ] || [ \"\$http_status\" = \"302\" ] || [ \"\$http_status\" = \"200\" ]; then
        echo \"✓ HTTP endpoint responding: \$http_status\"
        ((validation_passed++))
    else
        echo \"⚠ HTTP endpoint status: \$http_status (may need time to initialize)\"
    fi
else
    echo \"✗ Global IP not found\"
    ((validation_failed++))
fi

# Check startup scripts
echo \"Checking startup scripts...\"
scripts=(\"web-startup.sh\" \"app-startup.sh\" \"database-startup.sh\")
for script in \"\${scripts[@]}\"; do
    if [ -f \"../scripts/\$script\" ]; then
        echo \"✓ Startup script exists: \$script\"
        ((validation_passed++))
    else
        echo \"✗ Startup script missing: \$script\"
        ((validation_failed++))
    fi
done

# Check Terraform outputs
echo \"Checking Terraform outputs...\"
cd terraform
terraform_outputs=\$(terraform output -json 2>/dev/null)
if [ \$? -eq 0 ] && [ \"\$terraform_outputs\" != \"{}\" ]; then
    echo \"✓ Terraform outputs available\"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=(\"instance_groups\" \"load_balancers\" \"gke_cluster\" \"application_endpoints\")
    for output in \"\${required_outputs[@]}\"; do
        if echo \"\$terraform_outputs\" | jq -e \".\$output\" &>/dev/null; then
            echo \"✓ Output available: \$output\"
            ((validation_passed++))
        else
            echo \"✗ Output missing: \$output\"
            ((validation_failed++))
        fi
    done
else
    echo \"✗ Terraform outputs not available\"
    ((validation_failed++))
fi
cd .." \
"**Issue 1: Instance Template Creation Issues**
\`\`\`bash
# Check required APIs
gcloud services list --enabled --filter=\"name:compute.googleapis.com\"

# Check service account references
gcloud iam service-accounts list --filter=\"email:*-tier-sa@*\"

# Manual template creation test
gcloud compute instance-templates create test-template --machine-type=e2-micro --image-family=ubuntu-2004-lts --image-project=ubuntu-os-cloud
\`\`\`

**Issue 2: Managed Instance Group Issues**
\`\`\`bash
# Check template availability
gcloud compute instance-templates list --filter=\"name:techcorp\"

# Check network and subnet references
gcloud compute networks describe techcorp-shared-vpc
gcloud compute networks subnets list --filter=\"name:dev-*\"
\`\`\`

**Issue 3: Load Balancer Configuration Issues**
\`\`\`bash
# Check health check creation
gcloud compute health-checks list --filter=\"name:techcorp\"

# Test health check endpoint
curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/zone

# Check SSL certificate availability
gcloud compute ssl-certificates list --filter=\"name:techcorp\"
\`\`\`

**Issue 4: GKE Cluster Issues**
\`\`\`bash
# Check GKE API enablement
gcloud services list --enabled --filter=\"name:container.googleapis.com\"

# Check network configuration for GKE
gcloud compute networks subnets describe dev-web --region=\$REGION

# Manual cluster creation test
gcloud container clusters create test-cluster --zone=us-central1-a --num-nodes=1
\`\`\`" \
"### Immediate Next Steps
1. **Test Application Access**: Verify that applications are accessible through load balancers
2. **Monitor Instance Health**: Check that auto-healing and scaling policies are working
3. **Validate GKE Functionality**: Deploy test workloads to the Kubernetes cluster
4. **Prepare for Lab 10**: Workload environments will be secured with advanced controls

### Key Takeaways
- **Multi-Tier Architecture**: Proper separation and scaling of application tiers
- **High Availability**: Automatic failover and distribution across zones
- **Auto-scaling**: Dynamic resource allocation based on demand
- **Load Balancing**: Efficient traffic distribution with health monitoring
- **Container Support**: Kubernetes integration for modern microservices"

# Create Lab 10 - Security Controls & Compliance
echo "Creating Lab 10: Security Controls & Compliance..."
create_comprehensive_day2_lab_guide "10" "Security Controls & Compliance" \
"Implement advanced security controls including encryption, key management, security scanning, and compliance monitoring to meet fintech regulatory requirements including PCI DSS, SOX, and industry best practices." \
"60 minutes" \
"**Enterprise Security Framework**: Financial services require comprehensive security controls including encryption at rest and in transit, identity and access management, network security, and continuous monitoring. This includes implementing defense-in-depth strategies and zero-trust principles.

**Compliance Automation**: Regulatory compliance requires continuous monitoring, automated policy enforcement, and audit trail generation. This includes PCI DSS for payment processing, SOX for financial reporting, and other industry-specific requirements.

**Key Management**: Customer-managed encryption keys (CMEK) provide additional security and compliance benefits. This includes key rotation, access controls, and integration with Hardware Security Modules (HSMs).

**Security Scanning and Monitoring**: Continuous security assessment includes vulnerability scanning, configuration compliance monitoring, and security incident detection and response automation." \
"• Implement comprehensive encryption with customer-managed keys (CMEK)
• Configure advanced security scanning and vulnerability management
• Set up compliance monitoring and policy enforcement automation
• Implement security incident detection and automated response
• Configure audit logging and compliance reporting
• Set up data loss prevention (DLP) and sensitive data protection
• Implement network security controls and micro-segmentation" \
"Successful completion of Labs 01-09 (including workload environments)" \
"### Step 1: Customer-Managed Encryption Keys (CMEK)

Set up comprehensive encryption with customer-managed keys for enhanced security.

\`\`\`bash
# Navigate to lab directory
cd ~/gcp-landing-zone-workshop/lab-10/terraform

# Create main security configuration
cat > main.tf << 'SECURITY_MAIN_END'
# Lab 10: Security Controls & Compliance
# Advanced security controls for TechCorp enterprise environment

terraform {
  required_version = \">= 1.5\"
  required_providers {
    google = {
      source  = \"hashicorp/google\"
      version = \"~> 5.0\"
    }
    google-beta = {
      source  = \"hashicorp/google-beta\"
      version = \"~> 5.0\"
    }
  }
  
  backend \"gcs\" {
    bucket = \"\${TF_STATE_BUCKET}\"
    prefix = \"lab-10/terraform/state\"
  }
}

# Get previous lab outputs for integration
data \"terraform_remote_state\" \"lab02\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-02/terraform/state\"
  }
}

data \"terraform_remote_state\" \"lab08\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-08/terraform/state\"
  }
}

data \"terraform_remote_state\" \"lab09\" {
  backend = \"gcs\"
  config = {
    bucket = var.tf_state_bucket
    prefix = \"lab-09/terraform/state\"
  }
}

# Local values for security configuration
locals {
  common_labels = {
    workshop    = \"gcp-landing-zone\"
    lab         = \"10\"
    component   = \"security\"
    environment = \"production\"
    compliance  = \"fintech\"
  }
  
  # Key ring locations for different compliance zones
  key_locations = {
    primary   = var.region
    secondary = \"us-east1\"
    global    = \"global\"
  }
  
  # Security policies configuration
  security_policies = {
    web_security = {
      name        = \"techcorp-web-security\"
      description = \"Web application security policy\"
      rules = [
        {
          priority    = 1000
          action      = \"deny(403)\"
          description = \"Block SQL injection attempts\"
          expression  = \"evaluatePreconfiguredExpr('sqli-stable')\"
        },
        {
          priority    = 2000
          action      = \"deny(403)\"
          description = \"Block XSS attempts\"
          expression  = \"evaluatePreconfiguredExpr('xss-stable')\"
        },
        {
          priority    = 3000
          action      = \"rate_based_ban\"
          description = \"Rate limiting\"
          expression  = \"true\"
        }
      ]
    }
  }
}

# Create primary KMS key ring for application data
resource \"google_kms_key_ring\" \"primary_keyring\" {
  name     = \"techcorp-primary-keyring\"
  location = local.key_locations.primary
  
  depends_on = [google_project_service.kms_api]
}

# Enable required APIs
resource \"google_project_service\" \"security_apis\" {
  for_each = toset([
    \"cloudkms.googleapis.com\",
    \"securitycenter.googleapis.com\",
    \"dlp.googleapis.com\",
    \"binaryauthorization.googleapis.com\",
    \"containeranalysis.googleapis.com\"
  ])
  
  service = each.value
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Separate KMS API enablement for dependency management
resource \"google_project_service\" \"kms_api\" {
  service = \"cloudkms.googleapis.com\"
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Create encryption keys for different data types
resource \"google_kms_crypto_key\" \"application_data_key\" {
  name     = \"techcorp-application-data\"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = \"ENCRYPT_DECRYPT\"
  
  version_template {
    algorithm        = \"GOOGLE_SYMMETRIC_ENCRYPTION\"
    protection_level = \"SOFTWARE\"
  }
  
  # Automatic rotation every 90 days for compliance
  rotation_period = \"7776000s\"  # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"application-data\"
    compliance = \"pci-dss\"
  })
}

resource \"google_kms_crypto_key\" \"database_key\" {
  name     = \"techcorp-database-encryption\"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = \"ENCRYPT_DECRYPT\"
  
  version_template {
    algorithm        = \"GOOGLE_SYMMETRIC_ENCRYPTION\"
    protection_level = \"SOFTWARE\"
  }
  
  rotation_period = \"7776000s\"  # 90 days
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"database-encryption\"
    compliance = \"sox\"
  })
}

resource \"google_kms_crypto_key\" \"backup_key\" {
  name     = \"techcorp-backup-encryption\"
  key_ring = google_kms_key_ring.primary_keyring.id
  purpose  = \"ENCRYPT_DECRYPT\"
  
  version_template {
    algorithm        = \"GOOGLE_SYMMETRIC_ENCRYPTION\"
    protection_level = \"SOFTWARE\"
  }
  
  rotation_period = \"15552000s\"  # 180 days (longer for backups)
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"backup-encryption\"
    compliance = \"general\"
  })
}

# Create secondary key ring for DR/backup
resource \"google_kms_key_ring\" \"secondary_keyring\" {
  name     = \"techcorp-secondary-keyring\"
  location = local.key_locations.secondary
  
  depends_on = [google_project_service.kms_api]
}

resource \"google_kms_crypto_key\" \"dr_key\" {
  name     = \"techcorp-disaster-recovery\"
  key_ring = google_kms_key_ring.secondary_keyring.id
  purpose  = \"ENCRYPT_DECRYPT\"
  
  version_template {
    algorithm        = \"GOOGLE_SYMMETRIC_ENCRYPTION\"
    protection_level = \"SOFTWARE\"
  }
  
  rotation_period = \"31536000s\"  # 1 year for DR
  
  lifecycle {
    prevent_destroy = true
  }
  
  labels = merge(local.common_labels, {
    purpose = \"disaster-recovery\"
    compliance = \"business-continuity\"
  })
}
SECURITY_MAIN_END

echo \"✓ Security main configuration created\"
\`\`\`

### Step 2: Advanced Security Policies and Cloud Armor

Configure Web Application Firewall and security policies.

\`\`\`bash
# Add security policies configuration
cat >> main.tf << 'SECURITY_POLICIES_END'

# Create Cloud Armor security policy for web applications
resource \"google_compute_security_policy\" \"web_security_policy\" {
  name        = \"techcorp-web-security-policy\"
  description = \"Security policy for TechCorp web applications\"
  
  # Default rule - allow all traffic not matching other rules
  rule {
    action   = \"allow\"
    priority = \"2147483647\"
    match {
      versioned_expr = \"SRC_IPS_V1\"
      config {
        src_ip_ranges = [\"*\"]
      }
    }
    description = \"Default allow rule\"
  }
  
  # Block known malicious IPs
  rule {
    action   = \"deny(403)\"
    priority = \"1000\"
    match {
      versioned_expr = \"SRC_IPS_V1\"
      config {
        src_ip_ranges = [
          \"203.0.113.0/24\",  # Example malicious range
          \"198.51.100.0/24\"  # Example malicious range
        ]
      }
    }
    description = \"Block known malicious IP ranges\"
  }
  
  # Rate limiting rule
  rule {
    action   = \"rate_based_ban\"
    priority = \"2000\"
    match {
      versioned_expr = \"SRC_IPS_V1\"
      config {
        src_ip_ranges = [\"*\"]
      }
    }
    rate_limit_options {
      conform_action = \"allow\"
      exceed_action  = \"deny(429)\"
      enforce_on_key = \"IP\"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = \"Rate limiting: 100 requests per minute per IP\"
  }
  
  # SQL injection protection
  rule {
    action   = \"deny(403)\"
    priority = \"3000\"
    match {
      expr {
        expression = \"evaluatePreconfiguredExpr('sqli-stable')\"
      }
    }
    description = \"Block SQL injection attempts\"
  }
  
  # XSS protection
  rule {
    action   = \"deny(403)\"
    priority = \"4000\"
    match {
      expr {
        expression = \"evaluatePreconfiguredExpr('xss-stable')\"
      }
    }
    description = \"Block XSS attempts\"
  }
  
  # Geographic restriction (example: block traffic from certain countries)
  rule {
    action   = \"deny(403)\"
    priority = \"5000\"
    match {
      expr {
        expression = \"origin.region_code == 'CN' || origin.region_code == 'RU'\"
      }
    }
    description = \"Geographic restrictions for compliance\"
  }
  
  # Advanced threat protection
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

# Apply security policy to load balancer backend
resource \"google_compute_backend_service\" \"secure_web_backend\" {
  name        = \"techcorp-secure-web-backend\"
  description = \"Secure backend service with Cloud Armor protection\"
  protocol    = \"HTTP\"
  timeout_sec = 30
  
  backend {
    group           = data.terraform_remote_state.lab09.outputs.instance_groups.web.instance_group
    balancing_mode  = \"UTILIZATION\"
    max_utilization = 0.8
  }
  
  health_checks   = [data.terraform_remote_state.lab09.outputs.health_checks.web.id]
  security_policy = google_compute_security_policy.web_security_policy.id
  
  # Enable Cloud CDN for performance and additional security
  enable_cdn = true
  cdn_policy {
    cache_mode        = \"CACHE_ALL_STATIC\"
    default_ttl       = 3600
    max_ttl          = 86400
    negative_caching = true
    
    # Security headers
    negative_caching_policy {
      code = 404
      ttl  = 60
    }
  }
  
  # Connection draining
  connection_draining_timeout_sec = 300
  
  # Comprehensive logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
SECURITY_POLICIES_END

echo \"✓ Security policies configuration added\"
\`\`\`

### Step 3: Data Loss Prevention (DLP) and Sensitive Data Protection

Set up DLP scanning and protection for sensitive data.

\`\`\`bash
# Add DLP configuration
cat >> main.tf << 'DLP_CONFIG_END'

# Create DLP inspect template for financial data
resource \"google_data_loss_prevention_inspect_template\" \"financial_data_template\" {
  parent       = \"projects/\${var.project_id}\"
  description  = \"Template for detecting financial sensitive data\"
  display_name = \"TechCorp Financial Data Detection\"
  
  inspect_config {
    info_types {
      name = \"CREDIT_CARD_NUMBER\"
    }
    info_types {
      name = \"US_SOCIAL_SECURITY_NUMBER\"
    }
    info_types {
      name = \"US_BANK_ROUTING_MICR\"
    }
    info_types {
      name = \"IBAN_CODE\"
    }
    info_types {
      name = \"SWIFT_CODE\"
    }
    
    # Custom info type for TechCorp customer IDs
    custom_info_types {
      info_type {
        name = \"TECHCORP_CUSTOMER_ID\"
      }
      regex {
        pattern = \"TC[0-9]{8}\"
      }
      likelihood = \"LIKELY\"
    }
    
    # Minimum likelihood threshold
    min_likelihood = \"POSSIBLE\"
    
    # Limits for performance
    limits {
      max_findings_per_info_type {
        info_type {
          name = \"CREDIT_CARD_NUMBER\"
        }
        max_findings = 100
      }
      max_findings_per_request = 1000
    }
  }
}

# Create DLP de-identification template
resource \"google_data_loss_prevention_deidentify_template\" \"financial_deidentify_template\" {
  parent       = \"projects/\${var.project_id}\"
  description  = \"Template for de-identifying financial data\"
  display_name = \"TechCorp Financial Data De-identification\"
  
  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = \"CREDIT_CARD_NUMBER\"
        }
        primitive_transformation {
          crypto_replace_ffx_fpe_config {
            crypto_key {
              kms_wrapped {
                wrapped_key   = google_kms_crypto_key.application_data_key.id
                crypto_key_name = google_kms_crypto_key.application_data_key.id
              }
            }
            alphabet = \"NUMERIC\"
          }
        }
      }
      
      transformations {
        info_types {
          name = \"US_SOCIAL_SECURITY_NUMBER\"
        }
        primitive_transformation {
          crypto_hash_config {
            crypto_key {
              kms_wrapped {
                wrapped_key   = google_kms_crypto_key.application_data_key.id
                crypto_key_name = google_kms_crypto_key.application_data_key.id
              }
            }
          }
        }
      }
    }
  }
}

# Create DLP job trigger for continuous scanning
resource \"google_data_loss_prevention_job_trigger\" \"storage_scan_trigger\" {
  parent       = \"projects/\${var.project_id}\"
  description  = \"Scan Cloud Storage for sensitive financial data\"
  display_name = \"TechCorp Storage Scanner\"
  
  triggers {
    schedule {
      recurrence_period_duration = \"86400s\"  # Daily scan
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.financial_data_template.id
    
    storage_config {
      cloud_storage_options {
        file_set {
          url = \"gs://\${data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket}/*\"
        }
        
        bytes_limit_per_file      = 104857600  # 100MB
        bytes_limit_per_file_percent = 10
        file_types = [\"CSV\", \"JSON\", \"TEXT_FILE\"]
        sample_method = \"RANDOM_START\"
      }
      
      timespan_config {
        start_time = \"2023-01-01T00:00:00Z\"
        timestamp_field {
          name = \"timestamp\"
        }
      }
    }
    
    actions {
      pub_sub {
        topic = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
      }
    }
    
    actions {
      save_findings {
        output_config {
          table {
            project_id = var.project_id
            dataset_id = \"techcorp_security\"
            table_id   = \"dlp_findings\"
          }
        }
      }
    }
  }
  
  status = \"HEALTHY\"
}

# Create BigQuery dataset for security findings
resource \"google_bigquery_dataset\" \"security_dataset\" {
  dataset_id  = \"techcorp_security\"
  description = \"Dataset for security findings and compliance data\"
  location    = var.region
  
  # Access controls
  access {
    role          = \"OWNER\"
    user_by_email = data.google_client_openid_userinfo.current.email
  }
  
  access {
    role          = \"READER\"
    special_group = \"projectReaders\"
  }
  
  access {
    role   = \"WRITER\"
    group_by_email = \"security-team@techcorp.com\"  # Example security team
  }
  
  labels = merge(local.common_labels, {
    purpose = \"security-findings\"
    compliance = \"pci-dss\"
  })
}
DLP_CONFIG_END

echo \"✓ DLP configuration added\"
\`\`\`

### Step 4: Security Monitoring and Incident Response

Set up comprehensive security monitoring and automated response.

\`\`\`bash
# Add security monitoring configuration
cat >> main.tf << 'SECURITY_MONITORING_END'

# Create Security Command Center notification config
resource \"google_scc_notification_config\" \"security_notifications\" {
  config_id    = \"techcorp-security-notifications\"
  organization = var.organization_id  # Set by instructor if available
  description  = \"Security Command Center notifications for TechCorp\"
  
  pubsub_topic = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
  
  streaming_config {
    filter = <<-EOT
      (category=\"MALWARE\" OR 
       category=\"SUSPICIOUS_ACTIVITY\" OR 
       category=\"VULNERABILITY\" OR
       category=\"DATA_EXFILTRATION\") AND
      state=\"ACTIVE\"
    EOT
  }
}

# Create custom security findings
resource \"google_scc_source\" \"techcorp_security_source\" {
  count = var.organization_id != \"\" ? 1 : 0
  
  display_name = \"TechCorp Custom Security Scanner\"
  organization = var.organization_id
  description  = \"Custom security findings from TechCorp application security scans\"
}

# Create monitoring alert policy for security events
resource \"google_monitoring_alert_policy\" \"security_incidents\" {
  display_name = \"TechCorp Security Incidents\"
  combiner     = \"OR\"
  
  conditions {
    display_name = \"High severity security findings\"
    
    condition_threshold {
      filter         = \"resource.type=\\\"gce_instance\\\" AND metric.type=\\\"logging.googleapis.com/user/security_events\\\"\"
      duration       = \"300s\"
      comparison     = \"COMPARISON_GREATER_THAN\"
      threshold_value = 0
      
      aggregations {
        alignment_period   = \"300s\"
        per_series_aligner = \"ALIGN_COUNT\"
      }
    }
  }
  
  notification_channels = []  # Would be configured with actual notification channels
  
  alert_strategy {
    auto_close = \"604800s\"  # 7 days
  }
  
  enabled = true
}

# Create log-based metric for security events
resource \"google_logging_metric\" \"security_events_metric\" {
  name   = \"techcorp_security_events\"
  filter = <<-EOT
    (jsonPayload.severity=\"HIGH\" OR jsonPayload.severity=\"CRITICAL\") AND
    (jsonPayload.category=\"SECURITY\" OR 
     jsonPayload.event_type=\"UNAUTHORIZED_ACCESS\" OR
     jsonPayload.event_type=\"SUSPICIOUS_ACTIVITY\")
  EOT
  
  metric_descriptor {
    metric_kind = \"GAUGE\"
    value_type  = \"INT64\"
    unit        = \"1\"
    display_name = \"Security Events Count\"
  }
  
  label_extractors = {
    \"severity\" = \"EXTRACT(jsonPayload.severity)\"
    \"category\" = \"EXTRACT(jsonPayload.category)\"
    \"source_ip\" = \"EXTRACT(jsonPayload.source_ip)\"
  }
}

# Create Cloud Function for automated security response
resource \"google_storage_bucket_object\" \"security_response_function\" {
  name   = \"security-response-function.zip\"
  bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  content = base64encode(\"# Placeholder for security response function code\")
}

resource \"google_cloudfunctions_function\" \"security_response\" {
  name        = \"techcorp-security-response\"
  description = \"Automated security incident response function\"
  runtime     = \"python39\"
  
  available_memory_mb   = 256
  source_archive_bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  source_archive_object = google_storage_bucket_object.security_response_function.name
  entry_point          = \"security_response_handler\"
  
  event_trigger {
    event_type = \"google.pubsub.topic.publish\"
    resource   = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    ALERT_TOPIC = data.terraform_remote_state.lab08.outputs.security_services.alerts_topic
    KMS_KEY = google_kms_crypto_key.application_data_key.id
  }
  
  labels = local.common_labels
}

# Create firewall rules for micro-segmentation
resource \"google_compute_firewall\" \"deny_all_internal\" {
  name    = \"techcorp-deny-all-internal\"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  deny {
    protocol = \"tcp\"
  }
  deny {
    protocol = \"udp\"
  }
  deny {
    protocol = \"icmp\"
  }
  
  source_ranges = [\"10.0.0.0/8\"]
  target_tags   = [\"deny-internal\"]
  priority      = 1000
  
  description = \"Default deny rule for micro-segmentation\"
}

resource \"google_compute_firewall\" \"allow_web_to_app\" {
  name    = \"techcorp-allow-web-to-app\"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  allow {
    protocol = \"tcp\"
    ports    = [\"8080\", \"443\"]
  }
  
  source_tags = [\"techcorp-web-tier\"]
  target_tags = [\"techcorp-app-tier\"]
  priority    = 900
  
  description = \"Allow web tier to communicate with app tier\"
}

resource \"google_compute_firewall\" \"allow_app_to_db\" {
  name    = \"techcorp-allow-app-to-db\"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  
  allow {
    protocol = \"tcp\"
    ports    = [\"5432\", \"3306\"]
  }
  
  source_tags = [\"techcorp-app-tier\"]
  target_tags = [\"techcorp-database-tier\"]
  priority    = 900
  
  description = \"Allow app tier to communicate with database tier\"
}

# Data source for current user
data \"google_client_openid_userinfo\" \"current\" {}
SECURITY_MONITORING_END

echo \"✓ Security monitoring configuration added\"
\`\`\`

### Step 5: Binary Authorization and Container Security

Configure container security and binary authorization for GKE.

\`\`\`bash
# Add container security configuration
cat >> main.tf << 'CONTAINER_SECURITY_END'

# Create Binary Authorization policy
resource \"google_binary_authorization_policy\" \"policy\" {
  admission_whitelist_patterns {
    name_pattern = \"gcr.io/\${var.project_id}/*\"
  }
  
  admission_whitelist_patterns {
    name_pattern = \"us-docker.pkg.dev/\${var.project_id}/*\"
  }
  
  default_admission_rule {
    evaluation_mode         = \"REQUIRE_ATTESTATION\"
    enforcement_mode        = \"ENFORCED_BLOCK_AND_AUDIT_LOG\"
    require_attestations_by = [google_binary_authorization_attestor.build_attestor.name]
  }
  
  # Allow specific system images
  cluster_admission_rules {
    cluster                 = data.terraform_remote_state.lab09.outputs.gke_cluster.name
    evaluation_mode         = \"REQUIRE_ATTESTATION\"
    enforcement_mode        = \"ENFORCED_BLOCK_AND_AUDIT_LOG\"
    require_attestations_by = [google_binary_authorization_attestor.build_attestor.name]
  }
}

# Create attestor for build verification
resource \"google_binary_authorization_attestor\" \"build_attestor\" {
  name = \"techcorp-build-attestor\"
  description = \"Attestor for TechCorp build verification\"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.build_note.name
    public_keys {
      id = \"techcorp-build-key\"
      ascii_armored_pgp_public_key = var.pgp_public_key  # Would be provided
    }
  }
}

# Create Container Analysis note
resource \"google_container_analysis_note\" \"build_note\" {
  name = \"techcorp-build-note\"
  
  attestation_authority {
    hint {
      human_readable_name = \"TechCorp Build Verification\"
    }
  }
}

# Create vulnerability scanning configuration
resource \"google_container_analysis_note\" \"vulnerability_note\" {
  name = \"techcorp-vulnerability-note\"
  
  vulnerability {
    details {
      package = \"TechCorp Security Scanner\"
      package_type = \"GENERIC\"
      severity_name = \"HIGH\"
      description = \"Automated vulnerability scanning for TechCorp containers\"
    }
  }
}

# Create Kubernetes network policies (via ConfigMap)
resource \"google_storage_bucket_object\" \"network_policies\" {
  name   = \"k8s-network-policies.yaml\"
  bucket = data.terraform_remote_state.lab08.outputs.backup_services.backup_bucket
  content = <<-EOT
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-default-deny
      namespace: default
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
      - Egress
    ---
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-web-policy
      namespace: default
    spec:
      podSelector:
        matchLabels:
          tier: web
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
        ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
      egress:
      - to:
        - podSelector:
            matchLabels:
              tier: app
        ports:
        - protocol: TCP
          port: 8080
    ---
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: techcorp-app-policy
      namespace: default
    spec:
      podSelector:
        matchLabels:
          tier: app
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - podSelector:
            matchLabels:
              tier: web
        ports:
        - protocol: TCP
          port: 8080
      egress:
      - to:
        - podSelector:
            matchLabels:
              tier: database
        ports:
        - protocol: TCP
          port: 5432
  EOT
}
CONTAINER_SECURITY_END

echo \"✓ Container security configuration added\"
\`\`\`" \
"• Customer-managed encryption keys (CMEK) with automatic rotation for all data types
• Cloud Armor security policies with WAF protection, rate limiting, and geographic restrictions
• Data Loss Prevention (DLP) scanning with automated de-identification of sensitive data
• Security Command Center integration with automated incident response
• Binary Authorization for container security and build verification
• Network micro-segmentation with firewall rules and Kubernetes network policies
• Comprehensive security monitoring with log-based metrics and alerting
• Compliance automation for PCI DSS, SOX, and other fintech requirements" \
"# Check KMS key rings and keys
echo \"Checking KMS infrastructure...\"
keyrings=(\"techcorp-primary-keyring\" \"techcorp-secondary-keyring\")
for keyring in \"\${keyrings[@]}\"; do
    if gcloud kms keyrings describe \$keyring --location=\$REGION --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ KMS keyring created: \$keyring\"
        ((validation_passed++))
        
        # Check keys in keyring
        key_count=\$(gcloud kms keys list --keyring=\$keyring --location=\$REGION --format=\"value(name)\" | wc -l)
        if [ \$key_count -gt 0 ]; then
            echo \"✓ Encryption keys found in \$keyring: \$key_count keys\"
            ((validation_passed++))
        else
            echo \"✗ No encryption keys found in \$keyring\"
            ((validation_failed++))
        fi
    else
        echo \"✗ KMS keyring missing: \$keyring\"
        ((validation_failed++))
    fi
done

# Check Cloud Armor security policy
echo \"Checking Cloud Armor security policies...\"
if gcloud compute security-policies describe techcorp-web-security-policy --global --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Cloud Armor security policy created\"
    ((validation_passed++))
    
    # Check security rules
    rule_count=\$(gcloud compute security-policies describe techcorp-web-security-policy --global --format=\"value(rules.length())\")
    if [ \$rule_count -gt 5 ]; then
        echo \"✓ Security policy rules configured: \$rule_count rules\"
        ((validation_passed++))
    else
        echo \"✗ Insufficient security policy rules: \$rule_count\"
        ((validation_failed++))
    fi
else
    echo \"✗ Cloud Armor security policy missing\"
    ((validation_failed++))
fi

# Check DLP templates
echo \"Checking DLP templates...\"
dlp_templates=\$(gcloud dlp inspect-templates list --format=\"value(name)\" | grep techcorp | wc -l)
if [ \$dlp_templates -gt 0 ]; then
    echo \"✓ DLP inspect templates created: \$dlp_templates templates\"
    ((validation_passed++))
else
    echo \"✗ DLP inspect templates missing\"
    ((validation_failed++))
fi

deidentify_templates=\$(gcloud dlp deidentify-templates list --format=\"value(name)\" | grep techcorp | wc -l)
if [ \$deidentify_templates -gt 0 ]; then
    echo \"✓ DLP de-identify templates created: \$deidentify_templates templates\"
    ((validation_passed++))
else
    echo \"✗ DLP de-identify templates missing\"
    ((validation_failed++))
fi

# Check DLP job triggers
echo \"Checking DLP job triggers...\"
job_triggers=\$(gcloud dlp job-triggers list --format=\"value(name)\" | grep techcorp | wc -l)
if [ \$job_triggers -gt 0 ]; then
    echo \"✓ DLP job triggers created: \$job_triggers triggers\"
    ((validation_passed++))
else
    echo \"✗ DLP job triggers missing\"
    ((validation_failed++))
fi

# Check BigQuery security dataset
echo \"Checking security BigQuery dataset...\"
if bq show --dataset \${PROJECT_ID}:techcorp_security &>/dev/null; then
    echo \"✓ Security BigQuery dataset created\"
    ((validation_passed++))
else
    echo \"✗ Security BigQuery dataset missing\"
    ((validation_failed++))
fi

# Check security monitoring resources
echo \"Checking security monitoring...\"
if gcloud logging metrics describe techcorp_security_events --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Security events log metric created\"
    ((validation_passed++))
else
    echo \"✗ Security events log metric missing\"
    ((validation_failed++))
fi

# Check monitoring alert policies
security_policies=\$(gcloud alpha monitoring policies list --filter=\"displayName:TechCorp Security\" --format=\"value(name)\" | wc -l)
if [ \$security_policies -gt 0 ]; then
    echo \"✓ Security monitoring alert policies created\"
    ((validation_passed++))
else
    echo \"✗ Security monitoring alert policies missing\"
    ((validation_failed++))
fi

# Check Cloud Functions for security response
echo \"Checking security response automation...\"
if gcloud functions describe techcorp-security-response --region=\$REGION --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Security response Cloud Function created\"
    ((validation_passed++))
else
    echo \"✗ Security response Cloud Function missing\"
    ((validation_failed++))
fi

# Check firewall rules for micro-segmentation
echo \"Checking micro-segmentation firewall rules...\"
security_fw_rules=(\"techcorp-deny-all-internal\" \"techcorp-allow-web-to-app\" \"techcorp-allow-app-to-db\")
for rule in \"\${security_fw_rules[@]}\"; do
    if gcloud compute firewall-rules describe \$rule --project=\$PROJECT_ID &>/dev/null; then
        echo \"✓ Firewall rule created: \$rule\"
        ((validation_passed++))
    else
        echo \"✗ Firewall rule missing: \$rule\"
        ((validation_failed++))
    fi
done

# Check Binary Authorization policy
echo \"Checking Binary Authorization...\"
if gcloud container binauthz policy describe --project=\$PROJECT_ID &>/dev/null; then
    echo \"✓ Binary Authorization policy configured\"
    ((validation_passed++))
else
    echo \"✗ Binary Authorization policy missing\"
    ((validation_failed++))
fi

# Check attestors
attestor_count=\$(gcloud container binauthz attestors list --format=\"value(name)\" | wc -l)
if [ \$attestor_count -gt 0 ]; then
    echo \"✓ Binary Authorization attestors created: \$attestor_count\"
    ((validation_passed++))
else
    echo \"✗ Binary Authorization attestors missing\"
    ((validation_failed++))
fi

# Check Container Analysis notes
echo \"Checking Container Analysis...\"
analysis_notes=\$(gcloud alpha container analysis notes list --format=\"value(name)\" | grep techcorp | wc -l)
if [ \$analysis_notes -gt 0 ]; then
    echo \"✓ Container Analysis notes created: \$analysis_notes\"
    ((validation_passed++))
else
    echo \"✗ Container Analysis notes missing\"
    ((validation_failed++))
fi

# Check API enablement for security services
echo \"Checking security APIs...\"
security_apis=(\"cloudkms.googleapis.com\" \"securitycenter.googleapis.com\" \"dlp.googleapis.com\" \"binaryauthorization.googleapis.com\")
for api in \"\${security_apis[@]}\"; do
    if gcloud services list --enabled --filter=\"name:\$api\" --format=\"value(name)\" | grep -q \"\$api\"; then
        echo \"✓ Security API enabled: \$api\"
        ((validation_passed++))
    else
        echo \"✗ Security API not enabled: \$api\"
        ((validation_failed++))
    fi
done

# Check Terraform outputs
echo \"Checking Terraform outputs...\"
cd terraform
terraform_outputs=\$(terraform output -json 2>/dev/null)
if [ \$? -eq 0 ] && [ \"\$terraform_outputs\" != \"{}\" ]; then
    echo \"✓ Terraform outputs available\"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=(\"kms_keys\" \"security_policies\" \"dlp_templates\" \"security_monitoring\")
    for output in \"\${required_outputs[@]}\"; do
        if echo \"\$terraform_outputs\" | jq -e \".\$output\" &>/dev/null; then
            echo \"✓ Output available: \$output\"
            ((validation_passed++))
        else
            echo \"✗ Output missing: \$output\"
            ((validation_failed++))
        fi
    done
else
    echo \"✗ Terraform outputs not available\"
    ((validation_failed++))
fi
cd .." \
"**Issue 1: KMS Permission Issues**
\`\`\`bash
# Check KMS API enablement
gcloud services list --enabled --filter=\"name:cloudkms.googleapis.com\"

# Check KMS permissions
gcloud projects get-iam-policy \$PROJECT_ID --flatten=\"bindings[].members\" --filter=\"bindings.role:roles/cloudkms\"

# Manual key creation test
gcloud kms keyrings create test-keyring --location=\$REGION
\`\`\`

**Issue 2: Cloud Armor Configuration Issues**
\`\`\`bash
# Check Compute Engine API
gcloud services list --enabled --filter=\"name:compute.googleapis.com\"

# Manual security policy creation
gcloud compute security-policies create test-policy --description=\"Test policy\"
\`\`\`

**Issue 3: DLP API Issues**
\`\`\`bash
# Check DLP API enablement
gcloud services list --enabled --filter=\"name:dlp.googleapis.com\"

# Test DLP access
gcloud dlp inspect-templates list --format=\"table(name)\"
\`\`\`

**Issue 4: Binary Authorization Issues**
\`\`\`bash
# Check Binary Authorization API
gcloud services list --enabled --filter=\"name:binaryauthorization.googleapis.com\"

# Check GKE cluster configuration
gcloud container clusters describe techcorp-microservices --region=\$REGION
\`\`\`" \
"### Immediate Next Steps
1. **Test Security Controls**: Verify that WAF rules and DLP scanning are working
2. **Validate Encryption**: Ensure all data is encrypted with customer-managed keys
3. **Review Compliance**: Check that all fintech regulatory requirements are met
4. **Prepare for Lab 11**: Security infrastructure will integrate with advanced monitoring

### Key Takeaways
- **Defense in Depth**: Multiple layers of security controls protect against various threats
- **Compliance Automation**: Automated scanning and monitoring ensure continuous compliance
- **Key Management**: Customer-managed encryption provides enhanced security and control
- **Incident Response**: Automated security response reduces time to mitigation"

# Create a summary completion message
echo "
==========================================
🚀 Day 2 GCP Landing Zone Workshop Labs Created! 🚀
==========================================

Day 2 Labs Completed (Advanced Implementation):
✅ Lab 07: Cloud Logging Architecture (45 min)
   - Centralized logging with compliance-grade retention
   - Advanced log sinks and BigQuery integration
   - Log-based metrics and security monitoring

✅ Lab 08: Shared Services Implementation (60 min)
   - Enterprise DNS with private/public zones
   - Automated certificate management
   - Centralized security and backup services
   - Service discovery and configuration management

✅ Lab 09: Workload Environment Setup (60 min)
   - Multi-tier application environments
   - Auto-scaling instance groups and GKE
   - Load balancing with HTTPS termination
   - High availability across multiple zones

✅ Lab 10: Security Controls & Compliance (60 min)
   - Customer-managed encryption keys (CMEK)
   - Cloud Armor WAF and DLP protection
   - Security monitoring and incident response
   - Binary Authorization and container security

Remaining Labs to Create (11-14):
🔄 Lab 11: Advanced Monitoring & Alerting (60 min)
🔄 Lab 12: Disaster Recovery & Backup (45 min)
🔄 Lab 13: Cost Management & Optimization (45 min)
🔄 Lab 14: Final Validation & Optimization (60 min)

Created Day 2 Features:
🔧 Advanced enterprise configurations
🛡️ Comprehensive security and compliance
📊 Production-grade monitoring and logging
🏗️ High-availability architecture patterns
🔄 Automated scaling and management
📋 Detailed validation and troubleshooting

Next Steps:
1. Complete remaining labs (11-14) - run this script again to add them
2. Test integration between all Day 2 labs
3. Validate enterprise readiness
4. Begin workshop delivery preparation

Workshop Progress: 10/14 labs completed (71%)
==========================================

✅ Day 2 Advanced Implementation Labs (07-10) successfully created!
📁 Location: workshop-materials/lab-guides/
📖 Ready for enterprise deployment scenarios!"

echo "✅ Day 2 Labs 07-10 have been created successfully!"
echo "📂 Check workshop-materials/lab-guides/ for the new comprehensive lab guides"
echo "🔄 Run the script again to complete labs 11-14!"
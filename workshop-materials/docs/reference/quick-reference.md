# GCP Landing Zone Workshop - Quick Reference

## Essential Commands

### Terraform Commands
```bash
# Initialize and plan
terraform init
terraform plan -var-file=terraform.tfvars

# Apply and destroy
terraform apply -auto-approve
terraform destroy -auto-approve

# State management
terraform state list
terraform state show RESOURCE
terraform output

# Validation
terraform validate
terraform fmt
```

### GCP Commands
```bash
# Authentication
gcloud auth login
gcloud auth application-default login
gcloud auth list

# Project management
gcloud config set project PROJECT_ID
gcloud projects list
gcloud projects describe PROJECT_ID

# Service management
gcloud services list --enabled
gcloud services enable API_NAME

# Resource inspection
gcloud compute instances list
gcloud compute networks list
gcloud iam service-accounts list
```

### Workshop Environment
```bash
# Source configuration
source ~/gcp-landing-zone-workshop/workshop-config.env

# Check environment
echo $PROJECT_ID
echo $TF_STATE_BUCKET
echo $REGION

# Navigate to lab
cd ~/gcp-landing-zone-workshop/lab-XX

# Run validation
./validation/validate-lab-XX.sh
```

## Key Architecture Patterns

### Network CIDR Allocation
```
Management:    10.0.0.0/24   (256 IPs)
Web Tier:      10.1.0.0/22   (1024 IPs) 
App Tier:      10.1.4.0/22   (1024 IPs)
Data Tier:     10.1.8.0/22   (1024 IPs)
```

### Service Account Naming
```
Format: {purpose}-{environment}-sa
Examples:
- web-tier-sa
- app-tier-sa  
- monitoring-sa
- backup-manager-sa
```

### Resource Labeling
```hcl
labels = {
  workshop    = "gcp-landing-zone"
  lab         = "XX"
  environment = "production"
  component   = "networking"
  owner       = "platform-team"
}
```

## Troubleshooting Checklist

### Lab Won't Deploy
- [ ] Check authentication: `gcloud auth list`
- [ ] Verify project: `gcloud config get-value project`
- [ ] Check APIs: `gcloud services list --enabled`
- [ ] Validate Terraform: `terraform validate`
- [ ] Check state bucket: `gsutil ls gs://$TF_STATE_BUCKET`

### Terraform Issues
- [ ] Run `terraform init -upgrade`
- [ ] Check `.terraform.lock.hcl`
- [ ] Verify module paths
- [ ] Check variable values
- [ ] Review provider versions

### Network Issues  
- [ ] Check firewall rules: `gcloud compute firewall-rules list`
- [ ] Verify subnet CIDR ranges
- [ ] Test private Google access
- [ ] Check NAT gateway configuration
- [ ] Validate DNS resolution

### Permission Issues
- [ ] Check IAM policies: `gcloud projects get-iam-policy PROJECT_ID`
- [ ] Verify service account roles
- [ ] Check organization policies
- [ ] Validate API permissions
- [ ] Review conditional access

## Emergency Procedures

### Lab Cleanup
```bash
cd ~/gcp-landing-zone-workshop/lab-XX/terraform
terraform destroy -auto-approve
```

### Force Unlock Terraform
```bash
terraform force-unlock LOCK_ID
```

### Reset Authentication
```bash
gcloud auth revoke --all
gcloud auth login
gcloud auth application-default login
```

### Contact Information
- **Lead Instructor**: [instructor@company.com]
- **Technical Support**: [support@company.com]  
- **Slack Channel**: #gcp-workshop
- **Emergency Contact**: [emergency@company.com]

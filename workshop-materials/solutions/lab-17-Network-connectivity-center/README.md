# Lab 17: Network Connectivity Center Implementation

## Overview
This lab implements Network Connectivity Center infrastructure and configuration in your GCP Landing Zone using Terraform. You will deploy resources to establish centralized network connectivity management and multi-cloud interconnectivity.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – (Empty, add any helper scripts here)
- `docs/` – (Empty, add any documentation here)

## Configuration Details

### Required terraform.tfvars Changes
Before running Terraform, you must update the following variables in `terraform.tfvars`:

**Essential Configuration:**
- `project_id` - Your main GCP project ID
- `ncc_hub_name` - Name for the Network Connectivity Center hub
- `region` - GCP region (default: us-central1)
- `zone` - GCP zone (default: us-central1-a)

**Hub Configuration:**
- `create_ncc_hub` - Set to `true` if creating a new NCC hub
- `hub_description` - Description for the NCC hub
- `hub_labels` - Labels to apply to the hub

**Spoke Configuration:**
- `spoke_networks` - List of VPC networks to connect as spokes
- `spoke_subnets` - Subnet configurations for spokes
- `enable_private_google_access` - Enable private Google access

**Network Security:**
- `firewall_rules` - Custom firewall rules for spoke networks
- `allowed_ip_ranges` - IP ranges allowed for inter-spoke communication
- `enable_global_routing` - Enable global routing for the hub

**IAM Configuration:**
- `ncc_admin_members` - List of users/groups with NCC admin access
- `ncc_viewer_members` - List of users/groups with NCC viewer access

**Optional Features:**
- `create_sample_spokes` - Set to `true` to create sample spoke networks
- `enable_monitoring` - Enable monitoring and alerting for NCC

## Prerequisites
- Lab 16 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-17-Network-connectivity-center/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with the following required changes:
# 1. Update 'project_id' with your actual GCP project ID
# 2. Set 'ncc_hub_name' with your desired hub name
# 3. Configure 'spoke_networks' with your VPC networks
# 4. Update 'allowed_ip_ranges' for your network topology
# 5. Modify IAM member lists with actual user/group emails
# 6. Set 'create_sample_spokes' to true if you want to deploy test networks
# 7. Configure 'enable_global_routing' based on your requirements
# 8. Customize hub labels and descriptions as needed
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan -var-file=terraform.tfvars
```

### 4. Apply the Configuration
```bash
terraform apply -var-file=terraform.tfvars
# Type 'yes' to confirm
```

### 5. Review Outputs
```bash
terraform output
```

## Cleanup
```bash
terraform destroy -var-file=terraform.tfvars
# Type 'yes' to confirm
```

## Resources Created
- Network Connectivity Center hub
- Spoke network attachments
- Inter-spoke connectivity configurations
- Routing and firewall policies
- Monitoring and alerting setup

## Notes

- Ensure proper IAM permissions are configured before execution
- Review and customize variables according to your environment
- Monitor resource usage and costs
- Verify network connectivity after deployment

## Troubleshooting
- Verify GCP authentication: `gcloud auth list`
- Check project permissions: `gcloud projects get-iam-policy PROJECT_ID`
- Validate Terraform configuration: `terraform validate`
- Check NCC hub status: `gcloud network-connectivity hubs list`
- Verify spoke attachments: `gcloud network-connectivity spokes list`

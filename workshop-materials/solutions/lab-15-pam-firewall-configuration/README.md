# Lab 15: PAM Implementation & Firewall Configuration

## Overview
This lab implements Privileged Access Management (PAM) and configures firewall rules in your GCP Landing Zone using Terraform. You will deploy resources to enforce least-privilege access and secure network boundaries.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – (Empty, add any helper scripts here)
- `docs/` – (Empty, add any documentation here)

## Prerequisites
- Lab 14 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-15-pam-firewall-configuration/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars as needed
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
```

## Troubleshooting
- **Terraform errors:** Ensure all required APIs are enabled and credentials are valid.
- **Firewall/PAM errors:** Check IAM permissions, network settings, and resource quotas.

## Customization
- Add helper scripts to the `scripts/` folder as needed.
- Place additional documentation in the `docs/` folder.

## Next Steps
- Review all labs and ensure all outputs are as expected.
- Clean up resources if the workshop is complete.
- Provide feedback or suggestions for future improvements.

---

**Complete this lab to further secure your GCP Landing Zone!**

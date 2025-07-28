# Lab 10: Security Controls & Compliance

## Overview
This lab implements security controls and compliance measures in your GCP Landing Zone using Terraform. You will deploy security policies, IAM roles, and compliance configurations.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – (Empty, add any helper scripts here)
- `docs/` – (Empty, add any documentation here)

## Prerequisites
- Lab 09 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-10-security-controls-&-compliance/terraform
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
- **Security policy errors:** Check IAM permissions and organization policy constraints.

## Customization
- Add helper scripts to the `scripts/` folder as needed.
- Place additional documentation in the `docs/` folder.

## Next Steps
1. Proceed to Lab 11 after successful completion and validation of this lab:
   ```bash
   cd ../lab-11-advanced-monitoring-&-alerting/terraform
   ```
2. Follow the `README.md` in each lab folder for detailed instructions.

---

**Complete this lab before moving to the next. Each lab builds on the previous one!**

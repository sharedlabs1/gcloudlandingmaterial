# Lab 06: Cloud Monitoring Foundation

## Overview
This lab sets up foundational monitoring for the GCP Landing Zone using Terraform. You will deploy monitoring resources and validate the setup with provided scripts.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – Helper scripts (`deploy.sh`, `validate.sh`)
- `docs/` – (Empty, add any documentation here)
- `configs/` – (Empty, add any config files here)

## Prerequisites
- Lab 05 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-06-cloud-monitoring-foundation/terraform
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

## Using Scripts
- `scripts/deploy.sh`: Automates deployment steps (if provided)
- `scripts/validate.sh`: Validates the deployed resources

## Cleanup
```bash
terraform destroy -var-file=terraform.tfvars
```

## Troubleshooting
- **Terraform errors:** Check that all required APIs are enabled and credentials are valid.
- **Monitoring resource errors:** Ensure you have correct permissions and quotas.
- **Script errors:** Make sure scripts are executable and referenced correctly.

## Customization
- Place any additional documentation in the `docs/` folder.
- Place any config files in the `configs/` folder.

## Next Steps
1. Proceed to Lab 07 after successful completion and validation of this lab:
   ```bash
   cd ../lab-07-cloud-logging-architecture/terraform
   ```
2. Follow the `README.md` in each lab folder for detailed instructions.

---

**Complete this lab before moving to the next. Each lab builds on the previous one!**

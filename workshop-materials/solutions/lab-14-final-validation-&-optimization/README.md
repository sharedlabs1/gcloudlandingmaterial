# Lab 14: Final Validation & Optimization

## Overview
This lab performs final validation and optimization of your GCP Landing Zone using Terraform. You will validate all previous configurations, optimize resources, and ensure the environment is production-ready.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – (Empty, add any helper scripts here)
- `docs/` – (Empty, add any documentation here)

## Prerequisites
- Lab 13 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-14-final-validation-&-optimization/terraform
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
- **Validation/optimization errors:** Check IAM permissions and resource quotas.

## Customization
- Add helper scripts to the `scripts/` folder as needed.
- Place additional documentation in the `docs/` folder.

## Next Steps
- Review all labs and ensure all outputs are as expected.
- Clean up resources if the workshop is complete.
- Provide feedback or suggestions for future improvements.

---

**Congratulations! You have completed the GCP Landing Zone workshop.**

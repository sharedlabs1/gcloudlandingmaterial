# Lab 02: Terraform Environment Setup

## Overview
This lab sets up the Terraform environment, modules, and supporting resources for the GCP Landing Zone. You will use modules for IAM and VPC, and apply Terraform configurations.

## Folder Structure
- `terraform/` – Main Terraform configuration (`main.tf`)
- `modules/` – Reusable Terraform modules:
  - `iam-bindings/`
  - `vpc-network/`
- `scripts/` – (Empty, add any helper scripts here)

## Prerequisites
- Lab 01 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-02-terraform-environment-setup/terraform
cp terraform.tfvars.example terraform.tfvars  # if example provided
# Edit terraform.tfvars as needed
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Apply the Configuration
```bash
terraform apply
# Type 'yes' to confirm
```

### 5. Review Outputs
```bash
terraform output
```

## Using Modules
- The `modules/iam-bindings` and `modules/vpc-network` directories contain reusable Terraform modules.
- Reference these modules in your `main.tf` as needed.

## Cleanup
```bash
terraform destroy
```

## Troubleshooting
- **Terraform errors:** Check that all required APIs are enabled and credentials are valid.
- **Module errors:** Ensure module paths are correct and all variables are set.

## Customization
- Add any helper scripts to the `scripts/` folder as needed.
- Place any additional documentation in the `docs/` folder.

## Next Steps
1. Proceed to Lab 03 after successful completion and validation of this lab:
   ```bash
   cd ../lab-03-core-networking-architecture/terraform
   ```
2. Follow the `README.md` in each lab folder for detailed instructions.

---
**Complete this lab before moving to the next. Each lab builds on the previous one!**

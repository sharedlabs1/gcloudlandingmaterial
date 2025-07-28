# Lab 01: GCP Organizational Foundation

## Overview
This lab sets up the foundational GCP organizational structure using Terraform. You will create projects, enable APIs, and establish the base for all subsequent labs.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – (Empty, add any helper scripts here)
- `docs/` – (Empty, add any documentation here)

## Prerequisites
- Lab 00 (environment setup) completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled
- APIs enabled (see `setup-complete-environment.sh` or `apis-list.txt`)

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-01-gcp-organizational-foundation/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to set your PROJECT_ID and other variables
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
To destroy all resources created by this lab:
```bash
terraform destroy -var-file=terraform.tfvars
```

## Troubleshooting
- **Terraform errors:** Check that all required APIs are enabled and credentials are valid.
- **Project creation fails:** Ensure billing is enabled and you have sufficient permissions.
- **Output missing:** Check for errors in the apply step and review the Terraform state.

## Customization
- Add any helper scripts to the `scripts/` folder as needed.
- Place any additional documentation in the `docs/` folder.

## Next Steps
1. Proceed to Lab 02 after successful completion and validation of this lab:
   ```bash
   cd ../lab-02-terraform-environment-setup/terraform
   ```
2. Follow the `README.md` in each lab folder for detailed instructions.

---
**Complete this lab before moving to the next. Each lab builds on the previous one!**

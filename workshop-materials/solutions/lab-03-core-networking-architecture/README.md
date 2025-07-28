# Lab 03: Core Networking Architecture

## Overview
This lab builds the core networking architecture for the GCP Landing Zone using Terraform. You will deploy VPCs, subnets, and related resources. Startup scripts for VMs are provided in the `scripts/` folder.

## Folder Structure
- `terraform/` – Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`)
- `scripts/` – Startup scripts for VMs (`app-startup.sh`, `web-startup.sh`)
- `docs/` – (Empty, add any documentation here)

## Prerequisites
- Lab 02 completed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Prepare Environment
```bash
cd ~/workshop-materials/solutions/lab-03-core-networking-architecture/terraform
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

## Using Startup Scripts
- Use the scripts in the `scripts/` folder as startup scripts for your VM instances.

## Cleanup
```bash
terraform destroy -var-file=terraform.tfvars
```

## Troubleshooting
- **Terraform errors:** Check that all required APIs are enabled and credentials are valid.
- **Network resource errors:** Ensure subnet and VPC names are unique and not in use.
- **Startup script issues:** Make sure scripts are executable and referenced correctly in your Terraform config.

## Customization
- Add any helper scripts to the `scripts/` folder as needed.
- Place any additional documentation in the `docs/` folder.

## Next Steps
1. Proceed to Lab 04 after successful completion and validation of this lab:
   ```bash
   cd ../lab-04-network-security-implementation/terraform
   ```
2. Follow the `README.md` in each lab folder for detailed instructions.

---
**Complete this lab before moving to the next. Each lab builds on the previous one!**

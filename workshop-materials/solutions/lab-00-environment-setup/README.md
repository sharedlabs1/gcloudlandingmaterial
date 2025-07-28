# Lab 00: Environment Setup

## Overview
This lab prepares your local and GCP environment for the GCP Landing Zone Workshop. It ensures all required APIs are enabled, creates a Terraform state bucket, sets up authentication, and builds the directory structure for all subsequent labs.

## Folder Structure
- `scripts/` – Contains setup and utility scripts (e.g., `setup-complete-environment.sh`)

## Prerequisites
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Steps to Execute

### 1. Set Required Environment Variables
Before running the setup script, set your GCP project ID and (optionally) region/zone:
```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"         # or your preferred region
export ZONE="us-central1-a"         # or your preferred zone
```

### 2. Run the Complete Environment Setup Script
This script will:
- Enable all required GCP APIs
- Create a versioned Terraform state bucket
- Set up application default credentials
- Create the full workshop directory structure under `~/workshop-materials`
- Generate a `workshop-config.env` file with all key environment variables

Run the script:
```bash
cd solutions/lab-00-environment-setup/scripts
bash setup-complete-environment.sh
```

### 3. Review Output and Next Steps
After successful execution, you will see:
- Confirmation of API enablement and bucket creation
- Instructions to proceed to the `solutions` directory and start with Lab 01
- A `workshop-config.env` file in `~/workshop-materials` for sourcing in future sessions

### 4. Source the Workshop Configuration
Before starting any lab, always source the config:
```bash
source ~/workshop-materials/workshop-config.env
```

## Troubleshooting
- **API Enablement Fails:** Ensure your account has sufficient permissions and billing is enabled.
- **Bucket Already Exists:** The script will not fail if the bucket exists; it will reuse it.
- **Authentication Issues:** Run `gcloud auth login` and `gcloud auth application-default login` manually if needed.
- **Directory Not Created:** Check for typos in environment variables and rerun the script.

## Customization
- Edit the `setup-complete-environment.sh` script to add or remove APIs as needed (see the `apis` array).
- You can change the default region/zone by editing the environment variables at the top of the script or in your shell.

## Next Steps
1. Change to the solutions directory:
   ```bash
   cd ~/workshop-materials/solutions
   ```
2. Start with Lab 01:
   ```bash
   cd lab-01-gcp-organizational-foundation/terraform
   ```
3. Follow the `README.md` in each lab folder for detailed instructions.

---

**This setup is required for all subsequent labs. Complete this step before moving forward!**

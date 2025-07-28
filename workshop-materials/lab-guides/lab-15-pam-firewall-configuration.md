# Lab 15: PAM Implementation & Firewall Configuration

## Objective
Implement Privileged Access Management (PAM) and configure firewall rules in your GCP Landing Zone to enforce least-privilege access and secure network boundaries.

## Prerequisites
- Completion of Lab 14: Final Validation & Optimization
- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Bash shell (Ubuntu recommended)
- Valid GCP project and billing enabled

## Lab Steps

### 1. Review the Architecture
- Understand the need for PAM in cloud environments
- Identify critical resources requiring privileged access
- Review GCP firewall concepts and best practices

### 2. Prepare the Environment
- Clone or navigate to the workshop repository
- Set required environment variables:
  ```bash
  export PROJECT_ID=your-gcp-project-id
  export TF_STATE_BUCKET=your-tf-state-bucket
  ```

### 3. Configure PAM
- Define IAM roles and policies for privileged users
- Implement least-privilege access using custom roles or predefined roles
- (Optional) Integrate with third-party PAM solutions if required

### 4. Configure Firewall Rules
- Use Terraform to define firewall rules in `main.tf`
- Restrict access to management ports (e.g., SSH, RDP)
- Allow only necessary traffic from trusted sources
- Example:
  ```hcl
  resource "google_compute_firewall" "allow-ssh" {
    name    = "allow-ssh"
    network = var.network
    allow {
      protocol = "tcp"
      ports    = ["22"]
    }
    source_ranges = ["203.0.113.0/24"] # Replace with your trusted IP range
  }
  ```

### 5. Deploy and Validate
- Initialize and apply Terraform configuration:
  ```bash
  cd solutions/lab-15-pam-firewall-configuration/terraform
  terraform init
  terraform apply -var-file=terraform.tfvars
  ```
- Validate that only privileged users have access and firewall rules are enforced

### 6. Cleanup
- Destroy resources if no longer needed:
  ```bash
  terraform destroy -var-file=terraform.tfvars
  ```

## Deliverables
- Updated IAM roles and policies for PAM
- Configured firewall rules in GCP
- Validation evidence (screenshots, logs, or output)

## Troubleshooting
- Ensure all required APIs are enabled
- Check IAM permissions and firewall rule priorities
- Review Terraform logs for errors

## Next Steps
- Review all labs and ensure all outputs are as expected
- Clean up resources if the workshop is complete
- Provide feedback or suggestions for future improvements

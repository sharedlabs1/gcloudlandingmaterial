# Pre-Setup Guide: Preparing Your Environment for Lab-00

Before running `lab-00-environment-setup/scripts/setup-complete-environment.sh`, follow these steps to prepare your system:

## 1. System Requirements

- **Operating System:** Ubuntu 20.04+ (recommended) or other Linux
- **RAM:** 8GB minimum (16GB recommended)
- **Disk Space:** 20GB free
- **Network:** Stable internet connection

## 2. Install Required Tools

### a. Google Cloud SDK

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-456.0.0-linux-x86_64.tar.gz
 tar -xf google-cloud-sdk-456.0.0-linux-x86_64.tar.gz
 ./google-cloud-sdk/install.sh
 exec -l $SHELL
 gcloud init
```

### b. Terraform

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
 echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform -version
```

### c. Bash Shell & Utilities

```bash
sudo apt-get install -y bash curl wget git unzip jq
```

### d. gsutil

- Installed automatically with Google Cloud SDK.

## 3. Authenticate with Google Cloud

```bash
gcloud auth login
gcloud auth application-default login
```

## 4. Permissions

- Ensure you have **Owner** permissions on your GCP project.
- Enable billing for your project.

## 5. Verify Installation

```bash
gcloud version
gsutil version
terraform version
gcloud components update
gcloud projects list
gcloud config set project YOUR_PROJECT_ID #use your project name which is output of previous program
```

---

*GCP User: [niranjan.pandey@labs.webagesolutions.com](mailto:niranjan.pandey@labs.webagesolutions.com)
Password: Bamboo*0707

URL: [https://us.labportal.webagesolutions.com/#/](https://us.labportal.webagesolutions.com/#/) 

Username: 9542500114

Password: 7xgqNLHXCbxT

Once all steps are complete, you can run the setup script for Lab-00.**

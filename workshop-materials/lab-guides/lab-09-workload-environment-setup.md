# Lab 09: Workload Environment Setup

## Lab Overview

**Duration**: 60 minutes 
**Difficulty**: Advanced  
**Prerequisites**: Successful completion of Labs 01-08 (including shared services)

### Lab Description
Create application workload environments with compute instances, managed instance groups, auto-scaling, load balancing, and high availability for TechCorp's multi-tier applications with enterprise-grade reliability and performance.

### Business Context
As TechCorp's cloud infrastructure matures, this lab implements advanced operational capabilities essential for production fintech environments, including regulatory compliance, operational excellence, and enterprise-grade automation.

## Learning Objectives

After completing this lab, you will be able to:

• Deploy multi-tier application environments with proper segmentation
• Configure managed instance groups with auto-scaling policies
• Implement high availability across multiple zones and regions
• Set up application load balancing with health checks and SSL termination
• Configure container-based workloads with Kubernetes integration
• Implement blue-green deployment capabilities
• Set up application performance monitoring and scaling triggers

## Concept Overview (Theory: 15-20 minutes)

### Key Concepts

**Multi-Tier Application Architecture**: Enterprise applications require structured deployment across multiple tiers (web, application, database) with proper isolation, scaling, and communication patterns. This includes containerized and VM-based workloads with appropriate resource allocation.

**Auto-scaling and High Availability**: Production workloads require automatic scaling based on demand and high availability across multiple zones. This includes health checks, load balancing, and automatic failover capabilities to ensure business continuity.

**Instance Groups and Templates**: Managed instance groups provide consistent deployment, scaling, and management of compute resources. Instance templates ensure configuration consistency and enable blue-green deployments.

**Load Balancing Strategies**: Different load balancing patterns (global vs regional, HTTP vs TCP) serve different application requirements. This includes SSL termination, backend health monitoring, and traffic distribution algorithms.

### Architecture Diagram
```
[ASCII diagram would be here showing the components built in this lab]
TechCorp Architecture - Lab 09 Components
Integration with Labs 01-08
```

## Pre-Lab Setup

### Environment Verification
```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-09

# Source workshop configuration
source ../workshop-config.env

# Verify environment
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Lab: 09"
echo "Current directory: $(pwd)"

# Check prerequisites from previous labs
echo "Checking previous lab outputs..."
ls -la ../lab-08/outputs/

# Verify Day 1 foundation is complete
required_labs=(01 02 03 04 05 06)
for lab in "${required_labs[@]}"; do
    if [ -f "../lab-$lab/outputs/lab-$lab-validation.json" ]; then
        status=$(jq -r '.status' "../lab-$lab/outputs/lab-$lab-validation.json")
        if [ "$status" = "PASSED" ]; then
            echo "✓ Lab $lab: Foundation ready"
        else
            echo "✗ Lab $lab: Validation failed - please complete Day 1 labs first"
            exit 1
        fi
    else
        echo "✗ Lab $lab: Not completed - please complete Day 1 labs first"
        exit 1
    fi
done
```

### Required Variables
```bash
# Set lab-specific variables
export LAB_PREFIX="lab09"
export TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export LAB_USER=$(gcloud config get-value account | cut -d@ -f1)

# Verify authentication
gcloud auth list --filter=status:ACTIVE

# Create lab working directories
mkdir -p {terraform,scripts,docs,outputs,validation}

# Get previous lab outputs for integration
if [ -f "../lab-08/outputs/terraform-outputs.json" ]; then
    echo "✓ Previous lab outputs available for integration"
else
    echo "⚠ Previous lab outputs not found - some integrations may not work"
fi
```

## Lab Implementation

### Step 1: Application Environment Infrastructure

Set up the foundational infrastructure for TechCorp's application workloads.

```bash
# Navigate to lab directory
cd ~/workshop-materials/lab-09/terraform

# Create main workload configuration
cat > main.tf << 'WORKLOAD_MAIN_END'
# Lab 09: Workload Environment Setup
# Multi-tier application environments for TechCorp

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "${TF_STATE_BUCKET}"
    prefix = "lab-09/terraform/state"
  }
}

# Get previous lab outputs for integration
data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

data "terraform_remote_state" "lab08" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-08/terraform/state"
  }
}

# Local values for workload configuration
locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "09"
    component   = "workloads"
    environment = "production"
  }
  
  # Application tiers configuration
  app_tiers = {
    web = {
      machine_type    = "e2-medium"
      disk_size_gb   = 20
      disk_type      = "pd-standard"
      zones          = ["us-central1-a", "us-central1-b", "us-central1-c"]
      min_replicas   = 2
      max_replicas   = 10
      target_cpu     = 70
      subnet         = "dev-web"
    }
    app = {
      machine_type    = "e2-standard-2"
      disk_size_gb   = 50
      disk_type      = "pd-ssd"
      zones          = ["us-central1-a", "us-central1-b"]
      min_replicas   = 2
      max_replicas   = 8
      target_cpu     = 80
      subnet         = "dev-app"
    }
    database = {
      machine_type    = "e2-highmem-2"
      disk_size_gb   = 100
      disk_type      = "pd-ssd"
      zones          = ["us-central1-a", "us-central1-b"]
      min_replicas   = 2
      max_replicas   = 4
      target_cpu     = 85
      subnet         = "dev-app"
    }
  }
}

# Create instance templates for each tier
resource "google_compute_instance_template" "app_tiers" {
  for_each = local.app_tiers
  
  name_prefix = "techcorp-${each.key}-"
  description = "Instance template for ${each.key} tier"
  
  machine_type = each.value.machine_type
  
  # Boot disk configuration
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
  }
  
  # Network configuration
  network_interface {
    network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
    subnetwork = data.terraform_remote_state.lab02.outputs.subnets[each.value.subnet].self_link
    
    # No external IP for security (use NAT gateway)
    access_config = null
  }
  
  # Service account configuration
  service_account {
    email = data.terraform_remote_state.lab02.outputs.workload_service_accounts["${each.key}-tier-sa"].email
    scopes = ["cloud-platform"]
  }
  
  # Metadata and startup script
  metadata = {
    startup-script = templatefile("${path.module}/scripts/${each.key}-startup.sh", {
      tier           = each.key
      project_id     = var.project_id
      dns_zone       = data.terraform_remote_state.lab08.outputs.dns_zones.internal.name
      service_registry = data.terraform_remote_state.lab08.outputs.service_discovery.service_registry_secret
    })
    
    # Security configurations
    enable-oslogin = "TRUE"
    block-project-ssh-keys = "TRUE"
  }
  
  # Network tags for firewall rules
  tags = ["techcorp-${each.key}-tier", "internal", "workload"]
  
  # Labels
  labels = merge(local.common_labels, {
    tier = each.key
    purpose = "application-workload"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
WORKLOAD_MAIN_END

echo "✓ Workload infrastructure configuration created"
```

### Step 2: Managed Instance Groups and Auto-scaling

Configure managed instance groups with auto-scaling for high availability.

```bash
# Add managed instance groups configuration
cat >> main.tf << 'INSTANCE_GROUPS_END'

# Create managed instance groups for each tier
resource "google_compute_region_instance_group_manager" "app_tiers" {
  for_each = local.app_tiers
  
  name               = "techcorp-${each.key}-mig"
  base_instance_name = "techcorp-${each.key}"
  region             = var.region
  
  version {
    instance_template = google_compute_instance_template.app_tiers[each.key].id
  }
  
  target_size = each.value.min_replicas
  
  # Distribution across zones
  distribution_policy_zones = each.value.zones
  
  # Auto-healing configuration
  auto_healing_policies {
    health_check      = google_compute_health_check.tier_health_checks[each.key].id
    initial_delay_sec = 300
  }
  
  # Update policy for rolling updates
  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action              = "REPLACE"
    max_surge_fixed             = 2
    max_unavailable_fixed       = 1
  }
  
  # Named ports for load balancing
  named_port {
    name = "http"
    port = each.key == "web" ? 80 : 8080
  }
  
  if each.key == "web" {
    named_port {
      name = "https"
      port = 443
    }
  }
}

# Create auto-scaling policies
resource "google_compute_region_autoscaler" "app_tier_autoscaler" {
  for_each = local.app_tiers
  
  name   = "techcorp-${each.key}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.app_tiers[each.key].id
  
  autoscaling_policy {
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas
    cooldown_period = 60
    
    # CPU utilization scaling
    cpu_utilization {
      target = each.value.target_cpu / 100
    }
    
    # Custom metrics scaling (for production environments)
    dynamic "metric" {
      for_each = each.key == "web" ? [1] : []
      content {
        name   = "compute.googleapis.com/instance/network/received_bytes_count"
        target = 1000000  # 1MB/s network traffic
        type   = "GAUGE"
      }
    }
  }
}

# Create health checks for each tier
resource "google_compute_health_check" "tier_health_checks" {
  for_each = local.app_tiers
  
  name        = "techcorp-${each.key}-health-check"
  description = "Health check for ${each.key} tier instances"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = each.key == "web" ? 80 : 8080
    request_path = each.key == "database" ? "/db-health" : "/health"
  }
}
INSTANCE_GROUPS_END

echo "✓ Managed instance groups and auto-scaling configuration added"
```

### Step 3: Load Balancing Configuration

Set up comprehensive load balancing for the application tiers.

```bash
# Add load balancing configuration
cat >> main.tf << 'LOAD_BALANCING_END'

# Create backend services for load balancing
resource "google_compute_backend_service" "web_backend" {
  name        = "techcorp-web-backend"
  description = "Backend service for web tier"
  protocol    = "HTTP"
  timeout_sec = 30
  
  backend {
    group           = google_compute_region_instance_group_manager.app_tiers["web"].instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
  
  health_checks = [google_compute_health_check.tier_health_checks["web"].id]
  
  # Connection draining
  connection_draining_timeout_sec = 300
  
  # Enable logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }
  
  # Security policy (will be enhanced in security lab)
  # security_policy = google_compute_security_policy.web_security_policy.id
}

# Create internal load balancer for app tier
resource "google_compute_region_backend_service" "app_backend" {
  name        = "techcorp-app-backend"
  description = "Internal backend service for app tier"
  protocol    = "HTTP"
  region      = var.region
  
  backend {
    group          = google_compute_region_instance_group_manager.app_tiers["app"].instance_group
    balancing_mode = "UTILIZATION"
    max_utilization = 0.8
  }
  
  health_checks = [google_compute_region_health_check.app_internal_health.id]
  
  connection_draining_timeout_sec = 300
}

# Create regional health check for internal load balancer
resource "google_compute_region_health_check" "app_internal_health" {
  name   = "techcorp-app-internal-health"
  region = var.region
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# Create URL map for routing
resource "google_compute_url_map" "web_url_map" {
  name            = "techcorp-web-url-map"
  default_service = google_compute_backend_service.web_backend.id
  
  host_rule {
    hosts        = ["api.techcorp-demo.com"]
    path_matcher = "api-matcher"
  }
  
  path_matcher {
    name            = "api-matcher"
    default_service = google_compute_backend_service.web_backend.id
    
    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.web_backend.id
    }
    
    path_rule {
      paths   = ["/health"]
      service = google_compute_backend_service.web_backend.id
    }
  }
}

# Create HTTPS proxy
resource "google_compute_target_https_proxy" "web_https_proxy" {
  name             = "techcorp-web-https-proxy"
  url_map          = google_compute_url_map.web_url_map.id
  ssl_certificates = [data.terraform_remote_state.lab08.outputs.ssl_certificates.public_cert.id]
}

# Create HTTP proxy (for redirect)
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "techcorp-web-http-proxy"
  url_map = google_compute_url_map.web_redirect.id
}

# Create URL map for HTTP to HTTPS redirect
resource "google_compute_url_map" "web_redirect" {
  name = "techcorp-web-redirect"
  
  default_url_redirect {
    strip_query            = false
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

# Create global forwarding rules
resource "google_compute_global_forwarding_rule" "web_https" {
  name       = "techcorp-web-https"
  target     = google_compute_target_https_proxy.web_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.web_ip.address
}

resource "google_compute_global_forwarding_rule" "web_http" {
  name       = "techcorp-web-http"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.web_ip.address
}

# Reserve global IP address
resource "google_compute_global_address" "web_ip" {
  name = "techcorp-web-ip"
}

# Create internal forwarding rule for app tier
resource "google_compute_forwarding_rule" "app_internal" {
  name                  = "techcorp-app-internal"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.app_backend.id
  network               = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  subnetwork            = data.terraform_remote_state.lab02.outputs.subnets["dev-app"].self_link
  ports                 = ["8080"]
}
LOAD_BALANCING_END

echo "✓ Load balancing configuration added"
```

### Step 4: Container Workloads with GKE

Set up Kubernetes cluster for containerized workloads.

```bash
# Add GKE configuration
cat >> main.tf << 'GKE_CONFIG_END'

# Create GKE cluster for microservices
resource "google_container_cluster" "techcorp_cluster" {
  name     = "techcorp-microservices"
  location = var.region
  
  # Regional cluster for high availability
  node_locations = ["us-central1-a", "us-central1-b", "us-central1-c"]
  
  # Network configuration
  network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
  subnetwork = data.terraform_remote_state.lab02.outputs.subnets["dev-web"].self_link
  
  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "dev-web-pods"
    services_secondary_range_name = "dev-web-services"
  }
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Master configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Enable network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  
  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  # Enable logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }
  
  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# Create node pools
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-nodes"
  location   = var.region
  cluster    = google_container_cluster.techcorp_cluster.name
  node_count = 1
  
  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  
  # Node configuration
  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    
    # Service account for nodes
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Disk configuration
    disk_size_gb = 50
    disk_type    = "pd-standard"
    
    # Network tags
    tags = ["gke-nodes", "techcorp-cluster"]
    
    # Labels
    labels = merge(local.common_labels, {
      node-pool = "primary"
    })
  }
  
  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  
  # Management settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Create service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "techcorp-gke-nodes"
  display_name = "TechCorp GKE Node Service Account"
}

# Grant necessary permissions to GKE nodes
resource "google_project_iam_member" "gke_node_permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
GKE_CONFIG_END

echo "✓ GKE configuration added"
```

### Step 5: Create Startup Scripts

Create startup scripts for application tiers.

```bash
# Create scripts directory
mkdir -p scripts

# Create web tier startup script
cat > scripts/web-startup.sh << 'WEB_STARTUP_END'
#!/bin/bash

# Web Tier Startup Script for TechCorp
set -e

echo "Starting TechCorp Web Tier initialization..."

# Update system
apt-get update
apt-get install -y nginx jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure nginx
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # API proxy to app tier
    location /api/ {
        proxy_pass http://app./;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_CONFIG

# Create simple web page
cat > /var/www/html/index.html << 'HTML_END'
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #333; text-align: center; }
        .info { background: #f0f0f0; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1 class=header>TechCorp Web Application</h1>
    <div class=info>
        <h3>Server Information</h3>
        <p><strong>Tier:</strong> Web</p>
        <p><strong>Instance:</strong> ip-172-31-38-49</p>
        <p><strong>Zone:</strong> </p>
        <p><strong>Project:</strong> </p>
        <p><strong>Timestamp:</strong> Wed Jun 25 19:23:09 UTC 2025</p>
    </div>
</body>
</html>
HTML_END

# Start and enable nginx
systemctl restart nginx
systemctl enable nginx

echo "Web tier initialization completed successfully"
WEB_STARTUP_END

# Create app tier startup script
cat > scripts/app-startup.sh << 'APP_STARTUP_END'
#!/bin/bash

# App Tier Startup Script for TechCorp
set -e

echo "Starting TechCorp App Tier initialization..."

# Update system
apt-get update
apt-get install -y python3 python3-pip jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create application user
useradd -m -s /bin/bash techcorp
mkdir -p /opt/techcorp

# Create simple Python application
cat > /opt/techcorp/app.py << 'PYTHON_APP'
#!/usr/bin/env python3
import json
import socket
import subprocess
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

class TechCorpHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            health_data = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'hostname': socket.gethostname(),
                'tier': 'app'
            }
            self.wfile.write(json.dumps(health_data).encode())
        
        elif self.path == '/api/info':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Get instance metadata
            try:
                zone_cmd = 'curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone'
                zone = subprocess.check_output(zone_cmd, shell=True).decode().split('/')[-1]
            except:
                zone = 'unknown'
            
            info_data = {
                'service': 'TechCorp API',
                'tier': 'application',
                'hostname': socket.gethostname(),
                'zone': zone,
                'project': '',
                'timestamp': datetime.now().isoformat(),
                'version': '1.0.0'
            }
            self.wfile.write(json.dumps(info_data).encode())
        
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), TechCorpHandler)
    print('TechCorp App Server starting on port 8080...')
    server.serve_forever()
PYTHON_APP

# Create systemd service
cat > /etc/systemd/system/techcorp-app.service << 'SERVICE_CONFIG'
[Unit]
Description=TechCorp Application Service
After=network.target

[Service]
Type=simple
User=techcorp
WorkingDirectory=/opt/techcorp
ExecStart=/usr/bin/python3 /opt/techcorp/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_CONFIG

# Set permissions and start service
chown -R techcorp:techcorp /opt/techcorp
chmod +x /opt/techcorp/app.py
systemctl daemon-reload
systemctl start techcorp-app
systemctl enable techcorp-app

echo "App tier initialization completed successfully"
APP_STARTUP_END

# Create database tier startup script
cat > scripts/database-startup.sh << 'DB_STARTUP_END'
#!/bin/bash

# Database Tier Startup Script for TechCorp
set -e

echo "Starting TechCorp Database Tier initialization..."

# Update system
apt-get update
apt-get install -y postgresql postgresql-contrib jq curl

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql << 'SQL_CONFIG'
CREATE DATABASE techcorp;
CREATE USER techcorp_app WITH PASSWORD 'secure_password_123';
GRANT ALL PRIVILEGES ON DATABASE techcorp TO techcorp_app;
\q
SQL_CONFIG

# Create health check endpoint
cat > /opt/db-health.py << 'DB_HEALTH'
#!/usr/bin/env python3
import json
import socket
import psycopg2
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

class DBHealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/db-health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Test database connection
            try:
                conn = psycopg2.connect(
                    host="localhost",
                    database="techcorp",
                    user="techcorp_app",
                    password="secure_password_123"
                )
                conn.close()
                db_status = "healthy"
            except:
                db_status = "unhealthy"
            
            health_data = {
                'status': db_status,
                'timestamp': datetime.now().isoformat(),
                'hostname': socket.gethostname(),
                'tier': 'database',
                'service': 'postgresql'
            }
            self.wfile.write(json.dumps(health_data).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), DBHealthHandler)
    server.serve_forever()
DB_HEALTH

# Install Python dependencies and start health service
apt-get install -y python3-psycopg2
python3 /opt/db-health.py &

echo "Database tier initialization completed successfully"
DB_STARTUP_END

chmod +x scripts/*.sh
echo "✓ Startup scripts created"
```

## Expected Deliverables

Upon successful completion of this lab, you should have:

• Multi-tier application environments with web, app, and database tiers
• Managed instance groups with auto-scaling policies based on CPU and custom metrics
• Comprehensive load balancing with HTTPS termination and health checks
• GKE cluster for containerized microservices with workload identity
• High availability deployment across multiple zones
• Auto-healing capabilities with health monitoring
• Blue-green deployment support through instance templates
• Integration with shared services (DNS, certificates, monitoring)

## Validation and Testing

### Automated Validation
```bash
# Create comprehensive validation script
cat > validation/validate-lab-09.sh << 'VALIDATION_SCRIPT_END'
#!/bin/bash

echo "=== Lab 09 Validation Script ==="
echo "Started at: $(date)"
echo "Project: $PROJECT_ID"
echo

# Source workshop configuration
source ../../workshop-config.env

validation_passed=0
validation_failed=0

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo "✓ $2"
        ((validation_passed++))
    else
        echo "✗ $2"
        ((validation_failed++))
    fi
}

# Check Day 1 prerequisites
echo "Validating Day 1 prerequisites..."
day1_labs=(01 02 03 04 05 06)
for lab in "${day1_labs[@]}"; do
    if [ -f "../../lab-$lab/outputs/lab-$lab-validation.json" ]; then
        status=$(jq -r '.status' "../../lab-$lab/outputs/lab-$lab-validation.json")
        check_status $([ "$status" = "PASSED" ] && echo 0 || echo 1) "Day 1 Lab $lab prerequisite"
    else
        echo "✗ Day 1 Lab $lab not completed"
        ((validation_failed++))
    fi
done

# Check instance templates
echo "Checking instance templates..."
tiers=("web" "app" "database")
for tier in "${tiers[@]}"; do
    template_count=$(gcloud compute instance-templates list --filter="name:techcorp-$tier" --format="value(name)" | wc -l)
    if [ $template_count -gt 0 ]; then
        echo "✓ Instance template created for $tier tier"
        ((validation_passed++))
    else
        echo "✗ Instance template missing for $tier tier"
        ((validation_failed++))
    fi
done

# Check managed instance groups
echo "Checking managed instance groups..."
for tier in "${tiers[@]}"; do
    if gcloud compute instance-groups managed describe techcorp-$tier-mig --region=$REGION --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Managed instance group created for $tier tier"
        ((validation_passed++))
        
        # Check instance count
        instance_count=$(gcloud compute instance-groups managed list-instances techcorp-$tier-mig --region=$REGION --format="value(name)" | wc -l)
        if [ $instance_count -ge 2 ]; then
            echo "✓ Instances running in $tier tier: $instance_count"
            ((validation_passed++))
        else
            echo "⚠ Low instance count in $tier tier: $instance_count"
        fi
    else
        echo "✗ Managed instance group missing for $tier tier"
        ((validation_failed++))
    fi
done

# Check auto-scalers
echo "Checking auto-scalers..."
for tier in "${tiers[@]}"; do
    if gcloud compute instance-groups managed describe techcorp-$tier-mig --region=$REGION --format="value(autoscaler)" | grep -q "techcorp-$tier-autoscaler"; then
        echo "✓ Auto-scaler configured for $tier tier"
        ((validation_passed++))
    else
        echo "✗ Auto-scaler missing for $tier tier"
        ((validation_failed++))
    fi
done

# Check health checks
echo "Checking health checks..."
for tier in "${tiers[@]}"; do
    if gcloud compute health-checks describe techcorp-$tier-health-check --global --project=$PROJECT_ID &>/dev/null; then
        echo "✓ Health check created for $tier tier"
        ((validation_passed++))
    else
        echo "✗ Health check missing for $tier tier"
        ((validation_failed++))
    fi
done

# Check load balancers
echo "Checking load balancers..."
if gcloud compute backend-services describe techcorp-web-backend --global --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Web backend service created"
    ((validation_passed++))
else
    echo "✗ Web backend service missing"
    ((validation_failed++))
fi

if gcloud compute backend-services describe techcorp-app-backend --region=$REGION --project=$PROJECT_ID &>/dev/null; then
    echo "✓ App backend service created"
    ((validation_passed++))
else
    echo "✗ App backend service missing"
    ((validation_failed++))
fi

# Check global IP and forwarding rules
echo "Checking load balancer components..."
if gcloud compute addresses describe techcorp-web-ip --global --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Global IP address reserved"
    ((validation_passed++))
else
    echo "✗ Global IP address missing"
    ((validation_failed++))
fi

if gcloud compute forwarding-rules describe techcorp-web-https --global --project=$PROJECT_ID &>/dev/null; then
    echo "✓ HTTPS forwarding rule created"
    ((validation_passed++))
else
    echo "✗ HTTPS forwarding rule missing"
    ((validation_failed++))
fi

# Check GKE cluster
echo "Checking GKE cluster..."
if gcloud container clusters describe techcorp-microservices --region=$REGION --project=$PROJECT_ID &>/dev/null; then
    echo "✓ GKE cluster created"
    ((validation_passed++))
    
    # Check node pool
    node_count=$(gcloud container clusters describe techcorp-microservices --region=$REGION --format="value(currentNodeCount)")
    if [ $node_count -gt 0 ]; then
        echo "✓ GKE nodes running: $node_count"
        ((validation_passed++))
    else
        echo "✗ No GKE nodes found"
        ((validation_failed++))
    fi
else
    echo "✗ GKE cluster missing"
    ((validation_failed++))
fi

# Check GKE service account
echo "Checking GKE service account..."
gke_sa="techcorp-gke-nodes@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe $gke_sa --project=$PROJECT_ID &>/dev/null; then
    echo "✓ GKE node service account created"
    ((validation_passed++))
else
    echo "✗ GKE node service account missing"
    ((validation_failed++))
fi

# Test application endpoints (basic connectivity)
echo "Testing application connectivity..."
global_ip=$(gcloud compute addresses describe techcorp-web-ip --global --format="value(address)" 2>/dev/null)
if [ -n "$global_ip" ]; then
    echo "✓ Global IP available: $global_ip"
    ((validation_passed++))
    
    # Test HTTP redirect (should get redirect response)
    http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://$global_ip/health" || echo "000")
    if [ "$http_status" = "301" ] || [ "$http_status" = "302" ] || [ "$http_status" = "200" ]; then
        echo "✓ HTTP endpoint responding: $http_status"
        ((validation_passed++))
    else
        echo "⚠ HTTP endpoint status: $http_status (may need time to initialize)"
    fi
else
    echo "✗ Global IP not found"
    ((validation_failed++))
fi

# Check startup scripts
echo "Checking startup scripts..."
scripts=("web-startup.sh" "app-startup.sh" "database-startup.sh")
for script in "${scripts[@]}"; do
    if [ -f "../scripts/$script" ]; then
        echo "✓ Startup script exists: $script"
        ((validation_passed++))
    else
        echo "✗ Startup script missing: $script"
        ((validation_failed++))
    fi
done

# Check Terraform outputs
echo "Checking Terraform outputs..."
cd terraform
terraform_outputs=$(terraform output -json 2>/dev/null)
if [ $? -eq 0 ] && [ "$terraform_outputs" != "{}" ]; then
    echo "✓ Terraform outputs available"
    ((validation_passed++))
    
    # Check specific outputs
    required_outputs=("instance_groups" "load_balancers" "gke_cluster" "application_endpoints")
    for output in "${required_outputs[@]}"; do
        if echo "$terraform_outputs" | jq -e ".$output" &>/dev/null; then
            echo "✓ Output available: $output"
            ((validation_passed++))
        else
            echo "✗ Output missing: $output"
            ((validation_failed++))
        fi
    done
else
    echo "✗ Terraform outputs not available"
    ((validation_failed++))
fi
cd ..

# Check integration with previous labs
echo "Checking integration with previous labs..."
cd terraform
if [ -f "terraform.tfstate" ]; then
    terraform_outputs=$(terraform output -json 2>/dev/null)
    if [ $? -eq 0 ] && [ "$terraform_outputs" != "{}" ]; then
        echo "✓ Lab 09 Terraform state accessible"
        ((validation_passed++))
    else
        echo "✗ Lab 09 Terraform outputs not available"
        ((validation_failed++))
    fi
else
    echo "✗ Lab 09 Terraform state not found"
    ((validation_failed++))
fi
cd ..

# Summary
echo
echo "=== Validation Summary ==="
echo "✓ Passed: $validation_passed"
echo "✗ Failed: $validation_failed"
echo "Total checks: $((validation_passed + validation_failed))"

if [ $validation_failed -eq 0 ]; then
    echo
    echo "🎉 Lab 09 validation PASSED!"
    echo "Ready to proceed to next lab."
    
    # Save validation results
    cat > ../outputs/lab-09-validation.json << VALIDATION_JSON_END
{
  "lab": "09",
  "status": "PASSED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID",
  "day": 2,
  "integration_verified": true
}
VALIDATION_JSON_END
    
    exit 0
else
    echo
    echo "❌ Lab 09 validation FAILED."
    echo "Please review and fix the issues above."
    
    # Save validation results
    cat > ../outputs/lab-09-validation.json << VALIDATION_JSON_END
{
  "lab": "09",
  "status": "FAILED",
  "timestamp": "$(date -Iseconds)",
  "checks_passed": $validation_passed,
  "checks_failed": $validation_failed,
  "project_id": "$PROJECT_ID",
  "day": 2,
  "integration_verified": false
}
VALIDATION_JSON_END
    
    exit 1
fi
VALIDATION_SCRIPT_END

chmod +x validation/validate-lab-09.sh

# Run validation
echo "Running Lab 09 validation..."
cd validation
./validate-lab-09.sh
cd ..
```

### Manual Verification Steps
1. **Visual Inspection**: Check GCP Console for created resources
2. **Functional Testing**: Verify resource functionality and connectivity
3. **Security Review**: Confirm security controls are properly configured
4. **Integration Testing**: Verify integration with Day 1 infrastructure
5. **Performance Testing**: Validate performance and scalability
6. **Documentation**: Ensure all configurations are documented

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Instance Template Creation Issues**
```bash
# Check required APIs
gcloud services list --enabled --filter="name:compute.googleapis.com"

# Check service account references
gcloud iam service-accounts list --filter="email:*-tier-sa@*"

# Manual template creation test
gcloud compute instance-templates create test-template --machine-type=e2-micro --image-family=ubuntu-2004-lts --image-project=ubuntu-os-cloud
```

**Issue 2: Managed Instance Group Issues**
```bash
# Check template availability
gcloud compute instance-templates list --filter="name:techcorp"

# Check network and subnet references
gcloud compute networks describe techcorp-shared-vpc
gcloud compute networks subnets list --filter="name:dev-*"
```

**Issue 3: Load Balancer Configuration Issues**
```bash
# Check health check creation
gcloud compute health-checks list --filter="name:techcorp"

# Test health check endpoint
curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone

# Check SSL certificate availability
gcloud compute ssl-certificates list --filter="name:techcorp"
```

**Issue 4: GKE Cluster Issues**
```bash
# Check GKE API enablement
gcloud services list --enabled --filter="name:container.googleapis.com"

# Check network configuration for GKE
gcloud compute networks subnets describe dev-web --region=$REGION

# Manual cluster creation test
gcloud container clusters create test-cluster --zone=us-central1-a --num-nodes=1
```

### Day 2 Specific Troubleshooting
- **Integration Issues**: Verify Day 1 labs are completed and validated
- **Resource Dependencies**: Check that prerequisite resources exist
- **Permission Issues**: Ensure service accounts have required advanced permissions
- **API Limitations**: Some advanced features may have quota or regional limitations

### Getting Help
- **Immediate Support**: Raise hand for instructor assistance
- **Documentation**: Reference GCP documentation and Terraform provider docs
- **Community**: Check Stack Overflow and GCP Community forums
- **Logs**: Review Terraform logs and GCP audit logs for error details

## Lab Completion Checklist

### Technical Deliverables
- [ ] All Terraform resources deployed successfully
- [ ] Validation script passes all checks
- [ ] Resources are properly tagged and labeled
- [ ] Security best practices implemented
- [ ] Monitoring and logging configured (where applicable)
- [ ] Integration with Day 1 infrastructure verified
- [ ] Performance and scalability validated
- [ ] Documentation updated

### Knowledge Transfer
- [ ] Understand the purpose of each component created
- [ ] Can explain the architecture to others
- [ ] Know how to troubleshoot common issues
- [ ] Familiar with relevant GCP services and features
- [ ] Understand operational procedures and maintenance

### File Organization
- [ ] Terraform configurations saved in terraform/ directory
- [ ] Scripts saved in scripts/ directory
- [ ] Documentation saved in docs/ directory
- [ ] Outputs saved in outputs/ directory
- [ ] Validation results saved and accessible

## Output Artifacts

```bash
# Save all lab outputs for future reference
mkdir -p outputs

# Terraform outputs
if [ -f terraform/terraform.tfstate ]; then
    terraform -chdir=terraform output -json > outputs/terraform-outputs.json
    echo "✓ Terraform outputs saved"
fi

# Resource inventories (enhanced for Day 2)
gcloud compute instances list --format=json > outputs/compute-instances.json 2>/dev/null || echo "No compute instances"
gcloud iam service-accounts list --format=json > outputs/service-accounts.json 2>/dev/null || echo "No service accounts"
gcloud compute networks list --format=json > outputs/networks.json 2>/dev/null || echo "No networks"
gcloud compute firewall-rules list --format=json > outputs/firewall-rules.json 2>/dev/null || echo "No firewall rules"
gcloud logging sinks list --format=json > outputs/logging-sinks.json 2>/dev/null || echo "No logging sinks"
gcloud monitoring policies list --format=json > outputs/monitoring-policies.json 2>/dev/null || echo "No monitoring policies"
gcloud dns managed-zones list --format=json > outputs/dns-zones.json 2>/dev/null || echo "No DNS zones"

# Configuration backups
cp -r terraform/ outputs/ 2>/dev/null || echo "No terraform directory to backup"
cp -r scripts/ outputs/ 2>/dev/null || echo "No scripts directory to backup"

# Create enhanced lab summary for Day 2
cat > outputs/lab-09-summary.md << 'LAB_SUMMARY_END'
# Lab 09 Summary - Day 2 Advanced Implementation

## Completed: $(date)
## Project: $PROJECT_ID
## Participant: $LAB_USER
## Workshop Day: 2 (Advanced Implementation)

### Resources Created
- [Advanced resources and configurations for Workload Environment Setup]

### Key Learnings
- [Advanced technical concepts and enterprise patterns]

### Integration Points
- Integration with Day 1 foundation (Labs 01-06)
- Dependencies on previous Day 2 labs
- Outputs for subsequent advanced labs

### Next Steps
- Proceed to Lab 10
- Review outputs for integration with subsequent labs
- Validate enterprise readiness

### Files Generated
$(ls -la outputs/)

### Day 2 Progress
Lab 09 of 14 completed (Day 2: Lab 3 of 8)
LAB_SUMMARY_END

echo "✓ Lab outputs and artifacts saved to outputs/ directory"
```

## Integration with Subsequent Labs

### Outputs for Next Labs
This lab produces the following outputs that will be used in subsequent labs:

```bash
# Display key outputs for next labs
if [ -f outputs/terraform-outputs.json ]; then
    echo "Key outputs from Lab 09:"
    cat outputs/terraform-outputs.json | jq -r 'to_entries[] | "\(.key): \(.value.value)"'
fi

# Show integration with Day 1 foundation
echo "Integration with Day 1 foundation:"
for lab in 01 02 03 04 05 06; do
    if [ -f "../lab-$lab/outputs/terraform-outputs.json" ]; then
        echo "  ✓ Lab $lab outputs available for integration"
    fi
done
```

### Dependencies for Future Labs
- **Lab 10**: Will use [specific outputs] from this lab
- **Integration Points**: [How this lab integrates with overall Day 2 architecture]
- **Enterprise Readiness**: [Production deployment considerations]

## Next Steps

### Immediate Next Steps
1. **Test Application Access**: Verify that applications are accessible through load balancers
2. **Monitor Instance Health**: Check that auto-healing and scaling policies are working
3. **Validate GKE Functionality**: Deploy test workloads to the Kubernetes cluster
4. **Prepare for Lab 10**: Workload environments will be secured with advanced controls

### Key Takeaways
- **Multi-Tier Architecture**: Proper separation and scaling of application tiers
- **High Availability**: Automatic failover and distribution across zones
- **Auto-scaling**: Dynamic resource allocation based on demand
- **Load Balancing**: Efficient traffic distribution with health monitoring
- **Container Support**: Kubernetes integration for modern microservices

### Preparation for Next Lab
1. **Ensure all validation passes**: Fix any failed checks before proceeding
2. **Review outputs**: Understand what was created and why
3. **Verify integration**: Confirm proper integration with Day 1 foundation
4. **Take a break**: Complex Day 2 labs require mental breaks between sessions
5. **Ask questions**: Clarify any concepts before moving forward

---

## Additional Resources

### Documentation References
- **GCP Documentation**: [Relevant advanced GCP service documentation]
- **Terraform Provider**: [Advanced Terraform provider documentation]
- **Enterprise Best Practices**: [Links to enterprise architectural best practices]
- **Compliance Guidelines**: [Fintech compliance and regulatory guidance]

### Code Samples
- **GitHub Repository**: [Workshop repository with complete solutions]
- **Enterprise Reference Architectures**: [GCP enterprise reference architectures]
- **Production Patterns**: [Real-world production implementation examples]

---

**Lab 09 Complete** ✅

**Estimated Time for Completion**: 60 minutes
**Next Lab**: Lab 10 - [Next lab title]

*Day 2 Focus: Advanced enterprise implementations for production readiness*


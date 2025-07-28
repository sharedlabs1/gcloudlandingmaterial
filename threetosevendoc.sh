#!/bin/bash

# Continue creating concept guides for Labs 03-07
echo "Creating concept guides for Labs 03-07..."

# Lab 03 Concepts - Core Networking Architecture
cat > workshop-materials/docs/guides/lab-03-concepts.md << 'LAB03_CONCEPTS_END'
# Lab 03 Concepts: Core Networking Architecture

## Learning Objectives
After completing this lab, you will understand:
- Multi-tier network architecture design and implementation
- Load balancing strategies and health check mechanisms
- Auto-scaling patterns and instance group management
- Firewall rule design and network security micro-segmentation
- Application deployment automation and startup scripts

---

## Core Concepts

### 1. Multi-Tier Network Architecture

#### Architectural Pattern
```
┌─────────────────────────────────────────────────────────────┐
│                Multi-Tier Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Internet                    DMZ                   Internal  │
│  ┌─────────┐    ┌─────────────────────┐    ┌─────────────┐  │
│  │ Users   │───→│    Web Tier         │───→│  App Tier   │  │
│  │External │    │  ┌───────────────┐  │    │ ┌─────────┐ │  │
│  │Traffic  │    │  │Load Balancer  │  │    │ │Business │ │  │
│  └─────────┘    │  │Global/Regional│  │    │ │Logic    │ │  │
│                 │  │Health Checks  │  │    │ │Services │ │  │
│                 │  └───────────────┘  │    │ │APIs     │ │  │
│                 │  ┌───────────────┐  │    │ └─────────┘ │  │
│                 │  │Web Servers    │  │    │ ┌─────────┐ │  │
│                 │  │Auto-scaling   │  │    │ │Internal │ │  │
│                 │  │Instance Groups│  │    │ │Load Bal │ │  │
│                 │  └───────────────┘  │    │ └─────────┘ │  │
│                 └─────────────────────┘    └─────────────┘  │
│                           │                        │        │
│                           ▼                        ▼        │
│                 ┌─────────────────────┐    ┌─────────────┐  │
│                 │   Data Tier         │    │ Management  │  │
│                 │ ┌─────────────────┐ │    │ ┌─────────┐ │  │
│                 │ │ Databases       │ │    │ │Bastion  │ │  │
│                 │ │ Cloud SQL       │ │    │ │Hosts    │ │  │
│                 │ │ BigQuery        │ │    │ │Monitor  │ │  │
│                 │ │ Storage         │ │    │ │Logging  │ │  │
│                 │ └─────────────────┘ │    │ └─────────┘ │  │
│                 └─────────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### Design Principles
- **Separation of Concerns**: Each tier has specific responsibilities
- **Network Isolation**: Controlled communication between tiers
- **Scalability**: Independent scaling of each tier
- **Security**: Progressive security controls per tier
- **Maintainability**: Modular deployment and updates

#### Subnet Strategy
```hcl
# Subnet design for multi-tier architecture
variable "subnets" {
  description = "Multi-tier subnet configuration"
  type = map(object({
    cidr                   = string
    region                 = string
    tier                   = string
    internet_access        = bool
    private_google_access  = bool
    flow_logs_enabled      = bool
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  
  default = {
    "web-tier-subnet" = {
      cidr                  = "10.1.0.0/22"
      region               = "us-central1"
      tier                 = "web"
      internet_access      = true
      private_google_access = true
      flow_logs_enabled    = true
      secondary_ranges = [
        {
          range_name    = "web-services"
          ip_cidr_range = "10.1.16.0/20"
        }
      ]
    }
    "app-tier-subnet" = {
      cidr                  = "10.1.4.0/22"
      region               = "us-central1"
      tier                 = "application"
      internet_access      = false
      private_google_access = true
      flow_logs_enabled    = true
      secondary_ranges = [
        {
          range_name    = "app-services"
          ip_cidr_range = "10.1.32.0/20"
        }
      ]
    }
    "data-tier-subnet" = {
      cidr                  = "10.1.8.0/22"
      region               = "us-central1"
      tier                 = "data"
      internet_access      = false
      private_google_access = true
      flow_logs_enabled    = true
      secondary_ranges = []
    }
  }
}
```

### 2. Load Balancing Architecture

#### Load Balancer Types and Use Cases
```
┌─────────────────────────────────────────────────────────────┐
│                Load Balancing Strategy                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Global Load Balancer (Layer 7 - HTTP/HTTPS)               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │ │ Anycast IP  │    │ URL Mapping │    │ SSL Offload │ │ │
│  │ │ Global      │    │ Path/Host   │    │ Certificate │ │ │
│  │ │ Availability│    │ Based       │    │ Management  │ │ │
│  │ └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  │                                                         │ │
│  │ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │ │ CDN         │    │ Cloud Armor │    │ Health      │ │ │
│  │ │ Integration │    │ WAF/DDoS    │    │ Checks      │ │ │
│  │ │ Static      │    │ Protection  │    │ Monitoring  │ │ │
│  │ └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Regional Load Balancer (Layer 4 - TCP/UDP)                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │ │ Regional    │    │ Port        │    │ Session     │ │ │
│  │ │ Availability│    │ Forwarding  │    │ Affinity    │ │ │
│  │ │ Multi-zone  │    │ Rules       │    │ Client IP   │ │ │
│  │ └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Internal Load Balancer                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │ │ Private     │    │ Service     │    │ Cross-Zone  │ │ │
│  │ │ IP Range    │    │ Discovery   │    │ Load        │ │ │
│  │ │ Internal    │    │ Mesh        │    │ Balancing   │ │ │
│  │ └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Global Load Balancer Configuration
```hcl
# Global Load Balancer with URL mapping
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "techcorp-https-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range           = "443"
  target               = google_compute_target_https_proxy.https_proxy.id
  ip_address           = google_compute_global_address.lb_ip.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = "techcorp-https-proxy"
  url_map = google_compute_url_map.url_map.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_certificate.id
  ]
}

resource "google_compute_url_map" "url_map" {
  name            = "techcorp-url-map"
  default_service = google_compute_backend_service.web_backend.id

  host_rule {
    hosts        = ["app.techcorp.com"]
    path_matcher = "app-paths"
  }

  path_matcher {
    name            = "app-paths"
    default_service = google_compute_backend_service.web_backend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api_backend.id
    }

    path_rule {
      paths   = ["/admin/*"]
      service = google_compute_backend_service.admin_backend.id
    }
  }
}
```

#### Health Check Configuration
```hcl
resource "google_compute_health_check" "web_health_check" {
  name                = "web-tier-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    request_path         = "/health"
    port                 = 80
    host                 = "localhost"
    proxy_header        = "NONE"
  }

  log_config {
    enable = true
  }
}

resource "google_compute_health_check" "app_health_check" {
  name                = "app-tier-health-check"
  check_interval_sec  = 15
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 5

  http_health_check {
    request_path = "/api/health"
    port         = 8080
    host         = "localhost"
  }
}
```

### 3. Auto-Scaling and Instance Management

#### Instance Group Architecture
```
┌─────────────────────────────────────────────────────────────┐
│              Auto-Scaling Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Managed Instance Group (MIG)                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Instance Template                                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Machine     │  │ Boot Disk   │  │ Network     │ ││ │
│  │  │ │ Type        │  │ Image       │  │ Tags        │ ││ │
│  │  │ │ Metadata    │  │ Size        │  │ Service     │ ││ │
│  │  │ └─────────────┘  └─────────────┘  │ Account     │ ││ │
│  │  │                                   └─────────────┘ ││ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Startup     │  │ Preemptible │  │ Labels      │ ││ │
│  │  │ │ Script      │  │ Policy      │  │ & Tags      │ ││ │
│  │  │ │ Automation  │  │ Cost Opt    │  │ Resource    │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Auto-Scaling Policy                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ CPU         │  │ Custom      │  │ Scaling     │ ││ │
│  │  │ │ Utilization │  │ Metrics     │  │ Schedule    │ ││ │
│  │  │ │ Target 60%  │  │ Queue Depth │  │ Time-based  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  │                                                   ││ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Min/Max     │  │ Cooldown    │  │ Scale Up/   │ ││ │
│  │  │ │ Instances   │  │ Period      │  │ Down Policy │ ││ │
│  │  │ │ 2 / 20      │  │ 300 sec     │  │ Gradual     │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Instance Template Configuration
```hcl
resource "google_compute_instance_template" "web_tier_template" {
  name_prefix  = "web-tier-template-"
  machine_type = "e2-medium"
  region       = var.region

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = data.terraform_remote_state.lab02.outputs.network_config.subnets["web-tier"].self_link
    access_config {
      // Ephemeral external IP
      nat_ip = null
    }
  }

  service_account {
    email = data.terraform_remote_state.lab01.outputs.service_accounts["web-tier-sa"].email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  metadata = {
    startup-script = file("${path.module}/scripts/web-tier-startup.sh")
    tier          = "web"
    environment   = var.environment
  }

  tags = ["web-tier", "http-server", "https-server"]

  labels = local.common_labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web_tier_mig" {
  name   = "web-tier-mig"
  region = var.region

  base_instance_name = "web-tier"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.web_tier_template.id
  }

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https" 
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web_health_check.id
    initial_delay_sec = 120
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action              = "REPLACE"
    max_surge_fixed             = 2
    max_unavailable_fixed       = 0
  }
}

resource "google_compute_region_autoscaler" "web_tier_autoscaler" {
  name   = "web-tier-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.web_tier_mig.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 300

    cpu_utilization {
      target = 0.6
    }

    metric {
      name   = "compute.googleapis.com/instance/network/received_bytes_count"
      target = 100
      type   = "GAUGE"
    }

    scale_in_control {
      max_scaled_in_replicas {
        fixed = 2
      }
      time_window_sec = 300
    }
  }
}
```

### 4. Firewall Rules and Network Security

#### Micro-Segmentation Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                Firewall Rule Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Ingress Rules (Inbound Traffic)                            │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Internet → Web Tier                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Source: 0.0.0.0/0                                  ││ │
│  │  │ Target: web-tier tag                               ││ │
│  │  │ Ports: 80, 443                                     ││ │
│  │  │ Protocol: TCP                                       ││ │
│  │  │ Priority: 1000                                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Web Tier → App Tier                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Source: web-tier tag                               ││ │
│  │  │ Target: app-tier tag                               ││ │
│  │  │ Ports: 8080, 8443                                 ││ │
│  │  │ Protocol: TCP                                       ││ │
│  │  │ Priority: 1100                                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  App Tier → Data Tier                                   │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Source: app-tier tag                               ││ │
│  │  │ Target: data-tier tag                              ││ │
│  │  │ Ports: 3306, 5432, 27017                          ││ │
│  │  │ Protocol: TCP                                       ││ │
│  │  │ Priority: 1200                                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Management → All Tiers                                 │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Source: management-subnet                          ││ │
│  │  │ Target: all-tiers tag                              ││ │
│  │  │ Ports: 22, 3389                                    ││ │
│  │  │ Protocol: TCP                                       ││ │
│  │  │ Priority: 900                                       ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  Egress Rules (Outbound Traffic)                            │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Default Deny All                                       │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Target: all instances                              ││ │
│  │  │ Destination: 0.0.0.0/0                            ││ │
│  │  │ Action: DENY                                        ││ │
│  │  │ Priority: 65534                                     ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Allow Google APIs                                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Target: all-tiers tag                              ││ │
│  │  │ Destination: 199.36.153.8/30                       ││ │
│  │  │ Action: ALLOW                                       ││ │
│  │  │ Priority: 1000                                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Allow Package Updates                                  │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Target: all-tiers tag                              ││ │
│  │  │ Destination: 0.0.0.0/0                            ││ │
│  │  │ Ports: 80, 443                                     ││ │
│  │  │ Priority: 1100                                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Firewall Rule Implementation
```hcl
# Ingress rules for multi-tier architecture
resource "google_compute_firewall" "allow_web_ingress" {
  name    = "allow-web-ingress"
  network = data.terraform_remote_state.lab02.outputs.network_config.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-tier"]
  priority      = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_web_to_app" {
  name    = "allow-web-to-app"
  network = data.terraform_remote_state.lab02.outputs.network_config.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_tags = ["web-tier"]
  target_tags = ["app-tier"]
  priority    = 1100
}

resource "google_compute_firewall" "allow_app_to_data" {
  name    = "allow-app-to-data"
  network = data.terraform_remote_state.lab02.outputs.network_config.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["3306", "5432", "27017", "6379"]
  }

  source_tags = ["app-tier"]
  target_tags = ["data-tier"]
  priority    = 1200
}

resource "google_compute_firewall" "allow_management_ssh" {
  name    = "allow-management-ssh"
  network = data.terraform_remote_state.lab02.outputs.network_config.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    data.terraform_remote_state.lab02.outputs.network_config.subnets["management"].cidr
  ]
  target_tags = ["ssh-access"]
  priority    = 900
}

# Egress rules for controlled outbound access
resource "google_compute_firewall" "deny_all_egress" {
  name      = "deny-all-egress"
  network   = data.terraform_remote_state.lab02.outputs.network_config.vpc_name
  direction = "EGRESS"

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  priority          = 65534
}

resource "google_compute_firewall" "allow_google_apis_egress" {
  name      = "allow-google-apis-egress"
  network   = data.terraform_remote_state.lab02.outputs.network_config.vpc_name
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = [
    "199.36.153.8/30",    # private.googleapis.com
    "199.36.153.4/30"     # restricted.googleapis.com
  ]
  target_tags = ["google-apis-access"]
  priority    = 1000
}
```

### 5. Application Deployment Automation

#### Startup Script Architecture
```bash
#!/bin/bash
# Web Tier Startup Script - Comprehensive Application Bootstrap

# Variables from instance metadata
TIER=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/tier)
ENVIRONMENT=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment)
PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)

# Logging setup
exec > >(tee -a /var/log/startup-script.log)
exec 2>&1
echo "Starting ${TIER} tier deployment in ${ENVIRONMENT} environment"

# System preparation
apt-get update
apt-get install -y nginx docker.io docker-compose jq awscli

# Configure nginx
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Application proxy
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Health check for load balancer
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static content
    location /static/ {
        alias /var/www/static/;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_CONFIG

# Configure application
mkdir -p /opt/techcorp-app
cat > /opt/techcorp-app/docker-compose.yml << 'DOCKER_COMPOSE'
version: '3.8'
services:
  web-app:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./app:/usr/share/nginx/html
    environment:
      - TIER=${TIER}
      - ENVIRONMENT=${ENVIRONMENT}
      - PROJECT_ID=${PROJECT_ID}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  monitoring-agent:
    image: gcr.io/google-containers/cadvisor:latest
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped
DOCKER_COMPOSE

# Create application content
mkdir -p /opt/techcorp-app/app
cat > /opt/techcorp-app/app/index.html << 'HTML_CONTENT'
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Application - Web Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { color: #28a745; font-weight: bold; }
        .info { margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 TechCorp Application</h1>
        <div class="status">Status: Online</div>
        <div class="info">Tier: Web</div>
        <div class="info">Environment: Production</div>
        <div class="info">Instance: <span id="instance"></span></div>
        <div class="info">Timestamp: <span id="timestamp"></span></div>
    </div>
    <script>
        document.getElementById('instance').textContent = window.location.hostname;
        document.getElementById('timestamp').textContent = new Date().toISOString();
    </script>
</body>
</html>
HTML_CONTENT

# Start services
systemctl enable nginx
systemctl start nginx
systemctl enable docker
systemctl start docker

cd /opt/techcorp-app
docker-compose up -d

# Configure monitoring
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
bash add-monitoring-agent-repo.sh
apt-get update
apt-get install -y stackdriver-agent

# Install logging agent
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update
apt-get install -y google-fluentd

# Configure log forwarding
cat > /etc/google-fluentd/config.d/nginx.conf << 'FLUENTD_CONFIG'
<source>
  @type tail
  path /var/log/nginx/access.log
  pos_file /var/lib/google-fluentd/pos/nginx-access.log.pos
  read_from_head true
  tag nginx.access
  format nginx
</source>

<source>
  @type tail
  path /var/log/nginx/error.log
  pos_file /var/lib/google-fluentd/pos/nginx-error.log.pos
  read_from_head true
  tag nginx.error
  format /^(?<time>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(?<log_level>\w+)\] (?<message>.*)$/
</source>
FLUENTD_CONFIG

systemctl restart google-fluentd

echo "Web tier startup complete - $(date)"
```

---

## Integration Patterns

### 1. Lab-to-Lab Dependencies
```
Lab 02 Outputs → Lab 03 Inputs
├── VPC Network → Instance Templates
├── Subnets → Instance Groups  
├── Service Accounts → Compute Instances
└── NAT Gateway → Internet Access

Lab 03 Outputs → Lab 04 Inputs
├── Load Balancer → Cloud Armor Policy
├── Instance Groups → Security Policies
├── Firewall Rules → WAF Rules
└── Health Checks → DDoS Protection
```

### 2. Service Integration
```hcl
# Integration with previous labs
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

# Using service accounts from Lab 01
locals {
  service_accounts = data.terraform_remote_state.lab01.outputs.service_accounts
  network_config   = data.terraform_remote_state.lab02.outputs.network_config
}

# Creating resources with integrated dependencies
resource "google_compute_backend_service" "web_backend" {
  name        = "web-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30
  
  backend {
    group                 = google_compute_region_instance_group_manager.web_tier_mig.instance_group
    balancing_mode        = "UTILIZATION"
    max_utilization       = 0.8
    capacity_scaler       = 1.0
  }
  
  health_checks = [google_compute_health_check.web_health_check.id]
  
  # Integrate with Cloud Armor (Lab 04)
  security_policy = var.enable_cloud_armor ? google_compute_security_policy.web_security_policy[0].id : null
}
```

---

## Best Practices and Optimization

### 1. Performance Optimization
- **Instance Sizing**: Right-size instances based on workload requirements
- **Disk Performance**: Use appropriate disk types (pd-ssd for high IOPS)
- **Network Optimization**: Optimize placement and network proximity
- **Caching Strategy**: Implement CDN and application-level caching

### 2. Cost Optimization
- **Preemptible Instances**: Use for non-critical workloads
- **Automatic Scaling**: Scale down during low-usage periods
- **Resource Scheduling**: Start/stop development environments
- **Monitoring Costs**: Track resource usage and optimization opportunities

### 3. Reliability Patterns
- **Multi-Zone Deployment**: Distribute instances across zones
- **Health Checking**: Comprehensive health monitoring
- **Graceful Degradation**: Handle partial failures gracefully
- **Circuit Breaker**: Prevent cascade failures

---

## Troubleshooting Guide

### Load Balancer Issues
```bash
# Check backend health
gcloud compute backend-services get-health web-backend-service --global

# Verify health check configuration
gcloud compute health-checks describe web-tier-health-check

# Test connectivity
curl -I http://LOAD_BALANCER_IP/health
```

### Instance Group Issues
```bash
# Check autoscaler status
gcloud compute region-autoscalers describe web-tier-autoscaler --region=us-central1

# View instance group details
gcloud compute instance-groups managed describe web-tier-mig --region=us-central1

# Check instance template
gcloud compute instance-templates describe web-tier-template
```

### Firewall Troubleshooting
```bash
# List firewall rules
gcloud compute firewall-rules list --sort-by=priority

# Test connectivity
telnet TARGET_IP TARGET_PORT

# Check VPC flow logs (if enabled)
gcloud logging read "resource.type=gce_subnetwork"
```

---

## Assessment Questions

1. **How does multi-tier architecture improve security and scalability?**
2. **What are the differences between global and regional load balancers?**
3. **How do managed instance groups ensure high availability?**
4. **What considerations are important for firewall rule design?**
5. **How does auto-scaling help with cost optimization and performance?**

---

## Additional Resources

### Documentation
- [GCP Load Balancing](https://cloud.google.com/load-balancing/docs)
- [Managed Instance Groups](https://cloud.google.com/compute/docs/instance-groups)
- [VPC Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [Compute Engine Best Practices](https://cloud.google.com/compute/docs/best-practices)

### Monitoring and Troubleshooting
- [Instance Group Monitoring](https://cloud.google.com/monitoring/support/metrics#gce-instance-group)
- [Load Balancer Monitoring](https://cloud.google.com/monitoring/support/metrics#lb-metrics)
- [Network Troubleshooting](https://cloud.google.com/vpc/docs/troubleshooting)
LAB03_CONCEPTS_END

# Lab 04 Concepts - Network Security Implementation
cat > workshop-materials/docs/guides/lab-04-concepts.md << 'LAB04_CONCEPTS_END'
# Lab 04 Concepts: Network Security Implementation

## Learning Objectives
After completing this lab, you will understand:
- Cloud Armor security policies and Web Application Firewall (WAF) rules
- DDoS protection mechanisms and attack mitigation strategies
- Rate limiting and bot protection implementation
- Geo-blocking and IP reputation-based security controls
- Security monitoring and incident response automation

---

## Core Concepts

### 1. Cloud Armor Security Framework

#### Cloud Armor Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                 Cloud Armor Security Stack                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Edge Security (Global)                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ DDoS        │  │ Geo-blocking│  │ IP Reputation │   │ │
│  │ │ Protection  │  │ Countries   │  │ Known Bad    │   │ │
│  │ │ Auto-Scale  │  │ Regions     │  │ Threat Intel │   │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Layer 2: Application Security (WAF)                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ OWASP       │  │ SQL         │  │ XSS         │     │ │
│  │ │ Top 10      │  │ Injection   │  │ Protection  │     │ │
│  │ │ Rules       │  │ Detection   │  │ Filtering   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Custom      │  │ Signature   │  │ Behavioral  │     │ │
│  │ │ Rules       │  │ Based       │  │ Analysis    │     │ │
│  │ │ Business    │  │ Detection   │  │ ML-Based    │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Layer 3: Rate Limiting & Bot Protection                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Request     │  │ Bot         │  │ Adaptive    │     │ │
│  │ │ Rate Limits │  │ Detection   │  │ Protection  │     │ │
│  │ │ Per-Client  │  │ ML-based    │  │ Auto-tune   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Layer 4: Monitoring & Response                            │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Real-time   │  │ Security    │  │ Automated   │     │ │
│  │ │ Monitoring  │  │ Analytics   │  │ Response    │     │ │
│  │ │ Dashboards  │  │ Threat Intel│  │ Mitigation  │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Security Policy Implementation
```hcl
resource "google_compute_security_policy" "techcorp_security_policy" {
  name        = "techcorp-web-security-policy"
  description = "Comprehensive security policy for TechCorp web applications"

  # Default rule - allow all traffic (will be overridden by specific rules)
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # Block known malicious countries (adjust based on business requirements)
  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      expr {
        expression = "origin.region_code == 'CN' || origin.region_code == 'RU' || origin.region_code == 'KP'"
      }
    }
    description = "Block traffic from high-risk countries"
  }

  # Rate limiting rule - prevent excessive requests
  rule {
    action   = "rate_based_ban"
    priority = 1100
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 600
    }
    description = "Rate limit excessive requests"
  }

  # Block SQL injection attempts
  rule {
    action   = "deny(403)"
    priority = 1200
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "Block SQL injection attempts"
  }

  # Block XSS attempts
  rule {
    action   = "deny(403)"
    priority = 1300
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "Block XSS attempts"
  }

  # Block Remote Code Execution attempts
  rule {
    action   = "deny(403)"
    priority = 1400
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rce-stable')"
      }
    }
    description = "Block remote code execution attempts"
  }

  # Custom rule for admin path protection
  rule {
    action   = "deny(403)"
    priority = 1500
    match {
      expr {
        expression = "request.path.matches('/admin') && !inIpRange(origin.ip, '10.0.0.0/24')"
      }
    }
    description = "Restrict admin access to management subnet"
  }

  # Bot protection rule
  rule {
    action   = "deny(403)"
    priority = 1600
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('methodenforcement-stable') || evaluatePreconfiguredExpr('scannerdetection-stable')"
      }
    }
    description = "Block automated scanning and invalid methods"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }
}
```

### 2. DDoS Protection and Mitigation

#### DDoS Protection Layers
```
┌─────────────────────────────────────────────────────────────┐
│                 DDoS Protection Architecture                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Network Layer Protection (L3/L4)                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Volumetric Attack Protection                           │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Traffic Volume: Up to 2.5 Tbps absorption          ││ │
│  │  │ Packet Rate: Millions of packets per second        ││ │
│  │  │ Global Network: 100+ PoPs worldwide                ││ │
│  │  │ Anycast: Distributed traffic across network        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Protocol Attack Protection                             │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ SYN Floods: Connection state tracking               ││ │
│  │  │ UDP Floods: Rate limiting and validation           ││ │
│  │  │ ICMP Floods: Protocol-specific filtering           ││ │
│  │  │ Fragmentation: Packet reassembly attacks           ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Application Layer Protection (L7)                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  HTTP/HTTPS Attack Protection                           │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Slowloris: Connection exhaustion                   ││ │
│  │  │ HTTP Floods: Request rate limiting                 ││ │
│  │  │ SSL Exhaustion: Certificate validation attacks     ││ │
│  │  │ Cache Busting: Randomized parameter attacks        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Adaptive Protection (ML-based)                        │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Behavioral Analysis: Traffic pattern learning      ││ │
│  │  │ Anomaly Detection: Statistical deviation analysis  ││ │
│  │  │ Auto-mitigation: Dynamic rule generation           ││ │
│  │  │ Threat Intelligence: Known attack signatures       ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Adaptive Protection Configuration
```hcl
resource "google_compute_security_policy" "adaptive_protection" {
  name        = "techcorp-adaptive-security-policy"
  description = "ML-based adaptive protection for DDoS and application attacks"

  # Enable adaptive protection with machine learning
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
      
      threshold_configs {
        name           = "high-traffic-threshold"
        auto_deploy_load_threshold        = 0.8
        auto_deploy_confidence_threshold  = 0.8
        auto_deploy_impacted_baseline_threshold = 0.1
      }
    }
  }

  # Custom rule for adaptive protection
  rule {
    action   = "deny(403)"
    priority = 900
    match {
      expr {
        expression = "evaluateAdaptiveProtectionAutoDeploy()"
      }
    }
    description = "Adaptive protection auto-deployed rules"
    header_action {
      request_headers_to_add {
        header_name  = "X-Cloud-Armor-Action"
        header_value = "adaptive-protection-block"
      }
    }
  }

  # Advanced rate limiting with multiple keys
  rule {
    action   = "rate_based_ban"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "ALL"
      enforce_on_key_configs {
        enforce_on_key_type = "IP"
      }
      enforce_on_key_configs {
        enforce_on_key_type = "HTTP_HEADER"
        enforce_on_key_name = "User-Agent"
      }
      rate_limit_threshold {
        count        = 500
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Multi-key rate limiting"
  }
}
```

### 3. Web Application Firewall (WAF) Rules

#### OWASP Top 10 Protection
```hcl
# Comprehensive WAF rule set covering OWASP Top 10
locals {
  waf_rules = {
    # A01: Broken Access Control
    "access-control" = {
      priority    = 2000
      expression  = "request.path.matches('/admin') && !has(request.headers['authorization'])"
      action      = "deny(403)"
      description = "Block unauthorized admin access"
    }
    
    # A02: Cryptographic Failures
    "crypto-failures" = {
      priority    = 2100
      expression  = "request.query.matches('.*\\\\.(key|pem|p12|pfx).*')"
      action      = "deny(403)"
      description = "Block requests for cryptographic files"
    }
    
    # A03: Injection (SQL, NoSQL, OS, LDAP)
    "injection-protection" = {
      priority    = 2200
      expression  = "evaluatePreconfiguredExpr('sqli-stable') || evaluatePreconfiguredExpr('rce-stable')"
      action      = "deny(403)"
      description = "Block injection attacks"
    }
    
    # A04: Insecure Design
    "insecure-design" = {
      priority    = 2300
      expression  = "request.path.matches('.*\\\\.(env|config|ini|log)$')"
      action      = "deny(403)"
      description = "Block access to configuration files"
    }
    
    # A05: Security Misconfiguration
    "security-misconfig" = {
      priority    = 2400
      expression  = "request.path.matches('.*(\\\\.git|\\\\.svn|\\\\.hg)/.*') || request.headers['server'].contains('Apache/2.2')"
      action      = "deny(403)"
      description = "Block access to version control and vulnerable servers"
    }
    
    # A06: Vulnerable and Outdated Components
    "vulnerable-components" = {
      priority    = 2500
      expression  = "request.headers['user-agent'].matches('.*curl.*|.*wget.*|.*nikto.*|.*sqlmap.*')"
      action      = "deny(403)"
      description = "Block known scanning tools"
    }
    
    # A07: Identification and Authentication Failures
    "auth-failures" = {
      priority    = 2600
      expression  = "request.path.matches('/login') && size(request.body) > 1000"
      action      = "deny(413)"
      description = "Block oversized login requests"
    }
    
    # A08: Software and Data Integrity Failures
    "integrity-failures" = {
      priority    = 2700
      expression  = "request.headers['content-type'].contains('application/java-archive')"
      action      = "deny(403)"
      description = "Block Java archive uploads"
    }
    
    # A09: Security Logging and Monitoring Failures
    "logging-monitoring" = {
      priority    = 2800
      expression  = "request.path.matches('/api/.*') && !has(request.headers['x-request-id'])"
      action      = "allow"
      description = "Allow but flag API requests without tracking"
      header_action = {
        request_headers_to_add = [
          {
            header_name  = "X-Missing-Request-ID"
            header_value = "true"
          }
        ]
      }
    }
    
    # A10: Server-Side Request Forgery (SSRF)
    "ssrf-protection" = {
      priority    = 2900
      expression  = "request.query.matches('.*url=.*localhost.*|.*url=.*127\\\\.0\\\\.0\\\\.1.*|.*url=.*169\\\\.254\\\\.169\\\\.254.*')"
      action      = "deny(403)"
      description = "Block SSRF attempts"
    }
  }
}

# Dynamic WAF rule creation
resource "google_compute_security_policy_rule" "waf_rules" {
  for_each = local.waf_rules
  
  security_policy = google_compute_security_policy.techcorp_security_policy.name
  priority        = each.value.priority
  action          = each.value.action
  description     = each.value.description
  
  match {
    expr {
      expression = each.value.expression
    }
  }
  
  dynamic "header_action" {
    for_each = can(each.value.header_action) ? [each.value.header_action] : []
    content {
      dynamic "request_headers_to_add" {
        for_each = header_action.value.request_headers_to_add
        content {
          header_name  = request_headers_to_add.value.header_name
          header_value = request_headers_to_add.value.header_value
        }
      }
    }
  }
}
```

### 4. Geo-blocking and IP Reputation

#### Geographic Access Control
```hcl
# Geo-blocking configuration for compliance and security
resource "google_compute_security_policy" "geo_security_policy" {
  name        = "techcorp-geo-security-policy"
  description = "Geographic access control and IP reputation filtering"
  
  # Allow specific countries for business operations
  rule {
    action   = "allow"
    priority = 1000
    match {
      expr {
        expression = "origin.region_code == 'US' || origin.region_code == 'CA' || origin.region_code == 'GB' || origin.region_code == 'DE' || origin.region_code == 'FR'"
      }
    }
    description = "Allow access from approved countries"
  }
  
  # Block high-risk countries
  rule {
    action   = "deny(403)"
    priority = 1100
    match {
      expr {
        expression = "origin.region_code in ['CN', 'RU', 'KP', 'IR', 'SY']"
      }
    }
    description = "Block access from high-risk countries"
  }
  
  # Allow from specific regions for partners
  rule {
    action   = "allow"
    priority = 1200
    match {
      expr {
        expression = "origin.region_code == 'JP' && request.path.startsWith('/partner-api/')"
      }
    }
    description = "Allow partner API access from Japan"
  }
  
  # Block known malicious IP ranges
  rule {
    action   = "deny(403)"
    priority = 1300
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "1.2.3.0/24",      # Example malicious range
          "192.0.2.0/24",    # Example suspicious range
          "198.51.100.0/24", # Example blocked range
        ]
      }
    }
    description = "Block known malicious IP ranges"
  }
  
  # Default deny for unspecified regions (optional - use with caution)
  rule {
    action   = "deny(403)"
    priority = 2000
    match {
      expr {
        expression = "true"
      }
    }
    description = "Default deny for security"
  }
}

# IP reputation and threat intelligence integration
resource "google_compute_security_policy" "threat_intel_policy" {
  name        = "techcorp-threat-intel-policy"
  description = "Threat intelligence and IP reputation based blocking"
  
  # Block known botnet IPs (example - integrate with threat intel feeds)
  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.known_botnet_ips
      }
    }
    description = "Block known botnet IP addresses"
  }
  
  # Rate limit suspicious regions
  rule {
    action   = "rate_based_ban"
    priority = 1100
    match {
      expr {
        expression = "origin.region_code in ['VN', 'PK', 'BD', 'IN'] && !inIpRange(origin.ip, '10.0.0.0/8')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 10
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Rate limit traffic from suspicious regions"
  }
}
```

### 5. Advanced Rate Limiting and Bot Protection

#### Multi-dimensional Rate Limiting
```hcl
resource "google_compute_security_policy" "advanced_rate_limiting" {
  name        = "techcorp-advanced-rate-limiting"
  description = "Multi-dimensional rate limiting and bot protection"
  
  # Per-IP rate limiting
  rule {
    action   = "rate_based_ban"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 1000
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Per-IP rate limiting"
  }
  
  # Per-User-Agent rate limiting
  rule {
    action   = "rate_based_ban"
    priority = 1100
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "HTTP_HEADER"
      enforce_on_key_name = "User-Agent"
      rate_limit_threshold {
        count        = 5000
        interval_sec = 60
      }
      ban_duration_sec = 600
    }
    description = "Per-User-Agent rate limiting"
  }
  
  # API endpoint specific rate limiting
  rule {
    action   = "rate_based_ban"
    priority = 1200
    match {
      expr {
        expression = "request.path.startsWith('/api/v1/login')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 5
        interval_sec = 300
      }
      ban_duration_sec = 1800
    }
    description = "Login endpoint rate limiting"
  }
  
  # Bot detection and protection
  rule {
    action   = "deny(403)"
    priority = 1300
    match {
      expr {
        expression = <<-EOT
          request.headers['user-agent'].matches('(?i).*(bot|crawler|spider|scraper).*') &&
          !request.headers['user-agent'].matches('(?i).*(googlebot|bingbot|slurp|duckduckbot|baiduspider|yandexbot|facebookexternalhit|twitterbot|linkedinbot|whatsapp|applebot).*')
        EOT
      }
    }
    description = "Block unauthorized bots and scrapers"
  }
  
  # Headless browser detection
  rule {
    action   = "deny(403)"
    priority = 1400
    match {
      expr {
        expression = <<-EOT
          request.headers['user-agent'].matches('(?i).*(headless|phantom|selenium|puppeteer|playwright).*') ||
          request.headers['user-agent'].matches('(?i).*chrome.*headless.*')
        EOT
      }
    }
    description = "Block headless browsers and automation tools"
  }
}
```

---

## Integration with Monitoring and Alerting

### 1. Security Monitoring Dashboard
```hcl
# Cloud Armor monitoring and alerting
resource "google_monitoring_alert_policy" "cloud_armor_high_blocked_requests" {
  display_name = "Cloud Armor - High Blocked Request Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Blocked request rate > 100/min"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 100
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.backend_service_name"]
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.security_alerts.id
  ]
  
  alert_strategy {
    auto_close = "86400s"
  }
}

resource "google_monitoring_alert_policy" "cloud_armor_ddos_detection" {
  display_name = "Cloud Armor - Potential DDoS Attack"
  combiner     = "OR"
  
  conditions {
    display_name = "Request rate spike > 1000% increase"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
      duration        = "60s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 10000
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.security_critical.id
  ]
}
```

### 2. Security Incident Response
```hcl
# Automated security response using Cloud Functions
resource "google_cloudfunctions_function" "security_incident_response" {
  name        = "security-incident-response"
  description = "Automated security incident response function"
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.security_function_zip.name
  
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.security_alerts.name
  }
  
  entry_point = "security_incident_handler"
  
  environment_variables = {
    PROJECT_ID = var.project_id
    SLACK_WEBHOOK = var.security_slack_webhook
    SECURITY_POLICY = google_compute_security_policy.techcorp_security_policy.name
  }
}

# Security alerting topic
resource "google_pubsub_topic" "security_alerts" {
  name = "security-alerts"
}

# Log sink for security events
resource "google_logging_project_sink" "security_events_sink" {
  name = "security-events-sink"
  
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.security_alerts.name}"
  
  filter = <<-EOT
    resource.type="gce_backend_service" AND
    protoPayload.methodName="compute.backendServices.patch" AND
    protoPayload.resourceName=~".*security.*"
  EOT
  
  unique_writer_identity = true
}
```

---

## Best Practices and Optimization

### 1. Security Policy Management
- **Layered Security**: Implement multiple security layers
- **Regular Updates**: Keep security rules current with threat landscape
- **Performance Testing**: Ensure security rules don't impact performance
- **False Positive Management**: Monitor and tune rules to minimize false positives

### 2. Monitoring and Alerting
- **Real-time Monitoring**: Set up continuous security monitoring
- **Incident Response**: Automate initial response to security events
- **Forensic Logging**: Maintain detailed logs for security analysis
- **Threat Intelligence**: Integrate external threat feeds

### 3. Compliance and Governance
- **Regular Audits**: Conduct security policy reviews
- **Documentation**: Maintain comprehensive security documentation
- **Change Management**: Implement controlled security policy changes
- **Training**: Keep security team updated on latest threats

---

## Troubleshooting Guide

### Cloud Armor Issues
```bash
# Check security policy status
gcloud compute security-policies describe techcorp-security-policy

# View security policy rules
gcloud compute security-policies rules list techcorp-security-policy

# Check backend service security policy association
gcloud compute backend-services describe web-backend-service --global

# Monitor blocked requests
gcloud logging read "resource.type=gce_backend_service AND jsonPayload.enforcedSecurityPolicy.name=techcorp-security-policy"
```

### Performance Impact Analysis
```bash
# Check latency impact
gcloud monitoring metrics list --filter="metric.type:loadbalancing"

# View security policy effectiveness
gcloud logging read "jsonPayload.enforcedSecurityPolicy.outcome=DENY" --limit=100

# Analyze false positives
gcloud logging read "jsonPayload.enforcedSecurityPolicy.outcome=DENY AND jsonPayload.statusDetails=403" --limit=50
```

---

## Assessment Questions

1. **How does Cloud Armor provide protection against different types of DDoS attacks?**
2. **What are the key considerations when implementing geo-blocking policies?**
3. **How do you balance security effectiveness with false positive rates?**
4. **What monitoring and alerting strategies are essential for security policies?**
5. **How does adaptive protection enhance traditional rule-based security?**

---

## Additional Resources

### Documentation
- [Cloud Armor Security Policies](https://cloud.google.com/armor/docs/security-policy-overview)
- [DDoS Protection Best Practices](https://cloud.google.com/armor/docs/ddos-protection)
- [WAF Rules and Expressions](https://cloud.google.com/armor/docs/rules-language-reference)
- [Security Monitoring](https://cloud.google.com/monitoring/support/metrics)

### Security Frameworks
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)
LAB04_CONCEPTS_END

# Lab 05 Concepts - Identity and Access Management
cat > workshop-materials/docs/guides/lab-05-concepts.md << 'LAB05_CONCEPTS_END'
# Lab 05 Concepts: Identity and Access Management

## Learning Objectives
After completing this lab, you will understand:
- IAM role design principles and custom role creation
- Service account security patterns and Workload Identity
- Conditional access policies and context-aware access controls
- Organization policies and enterprise governance
- Access management automation and audit trails

---

## Core Concepts

### 1. IAM Role Architecture and Design

#### Role Hierarchy and Inheritance
```
┌─────────────────────────────────────────────────────────────┐
│                    IAM Role Architecture                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Organization Level                                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Org Admin   │  │ Security    │  │ Billing     │     │ │
│  │ │ Super Users │  │ Admin       │  │ Admin       │     │ │
│  │ │ Full Control│  │ Sec Policies│  │ Cost Mgmt   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼ (Inheritance)                 │
│  Folder Level                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Environment │  │ Team        │  │ Compliance  │     │ │
│  │ │ Admin       │  │ Lead        │  │ Officer     │     │ │
│  │ │ Env Control │  │ Team Mgmt   │  │ Audit       │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼ (Inheritance)                 │
│  Project Level                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Project     │  │ Developer   │  │ Service     │     │ │
│  │ │ Owner       │  │ Access      │  │ Account     │     │ │
│  │ │ Full Proj   │  │ Limited     │  │ Automated   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼ (Inheritance)                 │
│  Resource Level                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Compute     │  │ Storage     │  │ Network     │     │ │
│  │ │ Admin       │  │ Admin       │  │ Admin       │     │ │
│  │ │ VM Control  │  │ Data Access │  │ Firewall    │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Custom Role Design Patterns
```hcl
# TechCorp custom roles following principle of least privilege
resource "google_project_iam_custom_role" "web_tier_operator" {
  role_id     = "webTierOperator"
  title       = "Web Tier Operator"
  description = "Minimal permissions for web tier operations"
  project     = var.project_id
  
  permissions = [
    # Compute permissions for web tier management
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.reset",
    "compute.instances.setMetadata",
    "compute.instances.setTags",
    
    # Instance group permissions
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instanceGroupManagers.update",
    
    # Health check permissions
    "compute.healthChecks.get",
    "compute.healthChecks.list",
    "compute.healthChecks.use",
    
    # Load balancer permissions (read-only)
    "compute.backendServices.get",
    "compute.backendServices.list",
    "compute.urlMaps.get",
    "compute.urlMaps.list",
    
    # Monitoring permissions
    "monitoring.metricDescriptors.get",
    "monitoring.metricDescriptors.list",
    "monitoring.timeSeries.list",
    
    # Logging permissions (read-only)
    "logging.entries.list",
    "logging.logEntries.list",
    "logging.logs.list",
  ]
}

resource "google_project_iam_custom_role" "app_tier_developer" {
  role_id     = "appTierDeveloper"
  title       = "Application Tier Developer"
  description = "Development permissions for application tier"
  project     = var.project_id
  
  permissions = [
    # Container and Kubernetes permissions
    "container.clusters.get",
    "container.clusters.list",
    "container.pods.get",
    "container.pods.list",
    "container.pods.create",
    "container.pods.update",
    "container.pods.delete",
    "container.deployments.get",
    "container.deployments.list",
    "container.deployments.create",
    "container.deployments.update",
    "container.services.get",
    "container.services.list",
    "container.services.create",
    "container.services.update",
    
    # Cloud SQL permissions (limited)
    "cloudsql.instances.get",
    "cloudsql.instances.list",
    "cloudsql.instances.connect",
    
    # Secret Manager permissions
    "secretmanager.secrets.get",
    "secretmanager.versions.access",
    
    # Storage permissions (application data)
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.update",
    
    # Pub/Sub permissions
    "pubsub.topics.get",
    "pubsub.topics.list",
    "pubsub.subscriptions.get",
    "pubsub.subscriptions.list",
    "pubsub.messages.ack",
    "pubsub.messages.consume",
    "pubsub.messages.publish",
  ]
}

resource "google_project_iam_custom_role" "data_tier_administrator" {
  role_id     = "dataTierAdministrator"
  title       = "Data Tier Administrator"
  description = "Administrative permissions for data tier resources"
  project     = var.project_id
  
  permissions = [
    # Cloud SQL administrative permissions
    "cloudsql.instances.create",
    "cloudsql.instances.delete",
    "cloudsql.instances.get",
    "cloudsql.instances.list",
    "cloudsql.instances.update",
    "cloudsql.instances.restart",
    "cloudsql.databases.create",
    "cloudsql.databases.delete",
    "cloudsql.databases.get",
    "cloudsql.databases.list",
    "cloudsql.databases.update",
    "cloudsql.users.create",
    "cloudsql.users.delete",
    "cloudsql.users.list",
    "cloudsql.users.update",
    
    # BigQuery permissions
    "bigquery.datasets.create",
    "bigquery.datasets.delete",
    "bigquery.datasets.get",
    "bigquery.datasets.update",
    "bigquery.tables.create",
    "bigquery.tables.delete",
    "bigquery.tables.get",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create",
    
    # Cloud Storage permissions
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.buckets.update",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    
    # Backup and disaster recovery
    "compute.snapshots.create",
    "compute.snapshots.delete",
    "compute.snapshots.get",
    "compute.snapshots.list",
  ]
}

resource "google_project_iam_custom_role" "security_auditor" {
  role_id     = "securityAuditor"
  title       = "Security Auditor"
  description = "Read-only access for security auditing and compliance"
  project     = var.project_id
  
  permissions = [
    # IAM permissions (read-only)
    "iam.roles.get",
    "iam.roles.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "resourcemanager.projects.getIamPolicy",
    
    # Security Center permissions
    "securitycenter.assets.get",
    "securitycenter.assets.list",
    "securitycenter.findings.get",
    "securitycenter.findings.list",
    "securitycenter.sources.get",
    "securitycenter.sources.list",
    
    # Binary Authorization permissions
    "binaryauthorization.policy.get",
    "binaryauthorization.attestors.get",
    "binaryauthorization.attestors.list",
    
    # KMS permissions (read-only)
    "cloudkms.keyRings.get",
    "cloudkms.keyRings.list",
    "cloudkms.cryptoKeys.get",
    "cloudkms.cryptoKeys.list",
    "cloudkms.cryptoKeyVersions.get",
    "cloudkms.cryptoKeyVersions.list",
    
    # Audit log permissions
    "logging.entries.list",
    "logging.logEntries.list",
    "logging.logs.list",
    "logging.sinks.get",
    "logging.sinks.list",
    
    # Organization policy permissions
    "orgpolicy.policy.get",
    "orgpolicy.constraints.list",
  ]
}
```

### 2. Service Account Security Patterns

#### Service Account Architecture
```
┌─────────────────────────────────────────────────────────────┐
│              Service Account Security Model                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User-Managed Service Accounts                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Tier-Specific Service Accounts                         │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ web-tier-sa │  │ app-tier-sa │  │data-tier-sa │ ││ │
│  │  │ │ Web Apps    │  │ API Services│  │ Databases   │ ││ │
│  │  │ │ Static Cont │  │ Microservices│ │ Data Proc   │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Function-Specific Service Accounts                     │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │monitoring-sa│  │ backup-sa   │  │cicd-sa      │ ││ │
│  │  │ │ Observability│ │ Data Backup │  │ Deployment  │ ││ │
│  │  │ │ Metrics/Logs│  │ DR Procedures│ │ Automation  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Workload Identity Integration                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Kubernetes → Google Service Account Mapping           │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ K8s Service Account → Google Service Account       ││ │
│  │  │ ┌─────────────────┐   ┌─────────────────┐          ││ │
│  │  │ │ web-app-ksa     │──→│ web-tier-sa     │          ││ │
│  │  │ │ Kubernetes NS   │   │ Google Cloud    │          ││ │
│  │  │ │ web-tier        │   │ Service Account │          ││ │
│  │  │ └─────────────────┘   └─────────────────┘          ││ │
│  │  │                                                     ││ │
│  │  │ ┌─────────────────┐   ┌─────────────────┐          ││ │
│  │  │ │ api-app-ksa     │──→│ app-tier-sa     │          ││ │
│  │  │ │ Kubernetes NS   │   │ Google Cloud    │          ││ │
│  │  │ │ api-tier        │   │ Service Account │          ││ │
│  │  │ └─────────────────┘   └─────────────────┘          ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Security Benefits                                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • No Service Account Keys                           ││ │
│  │  │ • Automatic Token Rotation                          ││ │
│  │  │ • Fine-grained Permission Control                   ││ │
│  │  │ • Audit Trail Integration                           ││ │
│  │  │ • Namespace-based Isolation                         ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Service Account Implementation
```hcl
# Service account definitions with security best practices
locals {
  service_accounts = {
    "web-tier-sa" = {
      display_name = "Web Tier Service Account"
      description  = "Service account for web tier applications and load balancers"
      roles = [
        "roles/compute.instanceAdmin.v1",
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
        "roles/storage.objectViewer",
      ]
      custom_roles = [
        google_project_iam_custom_role.web_tier_operator.id
      ]
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[web-tier/web-app-ksa]"
      ]
    }
    
    "app-tier-sa" = {
      display_name = "Application Tier Service Account"
      description  = "Service account for application services and APIs"
      roles = [
        "roles/cloudsql.client",
        "roles/secretmanager.secretAccessor",
        "roles/pubsub.publisher",
        "roles/pubsub.subscriber",
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
      ]
      custom_roles = [
        google_project_iam_custom_role.app_tier_developer.id
      ]
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[app-tier/api-app-ksa]",
        "serviceAccount:${var.project_id}.svc.id.goog[app-tier/worker-app-ksa]"
      ]
    }
    
    "data-tier-sa" = {
      display_name = "Data Tier Service Account"
      description  = "Service account for data processing and database management"
      roles = [
        "roles/cloudsql.admin",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/storage.admin",
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
      ]
      custom_roles = [
        google_project_iam_custom_role.data_tier_administrator.id
      ]
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[data-tier/database-admin-ksa]"
      ]
    }
    
    "monitoring-sa" = {
      display_name = "Monitoring Service Account"
      description  = "Service account for monitoring and observability systems"
      roles = [
        "roles/monitoring.admin",
        "roles/logging.admin",
        "roles/errorreporting.admin",
        "roles/clouddebugger.agent",
        "roles/cloudprofiler.agent",
      ]
      custom_roles = []
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[monitoring/monitoring-ksa]"
      ]
    }
    
    "backup-sa" = {
      display_name = "Backup Service Account"
      description  = "Service account for backup and disaster recovery operations"
      roles = [
        "roles/compute.storageAdmin",
        "roles/storage.admin",
        "roles/cloudsql.admin",
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
      ]
      custom_roles = []
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[backup/backup-ksa]"
      ]
    }
    
    "cicd-sa" = {
      display_name = "CI/CD Service Account"
      description  = "Service account for CI/CD pipeline automation"
      roles = [
        "roles/container.developer",
        "roles/cloudbuild.builds.builder",
        "roles/storage.admin",
        "roles/iam.serviceAccountUser",
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter",
      ]
      custom_roles = []
      workload_identity_users = [
        "serviceAccount:${var.project_id}.svc.id.goog[cicd/build-ksa]"
      ]
    }
  }
}

# Create service accounts
resource "google_service_account" "service_accounts" {
  for_each = local.service_accounts
  
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# Apply IAM role bindings
resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in local.service_accounts : [
        for role in sa_config.roles : {
          key             = "${sa_key}-${role}"
          service_account = sa_key
          role           = role
        }
      ]
    ]) : binding.key => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account].email}"
}

# Apply custom role bindings
resource "google_project_iam_member" "service_account_custom_roles" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in local.service_accounts : [
        for role in sa_config.custom_roles : {
          key             = "${sa_key}-${role}"
          service_account = sa_key
          role           = role
        }
      ]
    ]) : binding.key => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account].email}"
}

# Configure Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in local.service_accounts : [
        for user in sa_config.workload_identity_users : {
          key             = "${sa_key}-${user}"
          service_account = sa_key
          user           = user
        }
      ]
    ]) : binding.key => binding
  }
  
  service_account_id = google_service_account.service_accounts[each.value.service_account].name
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.user
}
```

### 3. Conditional Access Policies

#### Context-Aware Access Controls
```hcl
# Conditional IAM policies based on context
resource "google_iap_client" "techcorp_iap_client" {
  display_name = "TechCorp IAP Client"
  brand        = google_iap_brand.techcorp_brand.name
}

resource "google_iap_brand" "techcorp_brand" {
  support_email     = "support@techcorp.com"
  application_title = "TechCorp Internal Applications"
  project           = var.project_id
}

# Conditional access policy for administrative functions
resource "google_project_iam_binding" "conditional_admin_access" {
  project = var.project_id
  role    = "roles/compute.admin"
  
  members = [
    "group:platform-admins@techcorp.com",
    "group:senior-engineers@techcorp.com"
  ]
  
  condition {
    title       = "Admin access during business hours from corporate network"
    description = "Allow admin access only during business hours and from corporate IP ranges"
    expression  = <<-EOT
      request.ip in [
        "203.0.113.0/24",    # Corporate office
        "198.51.100.0/24",   # VPN range
        "192.0.2.0/24"       # Backup office
      ] &&
      request.time.getHours() >= 8 &&
      request.time.getHours() <= 18 &&
      request.time.getDayOfWeek() >= 2 && 
      request.time.getDayOfWeek() <= 6
    EOT
  }
}

# Conditional access for sensitive data operations
resource "google_project_iam_binding" "conditional_data_access" {
  project = var.project_id
  role    = google_project_iam_custom_role.data_tier_administrator.id
  
  members = [
    "group:data-engineers@techcorp.com",
    "serviceAccount:${google_service_account.service_accounts["data-tier-sa"].email}"
  ]
  
  condition {
    title       = "Data access with MFA and device compliance"
    description = "Require MFA and compliant device for data operations"
    expression  = <<-EOT
      has(request.auth.access_levels) &&
      request.auth.access_levels.exists(level, level in [
        "accessPolicies/${var.access_policy_id}/accessLevels/mfa_required",
        "accessPolicies/${var.access_policy_id}/accessLevels/corporate_device"
      ])
    EOT
  }
}

# Break-glass access for emergencies
resource "google_project_iam_binding" "emergency_access" {
  project = var.project_id
  role    = "roles/owner"
  
  members = [
    "group:emergency-responders@techcorp.com"
  ]
  
  condition {
    title       = "Emergency break-glass access"
    description = "Emergency access with extended logging and notification"
    expression  = <<-EOT
      has(request.auth.claims) &&
      request.auth.claims.emergency_access == true
    EOT
  }
}
```

#### Access Context Manager Integration
```hcl
# Access Context Manager policy for advanced security
resource "google_access_context_manager_access_policy" "techcorp_policy" {
  parent = "organizations/${var.organization_id}"
  title  = "TechCorp Access Policy"
}

# Access level for MFA requirement
resource "google_access_context_manager_access_level" "mfa_required" {
  parent = google_access_context_manager_access_policy.techcorp_policy.name
  name   = "mfa_required"
  title  = "MFA Required"
  
  basic {
    conditions {
      required_access_levels = []
      ip_subnetworks         = []
      device_policy {
        require_screen_lock = true
        require_admin_approval = false
        require_corp_owned     = false
      }
      required_access_levels = []
    }
    
    combining_function = "AND"
  }
}

# Access level for corporate devices
resource "google_access_context_manager_access_level" "corporate_device" {
  parent = google_access_context_manager_access_policy.techcorp_policy.name
  name   = "corporate_device"
  title  = "Corporate Device"
  
  basic {
    conditions {
      device_policy {
        require_screen_lock    = true
        require_admin_approval = true
        require_corp_owned     = true
        
        os_constraints {
          os_type          = "DESKTOP_WINDOWS"
          minimum_version  = "10.0.0"
        }
        
        os_constraints {
          os_type          = "DESKTOP_MAC"
          minimum_version  = "10.15"
        }
      }
    }
    
    combining_function = "AND"
  }
}

# Access level for corporate network
resource "google_access_context_manager_access_level" "corporate_network" {
  parent = google_access_context_manager_access_policy.techcorp_policy.name
  name   = "corporate_network"
  title  = "Corporate Network"
  
  basic {
    conditions {
      ip_subnetworks = [
        "203.0.113.0/24",
        "198.51.100.0/24",
        "192.0.2.0/24"
      ]
    }
    
    combining_function = "AND"
  }
}

# Service perimeter for sensitive resources
resource "google_access_context_manager_service_perimeter" "techcorp_perimeter" {
  parent = google_access_context_manager_access_policy.techcorp_policy.name
  name   = "techcorp_production_perimeter"
  title  = "TechCorp Production Perimeter"
  
  status {
    resources = [
      "projects/${var.project_id}"
    ]
    
    access_levels = [
      google_access_context_manager_access_level.mfa_required.name,
      google_access_context_manager_access_level.corporate_device.name,
    ]
    
    restricted_services = [
      "bigquery.googleapis.com",
      "storage.googleapis.com",
      "cloudsql.googleapis.com",
      "secretmanager.googleapis.com",
    ]
    
    vpc_accessible_services {
      enable_restriction = true
      allowed_services = [
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "cloudsql.googleapis.com",
        "monitoring.googleapis.com",
        "logging.googleapis.com",
      ]
    }
  }
}
```

### 4. Organization Policies and Governance

#### Enterprise Governance Framework
```hcl
# Organization policies for enterprise governance
resource "google_organization_policy" "disable_service_account_key_creation" {
  org_id     = var.organization_id
  constraint = "iam.disableServiceAccountKeyCreation"
  
  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "disable_service_account_key_upload" {
  org_id     = var.organization_id
  constraint = "iam.disableServiceAccountKeyUpload"
  
  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "require_os_login" {
  org_id     = var.organization_id
  constraint = "compute.requireOsLogin"
  
  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "restrict_vm_external_ips" {
  org_id     = var.organization_id
  constraint = "compute.vmExternalIpAccess"
  
  list_policy {
    deny {
      all = true
    }
    
    allow {
      values = [
        "projects/${var.project_id}/zones/us-central1-a/instances/bastion-host",
        "projects/${var.project_id}/zones/us-central1-a/instances/nat-gateway"
      ]
    }
  }
}

resource "google_organization_policy" "allowed_policy_member_domains" {
  org_id     = var.organization_id
  constraint = "iam.allowedPolicyMemberDomains"
  
  list_policy {
    allow {
      values = [
        "techcorp.com",
        "C01234567"  # Google Workspace Customer ID
      ]
    }
  }
}

resource "google_organization_policy" "uniform_bucket_level_access" {
  org_id     = var.organization_id
  constraint = "storage.uniformBucketLevelAccess"
  
  boolean_policy {
    enforced = true
  }
}

# Project-level policies
resource "google_project_organization_policy" "restrict_shared_vpc_subnetworks" {
  project    = var.project_id
  constraint = "compute.restrictSharedVpcSubnetworks"
  
  list_policy {
    allow {
      values = [
        "projects/${var.shared_vpc_project}/regions/us-central1/subnetworks/web-tier-subnet",
        "projects/${var.shared_vpc_project}/regions/us-central1/subnetworks/app-tier-subnet",
        "projects/${var.shared_vpc_project}/regions/us-central1/subnetworks/data-tier-subnet"
      ]
    }
  }
}

resource "google_project_organization_policy" "allowed_ingress_settings" {
  project    = var.project_id
  constraint = "cloudfunctions.allowedIngressSettings"
  
  list_policy {
    allow {
      values = [
        "ALLOW_INTERNAL_ONLY",
        "ALLOW_INTERNAL_AND_GCLB"
      ]
    }
  }
}
```

### 5. Access Management Automation

#### Automated Access Reviews
```hcl
# Cloud Scheduler job for periodic access reviews
resource "google_cloud_scheduler_job" "access_review_job" {
  name             = "access-review-automation"
  description      = "Automated access review and audit"
  schedule         = "0 9 1 * *"  # First day of each month at 9 AM
  time_zone        = "America/New_York"
  attempt_deadline = "180s"
  
  pubsub_target {
    topic_name = google_pubsub_topic.access_review_topic.id
    data       = base64encode(jsonencode({
      project_id = var.project_id
      review_type = "monthly"
      notify_managers = true
    }))
  }
}

resource "google_pubsub_topic" "access_review_topic" {
  name = "access-review-requests"
}

resource "google_cloudfunctions_function" "access_review_function" {
  name        = "access-review-automation"
  description = "Automated access review and reporting"
  runtime     = "python39"
  
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.access_review_function.name
  
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.access_review_topic.name
  }
  
  entry_point = "access_review_handler"
  
  environment_variables = {
    PROJECT_ID = var.project_id
    ORGANIZATION_ID = var.organization_id
    SLACK_WEBHOOK = var.slack_webhook_url
    REVIEW_SPREADSHEET_ID = var.review_spreadsheet_id
  }
}

# IAM analyzer for access review
resource "google_cloud_asset_project_feed" "iam_policy_feed" {
  project      = var.project_id
  feed_id      = "iam-policy-changes"
  content_type = "IAM_POLICY"
  
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project",
    "compute.googleapis.com/Instance",
    "storage.googleapis.com/Bucket",
    "bigquery.googleapis.com/Dataset"
  ]
  
  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.iam_changes_topic.id
    }
  }
}

resource "google_pubsub_topic" "iam_changes_topic" {
  name = "iam-policy-changes"
}
```

#### Just-In-Time Access Implementation
```hcl
# JIT access management system
resource "google_cloudfunctions_function" "jit_access_manager" {
  name        = "jit-access-manager"
  description = "Just-in-time access management and approval"
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.jit_function.name
  
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.jit_requests_topic.name
  }
  
  entry_point = "jit_access_handler"
  
  environment_variables = {
    PROJECT_ID = var.project_id
    APPROVAL_SPREADSHEET_ID = var.approval_spreadsheet_id
    SECURITY_TEAM_EMAIL = var.security_team_email
    MAX_ACCESS_DURATION = "4h"
  }
}

resource "google_pubsub_topic" "jit_requests_topic" {
  name = "jit-access-requests"
}

# JIT access request form trigger
resource "google_cloudfunctions_function" "jit_request_form" {
  name        = "jit-request-form"
  description = "JIT access request form handler"
  runtime     = "python39"
  
  available_memory_mb = 256
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.jit_form_function.name
  
  trigger {
    event_type = "providers/cloud.firestore/eventTypes/document.write"
    resource   = "projects/${var.project_id}/databases/(default)/documents/jit_requests/{document}"
  }
  
  entry_point = "process_jit_request"
}

# Firestore for JIT access tracking
resource "google_firestore_database" "jit_database" {
  project     = var.project_id
  name        = "(default)"
  location_id = "us-central1"
  type        = "FIRESTORE_NATIVE"
}
```

---

## Integration Patterns

### 1. Lab Dependencies and Outputs
```hcl
# Outputs for integration with subsequent labs
output "custom_roles" {
  description = "Custom IAM roles created for TechCorp"
  value = {
    web_tier_operator     = google_project_iam_custom_role.web_tier_operator.id
    app_tier_developer    = google_project_iam_custom_role.app_tier_developer.id
    data_tier_admin       = google_project_iam_custom_role.data_tier_administrator.id
    security_auditor      = google_project_iam_custom_role.security_auditor.id
  }
}

output "service_accounts" {
  description = "Service accounts with their email addresses and roles"
  value = {
    for sa_key, sa in google_service_account.service_accounts : sa_key => {
      email        = sa.email
      unique_id    = sa.unique_id
      display_name = sa.display_name
      roles        = local.service_accounts[sa_key].roles
      custom_roles = local.service_accounts[sa_key].custom_roles
    }
  }
}

output "workload_identity_config" {
  description = "Workload Identity configuration for Kubernetes integration"
  value = {
    for sa_key, sa_config in local.service_accounts : sa_key => {
      service_account_email = google_service_account.service_accounts[sa_key].email
      workload_identity_users = sa_config.workload_identity_users
    }
  }
}

output "organization_policies" {
  description = "Organization policies applied for governance"
  value = {
    disable_sa_key_creation = google_organization_policy.disable_service_account_key_creation.constraint
    require_os_login       = google_organization_policy.require_os_login.constraint
    restrict_vm_external_ips = google_organization_policy.restrict_vm_external_ips.constraint
  }
}

output "access_context_manager" {
  description = "Access Context Manager configuration"
  value = {
    policy_id = google_access_context_manager_access_policy.techcorp_policy.name
    access_levels = {
      mfa_required      = google_access_context_manager_access_level.mfa_required.name
      corporate_device  = google_access_context_manager_access_level.corporate_device.name
      corporate_network = google_access_context_manager_access_level.corporate_network.name
    }
    service_perimeter = google_access_context_manager_service_perimeter.techcorp_perimeter.name
  }
}
```

### 2. Integration with Monitoring (Lab 06)
```hcl
# IAM monitoring integration
resource "google_monitoring_alert_policy" "iam_policy_violations" {
  display_name = "IAM Policy Violations"
  combiner     = "OR"
  
  conditions {
    display_name = "Service account key creation detected"
    
    condition_threshold {
      filter = "resource.type=\"service_account\" AND protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\""
      duration = "60s"
      comparison = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.security_team.id
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "privileged_access_usage" {
  display_name = "Privileged Access Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "Owner role usage detected"
    
    condition_threshold {
      filter = "protoPayload.authenticationInfo.principalEmail!=\"\" AND protoPayload.authorizationInfo.granted=true AND protoPayload.authorizationInfo.permission~\".*owner.*\""
      duration = "60s"
      comparison = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.security_team.id
  ]
}
```

### 3. Integration with Security Controls (Lab 10)
```hcl
# Data for security controls integration
data "google_iam_policy" "security_binding" {
  binding {
    role = "roles/securitycenter.admin"
    members = [
      "serviceAccount:${google_service_account.service_accounts["monitoring-sa"].email}"
    ]
  }
  
  binding {
    role = google_project_iam_custom_role.security_auditor.id
    members = [
      "group:security-team@techcorp.com",
      "serviceAccount:${google_service_account.service_accounts["monitoring-sa"].email}"
    ]
  }
}

# Binary Authorization integration
resource "google_project_iam_member" "binary_auth_attestor" {
  project = var.project_id
  role    = "roles/binaryauthorization.attestorsEditor"
  member  = "serviceAccount:${google_service_account.service_accounts["cicd-sa"].email}"
}

# KMS integration for security controls
resource "google_project_iam_member" "kms_crypto_key_user" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_service_account.service_accounts["data-tier-sa"].email}"
}
```

---

## Best Practices and Security Considerations

### 1. IAM Security Best Practices
- **Principle of Least Privilege**: Grant minimal required permissions
- **Regular Access Reviews**: Conduct periodic permission audits
- **Conditional Access**: Use context-aware access controls
- **Workload Identity**: Avoid service account keys when possible
- **Monitoring and Alerting**: Track privileged access usage

### 2. Service Account Management
- **Unique Purpose**: One service account per distinct function
- **Short-lived Tokens**: Use automatic token rotation
- **Cross-Project Access**: Minimize cross-project service account usage
- **Key Rotation**: Regular rotation of any required keys
- **Audit Trails**: Comprehensive logging of service account activities

### 3. Organization Policy Governance
- **Preventive Controls**: Use organization policies to prevent misconfigurations
- **Inheritance**: Leverage policy inheritance for consistent enforcement
- **Exception Management**: Carefully manage policy exceptions
- **Regular Reviews**: Periodic review and updates of policies
- **Testing**: Validate policies in non-production environments

---

## Troubleshooting Guide

### IAM Permission Issues
```bash
# Check effective IAM policies
gcloud projects get-iam-policy PROJECT_ID

# Test service account permissions
gcloud auth activate-service-account --key-file=SERVICE_ACCOUNT_KEY.json
gcloud projects get-iam-policy PROJECT_ID --impersonate-service-account=SERVICE_ACCOUNT_EMAIL

# Troubleshoot policy troubleshooter
gcloud policy-troubleshoot iam PROJECT_ID \
  --principal-email=PRINCIPAL_EMAIL \
  --resource-name=RESOURCE_NAME \
  --permission=PERMISSION
```

### Workload Identity Issues
```bash
# Check Workload Identity configuration
kubectl describe serviceaccount KSA_NAME -n NAMESPACE

# Verify Workload Identity binding
gcloud iam service-accounts get-iam-policy GSA_EMAIL

# Test Workload Identity from pod
kubectl run -it --rm debug --image=google/cloud-sdk:slim --restart=Never -- /bin/bash
gcloud auth list
gcloud projects get-iam-policy PROJECT_ID
```

### Organization Policy Conflicts
```bash
# Check organization policies
gcloud resource-manager org-policies list --organization=ORG_ID

# Describe specific policy
gcloud resource-manager org-policies describe CONSTRAINT_NAME --organization=ORG_ID

# Test policy constraints
gcloud policy-troubleshoot iam PROJECT_ID \
  --principal-email=PRINCIPAL_EMAIL \
  --resource-name=projects/PROJECT_ID \
  --permission=PERMISSION
```

---

## Assessment Questions

1. **How do custom IAM roles improve security compared to predefined roles?**
2. **What are the benefits of Workload Identity over service account keys?**
3. **How do conditional access policies enhance security controls?**
4. **What role do organization policies play in enterprise governance?**
5. **How can access management automation improve security and compliance?**

---

## Additional Resources

### Documentation
- [IAM Best Practices](https://cloud.google.com/iam/docs/using-iam-securely)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Organization Policies](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [Access Context Manager](https://cloud.google.com/access-context-manager/docs)

### Security Frameworks
- [CIS Google Cloud Foundations](https://www.cisecurity.org/benchmark/google_cloud_platform)
- [NIST Identity and Access Management](https://csrc.nist.gov/projects/identity-and-access-management)
- [Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)
LAB05_CONCEPTS_END

# Lab 06 Concepts - Cloud Monitoring Foundation
cat > workshop-materials/docs/guides/lab-06-concepts.md << 'LAB06_CONCEPTS_END'
# Lab 06 Concepts: Cloud Monitoring Foundation

## Learning Objectives
After completing this lab, you will understand:
- Cloud Monitoring architecture and metric collection strategies
- Custom dashboard design and visualization best practices
- Alert policy configuration and notification management
- SLI/SLO implementation for reliability engineering
- Monitoring automation and infrastructure observability

---

## Core Concepts

### 1. Cloud Monitoring Architecture

#### Monitoring Stack Overview
```
┌─────────────────────────────────────────────────────────────┐
│              Cloud Monitoring Architecture                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Data Collection Layer                                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Infrastructure Metrics                                 │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Compute     │  │ Networking  │  │ Storage     │ ││ │
│  │  │ │ CPU, Memory │  │ Bandwidth   │  │ IOPS, Space │ ││ │
│  │  │ │ Disk I/O    │  │ Latency     │  │ Throughput  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Application Metrics                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Request     │  │ Response    │  │ Error       │ ││ │
│  │  │ │ Rate        │  │ Time        │  │ Rate        │ ││ │
│  │  │ │ Throughput  │  │ Latency     │  │ Exceptions  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Custom Metrics                                         │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Business    │  │ Security    │  │ Performance │ ││ │
│  │  │ │ KPIs        │  │ Events      │  │ Metrics     │ ││ │
│  │  │ │ SLIs        │  │ Threats     │  │ Benchmarks  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Processing and Storage Layer                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Time Series │  │ Metric      │  │ Aggregation │     │ │
│  │ │ Database    │  │ Ingestion   │  │ Engine      │     │ │
│  │ │ Storage     │  │ Pipeline    │  │ Processing  │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Visualization and Alerting Layer                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Dashboards  │  │ Alert       │  │ Notification│     │ │
│  │ │ Custom      │  │ Policies    │  │ Channels    │     │ │
│  │ │ Widgets     │  │ Conditions  │  │ Integration │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Monitoring Workspace Configuration
```hcl
# Cloud Monitoring workspace setup
resource "google_monitoring_workspace" "techcorp_workspace" {
  project = var.project_id
  
  lifecycle {
    prevent_destroy = true
  }
}

# Notification channels for different alert types
resource "google_monitoring_notification_channel" "email_critical" {
  display_name = "Critical Alerts - Email"
  type         = "email"
  
  labels = {
    email_address = var.critical_alerts_email
  }
  
  user_labels = {
    environment = var.environment
    team        = "platform"
    priority    = "critical"
  }
}

resource "google_monitoring_notification_channel" "slack_general" {
  display_name = "General Alerts - Slack"
  type         = "slack"
  
  labels = {
    channel_name = var.slack_channel
    url          = var.slack_webhook_url
  }
  
  user_labels = {
    environment = var.environment
    team        = "platform"
    priority    = "general"
  }
}

resource "google_monitoring_notification_channel" "pagerduty_incidents" {
  display_name = "Incidents - PagerDuty"
  type         = "pagerduty"
  
  labels = {
    service_key = var.pagerduty_service_key
  }
  
  user_labels = {
    environment = var.environment
    team        = "sre"
    priority    = "incident"
  }
}

resource "google_monitoring_notification_channel" "sms_critical" {
  display_name = "Critical Alerts - SMS"
  type         = "sms"
  
  labels = {
    number = var.critical_alerts_phone
  }
  
  user_labels = {
    environment = var.environment
    team        = "platform"
    priority    = "critical"
  }
}
```

### 2. Custom Dashboard Design

#### Dashboard Architecture Pattern
```
┌─────────────────────────────────────────────────────────────┐
│                   Dashboard Architecture                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Executive Dashboard (High-Level Overview)                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Service     │  │ Cost        │  │ Security    │     │ │
│  │ │ Health      │  │ Overview    │  │ Posture     │     │ │
│  │ │ 99.9% SLA   │  │ $X,XXX/mo   │  │ 0 Critical  │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Business Metrics Timeline                           │ │ │
│  │ │ • Request Volume                                    │ │ │
│  │ │ • Revenue Impact                                    │ │ │
│  │ │ • User Experience Score                             │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Operational Dashboard (Team Overview)                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Golden      │  │ Resource    │  │ Error       │     │ │
│  │ │ Signals     │  │ Utilization │  │ Budget      │     │ │
│  │ │ RED/USE     │  │ CPU/Memory  │  │ Incidents   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Service Map and Dependencies                        │ │ │
│  │ │ • Load Balancer → Web Tier → App Tier → Data       │ │ │
│  │ │ • Health status per component                       │ │ │
│  │ │ • Request flow and latency                          │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Technical Dashboard (Deep Dive)                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Detailed    │  │ Performance │  │ Capacity    │     │ │
│  │ │ Metrics     │  │ Analysis    │  │ Planning    │     │ │
│  │ │ Per Service │  │ Bottlenecks │  │ Forecasting │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Troubleshooting Views                               │ │ │
│  │ │ • Log correlation                                   │ │ │
│  │ │ • Trace analysis                                    │ │ │
│  │ │ • Resource debugging                                │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Dashboard Implementation
```hcl
# Executive dashboard for high-level overview
resource "google_monitoring_dashboard" "executive_overview" {
  dashboard_json = jsonencode({
    displayName = "TechCorp Executive Overview"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Service Health Overview"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/up\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                    groupByFields = ["resource.project_id"]
                  }
                }
              }
              gaugeView = {
                lowerBound = 0.0
                upperBound = 1.0
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Request Volume (QPS)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Requests per second"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width = 12
          height = 4
          widget = {
            title = "Error Rate by Service"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.backend_service_name", "metric.response_code_class"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
              yAxis = {
                label = "Error rate"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

# Operational dashboard for platform team
resource "google_monitoring_dashboard" "operational_overview" {
  dashboard_json = jsonencode({
    displayName = "TechCorp Operational Dashboard"
    mosaicLayout = {
      tiles = [
        # Golden Signals - Request Rate
        {
          width = 6
          height = 4
          widget = {
            title = "Request Rate (RED)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.backend_service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # Golden Signals - Error Rate
        {
          width = 6
          height = 4
          widget = {
            title = "Error Rate (RED)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND metric.response_code_class=\"4xx\" OR metric.response_code_class=\"5xx\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # Golden Signals - Duration
        {
          width = 12
          height = 4
          widget = {
            title = "Response Duration (RED)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/total_latencies\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      groupByFields = ["resource.backend_service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # Resource Utilization - CPU
        {
          width = 6
          height = 4
          widget = {
            title = "CPU Utilization (USE)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.instance_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # Resource Utilization - Memory
        {
          width = 6
          height = 4
          widget = {
            title = "Memory Utilization (USE)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"agent.googleapis.com/memory/percent_used\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.instance_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })
}

# Technical deep-dive dashboard
resource "google_monitoring_dashboard" "technical_deep_dive" {
  dashboard_json = jsonencode({
    displayName = "TechCorp Technical Deep Dive"
    mosaicLayout = {
      tiles = [
        # Database Performance
        {
          width = 8
          height = 4
          widget = {
            title = "Database Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        # Network Performance
        {
          width = 4
          height = 4
          widget = {
            title = "Network Throughput"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_RATE"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
            }
          }
        },
        # Storage Performance
        {
          width = 12
          height = 4
          widget = {
            title = "Disk I/O Operations"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/disk/read_ops_count\""
                      aggregation = {
                        alignmentPeriod = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/disk/write_ops_count\""
                      aggregation = {
                        alignmentPeriod = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        }
      ]
    }
  })
}
```

### 3. Alert Policy Configuration

#### Alert Strategy Framework
```
┌─────────────────────────────────────────────────────────────┐
│                  Alert Policy Framework                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Critical Alerts (P0 - Immediate Response)                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Service     │  │ Security    │  │ Data Loss   │     │ │
│  │ │ Outage      │  │ Breach      │  │ Risk        │     │ │
│  │ │ SLA Breach  │  │ Unauthorized│  │ Backup Fail │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ Notification: PagerDuty + SMS + Email                  │ │
│  │ Response Time: < 5 minutes                             │ │
│  │ Escalation: Automatic after 15 minutes                │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Warning Alerts (P1 - Urgent Response)                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Performance │  │ Resource    │  │ Capacity    │     │ │
│  │ │ Degradation │  │ Saturation  │  │ Threshold   │     │ │
│  │ │ High Latency│  │ CPU/Memory  │  │ Disk Space  │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ Notification: Slack + Email                            │ │
│  │ Response Time: < 30 minutes                            │ │
│  │ Escalation: Manual review required                     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Informational Alerts (P2 - Monitoring)                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Trend       │  │ Maintenance │  │ Business    │     │ │
│  │ │ Analysis    │  │ Windows     │  │ Metrics     │     │ │
│  │ │ Anomalies   │  │ Schedules   │  │ Thresholds  │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ Notification: Email                                     │ │
│  │ Response Time: During business hours                   │ │
│  │ Escalation: Weekly review                              │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Alert Policy Implementation
```hcl
# Critical alert policies
resource "google_monitoring_alert_policy" "service_down" {
  display_name = "Service Down - Critical"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Load balancer backend unavailable"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.backend_service_name"]
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  conditions {
    display_name = "Instance group unhealthy"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance_group\" AND metric.type=\"compute.googleapis.com/instance_group/healthy_instances\""
      duration        = "180s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MIN"
        group_by_fields      = ["resource.instance_group_name"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.pagerduty_incidents.id,
    google_monitoring_notification_channel.sms_critical.id,
    google_monitoring_notification_channel.email_critical.id
  ]
  
  alert_strategy {
    auto_close = "1800s"
    
    notification_rate_limit {
      period = "300s"
    }
  }
  
  documentation {
    content = "Service outage detected. Immediate response required."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate - Critical"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Error rate > 5%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND (metric.response_code_class=\"4xx\" OR metric.response_code_class=\"5xx\")"
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.05
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.pagerduty_incidents.id,
    google_monitoring_notification_channel.slack_general.id
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = <<-EOF
    High error rate detected. 
    
    ## Immediate Actions
    1. Check service status
    2. Review recent deployments
    3. Examine error logs
    4. Verify database connectivity
    
    ## Escalation
    - Escalate to on-call engineer if not resolved in 15 minutes
    - Page senior engineer if customer impact confirmed
    EOF
    mime_type = "text/markdown"
  }
}

# Warning alert policies
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "High Latency - Warning"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "95th percentile latency > 2 seconds"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/total_latencies\""
      duration        = "600s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 2000
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.backend_service_name"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.slack_general.id
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
}

resource "google_monitoring_alert_policy" "high_cpu_usage" {
  display_name = "High CPU Usage - Warning"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "CPU usage > 80%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "900s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.instance_name"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.slack_general.id
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Informational alert policies
resource "google_monitoring_alert_policy" "unusual_traffic_pattern" {
  display_name = "Unusual Traffic Pattern - Info"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Traffic 50% above baseline"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
      duration        = "1800s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1.5
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_critical.id
  ]
  
  alert_strategy {
    auto_close = "7200s"
  }
}
```

### 4. SLI/SLO Implementation

#### SLI/SLO Framework
```
┌─────────────────────────────────────────────────────────────┐
│                     SLI/SLO Framework                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Service Level Indicators (SLIs)                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Availability SLI                                       │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Successful Requests / Total Requests                ││ │
│  │  │ • HTTP 200-299 responses                            ││ │
│  │  │ • Exclude planned maintenance                       ││ │
│  │  │ • Time window: 30-day rolling                       ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Latency SLI                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Fast Requests / Total Requests                      ││ │
│  │  │ • < 500ms response time                             ││ │
│  │  │ • 95th percentile measurement                       ││ │
│  │  │ • Time window: 7-day rolling                        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Throughput SLI                                         │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Requests Processed / Requests Attempted             ││ │
│  │  │ • Queue processing efficiency                       ││ │
│  │  │ • Batch job completion rate                         ││ │
│  │  │ • Time window: 24-hour rolling                      ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Service Level Objectives (SLOs)                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Availability SLO: 99.9% (30-day)                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Error Budget: 43.2 minutes/month                  ││ │
│  │  │ • Alert Threshold: 99.5% (early warning)           ││ │
│  │  │ • Business Impact: Revenue loss, reputation        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Latency SLO: 95% < 500ms (7-day)                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Error Budget: 5% slow requests                    ││ │
│  │  │ • Alert Threshold: 90% (performance degradation)   ││ │
│  │  │ • Business Impact: User experience, conversion     ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Throughput SLO: 99.5% (24-hour)                       │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Error Budget: 0.5% failed processing             ││ │
│  │  │ • Alert Threshold: 99.0% (capacity issue)          ││ │
│  │  │ • Business Impact: Data processing delays          ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Error Budget Policy                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Error Budget Consumption Rates                         │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ Fast Burn (2% budget in 1 hour)                    ││ │
│  │  │ • Page immediately                                  ││ │
│  │  │ • Halt deployments                                  ││ │
│  │  │ • Incident response                                 ││ │
│  │  │                                                     ││ │
│  │  │ Slow Burn (10% budget in 6 hours)                  ││ │
│  │  │ • Alert operations team                             ││ │
│  │  │ • Review deployment cadence                         ││ │
│  │  │ • Investigate root cause                            ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### SLO Implementation
```hcl
# SLO monitoring for availability
resource "google_monitoring_slo" "availability_slo" {
  service = google_monitoring_service.techcorp_service.service_id
  
  display_name = "Availability SLO - 99.9%"
  goal         = 0.999
  
  rolling_period_days = 30
  
  request_based_sli {
    good_total_ratio {
      good_service_filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND (metric.response_code_class=\"2xx\" OR metric.response_code_class=\"3xx\")"
      total_service_filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
    }
  }
}

# SLO monitoring for latency
resource "google_monitoring_slo" "latency_slo" {
  service = google_monitoring_service.techcorp_service.service_id
  
  display_name = "Latency SLO - 95% < 500ms"
  goal         = 0.95
  
  rolling_period_days = 7
  
  request_based_sli {
    distribution_cut {
      distribution_filter = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/total_latencies\""
      range {
        min = 0
        max = 500
      }
    }
  }
}

# Service definition for SLO tracking
resource "google_monitoring_service" "techcorp_service" {
  service_id   = "techcorp-web-service"
  display_name = "TechCorp Web Service"
  
  basic_service {
    service_type = "CLOUD_LOAD_BALANCER"
    service_labels = {
      load_balancer_name = "techcorp-web-lb"
    }
  }
}

# Error budget alert policies
resource "google_monitoring_alert_policy" "error_budget_fast_burn" {
  display_name = "Error Budget Fast Burn - SLO"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Availability SLO fast burn"
    
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability_slo.name}\", \"3600s\")"
      duration        = "120s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 14.4  # 2% budget in 1 hour
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.pagerduty_incidents.id,
    google_monitoring_notification_channel.sms_critical.id
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = <<-EOF
    Error budget is burning too fast. Service reliability at risk.
    
    ## Actions Required
    1. Stop all deployments immediately
    2. Investigate root cause of errors
    3. Implement immediate fixes
    4. Consider rollback if recent deployment
    
    ## Error Budget Status
    - Current burn rate: Too fast
    - Time to exhaust: < 1 hour at current rate
    - SLO at risk: Availability 99.9%
    EOF
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "error_budget_slow_burn" {
  display_name = "Error Budget Slow Burn - SLO"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Availability SLO slow burn"
    
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability_slo.name}\", \"21600s\")"
      duration        = "900s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 6.0  # 10% budget in 6 hours
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.slack_general.id
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
  
  documentation {
    content = <<-EOF
    Error budget is burning faster than expected. 
    
    ## Actions Required
    1. Review recent changes and deployments
    2. Analyze error patterns and trends
    3. Consider reducing deployment frequency
    4. Implement preventive measures
    
    ## Error Budget Status
    - Current burn rate: Above normal
    - Time to exhaust: ~6 hours at current rate
    - SLO at risk: Availability 99.9%
    EOF
    mime_type = "text/markdown"
  }
}
```

---

## Integration with Lab Dependencies

### 1. Using Previous Lab Outputs
```hcl
# Reference infrastructure from previous labs
data "terraform_remote_state" "lab01" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-01/terraform/state"
  }
}

data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

data "terraform_remote_state" "lab03" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-03/terraform/state"
  }
}

data "terraform_remote_state" "lab05" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-05/terraform/state"
  }
}

# Use service account for monitoring
locals {
  monitoring_sa = data.terraform_remote_state.lab05.outputs.service_accounts["monitoring-sa"]
  backend_services = data.terraform_remote_state.lab03.outputs.backend_services
  instance_groups = data.terraform_remote_state.lab03.outputs.instance_groups
}
```

### 2. Custom Metrics Integration
```hcl
# Custom metrics for business logic monitoring
resource "google_monitoring_metric_descriptor" "business_transactions" {
  type         = "custom.googleapis.com/business/transactions_processed"
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  unit         = "1"
  description  = "Number of business transactions processed"
  display_name = "Business Transactions"
  
  labels {
    key         = "transaction_type"
    value_type  = "STRING"
    description = "Type of business transaction"
  }
  
  labels {
    key         = "status"
    value_type  = "STRING"
    description = "Transaction status (success/failure)"
  }
  
  labels {
    key         = "tier"
    value_type  = "STRING"
    description = "Application tier processing transaction"
  }
}

resource "google_monitoring_metric_descriptor" "security_events" {
  type         = "custom.googleapis.com/security/events_detected"
  metric_kind  = "COUNTER"
  value_type   = "INT64"
  unit         = "1"
  description  = "Security events detected by tier"
  display_name = "Security Events"
  
  labels {
    key         = "event_type"
    value_type  = "STRING"
    description = "Type of security event"
  }
  
  labels {
    key         = "severity"
    value_type  = "STRING"
    description = "Event severity level"
  }
  
  labels {
    key         = "source_ip"
    value_type  = "STRING"
    description = "Source IP address"
  }
}
```

### 3. Outputs for Subsequent Labs
```hcl
# Outputs for integration with logging (Lab 07) and other labs
output "monitoring_workspace" {
  description = "Cloud Monitoring workspace information"
  value = {
    workspace_name = google_monitoring_workspace.techcorp_workspace.name
    project_id     = var.project_id
  }
}

output "notification_channels" {
  description = "Notification channels for alerts"
  value = {
    email_critical    = google_monitoring_notification_channel.email_critical.id
    slack_general     = google_monitoring_notification_channel.slack_general.id
    pagerduty_incidents = google_monitoring_notification_channel.pagerduty_incidents.id
    sms_critical      = google_monitoring_notification_channel.sms_critical.id
  }
}

output "dashboards" {
  description = "Created dashboards"
  value = {
    executive_overview    = google_monitoring_dashboard.executive_overview.id
    operational_overview  = google_monitoring_dashboard.operational_overview.id
    technical_deep_dive   = google_monitoring_dashboard.technical_deep_dive.id
  }
}

output "slo_configuration" {
  description = "SLO configuration for service reliability"
  value = {
    availability_slo = {
      name = google_monitoring_slo.availability_slo.name
      goal = google_monitoring_slo.availability_slo.goal
      service_id = google_monitoring_service.techcorp_service.service_id
    }
    latency_slo = {
      name = google_monitoring_slo.latency_slo.name
      goal = google_monitoring_slo.latency_slo.goal
      service_id = google_monitoring_service.techcorp_service.service_id
    }
  }
}

output "custom_metrics" {
  description = "Custom metrics for application monitoring"
  value = {
    business_transactions = google_monitoring_metric_descriptor.business_transactions.type
    security_events      = google_monitoring_metric_descriptor.security_events.type
  }
}
```

---

## Best Practices and Optimization

### 1. Monitoring Strategy
- **Golden Signals**: Focus on Request rate, Error rate, Duration, Saturation
- **Layered Monitoring**: Infrastructure, application, and business metrics
- **Proactive Alerting**: Alert on symptoms, not just failures
- **Contextual Dashboards**: Different views for different audiences

### 2. Alert Management
- **Alert Fatigue Prevention**: Tune thresholds to minimize false positives
- **Escalation Policies**: Clear escalation paths for different severity levels
- **Runbook Integration**: Include actionable information in alerts
- **Regular Review**: Periodic review and optimization of alert policies

### 3. SLO Management
- **User-Centric SLOs**: Align SLOs with user experience
- **Error Budget Policy**: Clear policies for error budget management
- **SLO Review Process**: Regular review and adjustment of SLOs
- **Business Alignment**: Connect SLOs to business objectives

---

## Troubleshooting Guide

### Monitoring Issues
```bash
# Check monitoring agent status
sudo systemctl status stackdriver-agent
sudo systemctl status google-fluentd

# Verify metric collection
gcloud monitoring metrics list --filter="metric.type:custom.googleapis.com"

# Test alert policies
gcloud alpha monitoring policies list
gcloud alpha monitoring policies describe POLICY_ID
```

### Dashboard Issues
```bash
# Check dashboard configuration
gcloud monitoring dashboards list
gcloud monitoring dashboards describe DASHBOARD_ID

# Verify metric queries
gcloud monitoring metrics-descriptors list --filter="metric.type:loadbalancing"
```

### SLO Issues
```bash
# Check SLO status
gcloud monitoring slos list --service=SERVICE_ID
gcloud monitoring slos describe SLO_ID --service=SERVICE_ID

# Verify error budget burn rate
gcloud monitoring slos describe SLO_ID --service=SERVICE_ID --format="value(serviceLevelIndicator)"
```

---

## Assessment Questions

1. **How do Golden Signals help in effective monitoring strategy?**
2. **What are the key considerations for designing effective dashboards?**
3. **How do SLOs contribute to reliability engineering practices?**
4. **What strategies help prevent alert fatigue in monitoring systems?**
5. **How does monitoring integration support overall observability?**

---

## Additional Resources

### Documentation
- [Cloud Monitoring Overview](https://cloud.google.com/monitoring/docs)
- [SLO Monitoring](https://cloud.google.com/monitoring/slo)
- [Alert Policies](https://cloud.google.com/monitoring/alerts)
- [Custom Metrics](https://cloud.google.com/monitoring/custom-metrics)

### Best Practices
- [Site Reliability Engineering](https://sre.google/books/)
- [Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Error Budgets](https://sre.google/sre-book/embracing-risk/)
LAB06_CONCEPTS_END

# Lab 07 Concepts - Cloud Logging Architecture
cat > workshop-materials/docs/guides/lab-07-concepts.md << 'LAB07_CONCEPTS_END'
# Lab 07 Concepts: Cloud Logging Architecture

## Learning Objectives
After completing this lab, you will understand:
- Centralized logging architecture and log aggregation strategies
- Log routing, filtering, and sink configuration
- Compliance logging requirements and audit trail management
- Log analysis and correlation techniques
- Cost optimization strategies for logging infrastructure

---

## Core Concepts

### 1. Centralized Logging Architecture

#### Logging Stack Overview
```
┌─────────────────────────────────────────────────────────────┐
│                Cloud Logging Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Log Generation Layer                                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Infrastructure Logs                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ GCE         │  │ GKE         │  │ Cloud       │ ││ │
│  │  │ │ System Logs │  │ Container   │  │ Functions   │ ││ │
│  │  │ │ Syslog      │  │ Logs        │  │ Execution   │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Application Logs                                       │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ Web Tier    │  │ App Tier    │  │ Data Tier   │ ││ │
│  │  │ │ Access Logs │  │ Service     │  │ Database    │ ││ │
│  │  │ │ Error Logs  │  │ Logs        │  │ Query Logs  │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Security and Audit Logs                               │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ││ │
│  │  │ │ IAM         │  │ Network     │  │ Security    │ ││ │
│  │  │ │ Audit Logs  │  │ Flow Logs   │  │ Events      │ ││ │
│  │  │ │ Admin API   │  │ Firewall    │  │ Intrusion   │ ││ │
│  │  │ └─────────────┘  └─────────────┘  └─────────────┘ ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Log Ingestion and Processing Layer                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Fluentd     │  │ Log         │  │ Structured  │     │ │
│  │ │ Agents      │  │ Parsers     │  │ Logging     │     │ │
│  │ │ Collection  │  │ Enrichment  │  │ JSON Format │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Cloud Logging API                                   │ │ │
│  │ │ • Real-time ingestion                               │ │ │
│  │ │ • Automatic enrichment                              │ │ │
│  │ │ • Metadata extraction                               │ │ │
│  │ │ • Rate limiting and quotas                          │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Log Storage and Routing Layer                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Cloud       │  │ Log Sinks   │  │ Retention   │     │ │
│  │ │ Logging     │  │ Routing     │  │ Policies    │     │ │
│  │ │ Storage     │  │ Filters     │  │ Lifecycle   │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ External Destinations                               │ │ │
│  │ │ • BigQuery (Analytics)                              │ │ │
│  │ │ • Cloud Storage (Archival)                          │ │ │
│  │ │ • Pub/Sub (Real-time Processing)                    │ │ │
│  │ │ • External SIEM Systems                             │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Log Analysis and Visualization Layer                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │ │ Logs        │  │ BigQuery    │  │ Monitoring  │     │ │
│  │ │ Explorer    │  │ Analytics   │  │ Integration │     │ │
│  │ │ Search UI   │  │ SQL Queries │  │ Alerting    │     │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Logging Infrastructure Setup
```hcl
# Cloud Logging configuration
resource "google_logging_project_bucket_config" "techcorp_logs" {
  project        = var.project_id
  location       = var.region
  retention_days = 30
  bucket_id      = "techcorp-default-logs"
  
  description = "Default log bucket for TechCorp application logs"
  
  lifecycle {
    prevent_destroy = true
  }
}

# Compliance logging bucket with extended retention
resource "google_logging_project_bucket_config" "compliance_logs" {
  project        = var.project_id
  location       = var.region
  retention_days = 2555  # 7 years for compliance
  bucket_id      = "techcorp-compliance-logs"
  
  description = "Compliance and audit log bucket with 7-year retention"
  
  lifecycle {
    prevent_destroy = true
  }
}

# Security logging bucket
resource "google_logging_project_bucket_config" "security_logs" {
  project        = var.project_id
  location       = var.region
  retention_days = 365  # 1 year for security logs
  bucket_id      = "techcorp-security-logs"
  
  description = "Security and audit log bucket"
  
  lifecycle {
    prevent_destroy = true
  }
}

# Application logging bucket
resource "google_logging_project_bucket_config" "application_logs" {
  project        = var.project_id
  location       = var.region
  retention_days = 90  # 3 months for application logs
  bucket_id      = "techcorp-application-logs"
  
  description = "Application and service log bucket"
}
```

### 2. Log Routing and Sink Configuration

#### Log Routing Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                    Log Routing Strategy                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Audit and Compliance Logs                                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Source: Admin Activity, Data Access, System Events     │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Filter: protoPayload.@type="type.googleapis.com/   │ │ │
│  │ │         google.cloud.audit.AuditLog"               │ │ │
│  │ │ Destination: Compliance Bucket (7 years)           │ │ │
│  │ │ + BigQuery Dataset (Analytics)                      │ │ │
│  │ │ + Cloud Storage (Long-term Archive)                │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Security Logs                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Source: Firewall, IAM, Security Events                 │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Filter: logName=~"cloudaudit.googleapis.com" OR     │ │ │
│  │ │         logName=~"compute.googleapis.com/firewall"  │ │ │
│  │ │ Destination: Security Bucket (1 year)              │ │ │
│  │ │ + Pub/Sub Topic (Real-time SIEM)                   │ │ │
│  │ │ + Cloud Functions (Automated Response)             │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Application Logs                                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Source: Web, App, Data Tier Applications               │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Filter: resource.type="gce_instance" AND            │ │ │
│  │ │         labels.tier=~"web|app|data"                 │ │ │
│  │ │ Destination: Application Bucket (90 days)          │ │ │
│  │ │ + BigQuery Dataset (Analytics)                      │ │ │
│  │ │ + Monitoring Integration (Metrics)                  │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Infrastructure Logs                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Source: System, Network, Storage                        │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Filter: resource.type=~"gce_|gke_|cloudsql_"        │ │ │
│  │ │ Destination: Default Bucket (30 days)              │ │ │
│  │ │ + Monitoring Integration (Alerts)                   │ │ │
│  │ │ + Cost Optimization (Sampling)                      │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Log Sink Implementation
```hcl
# Audit and compliance log sink
resource "google_logging_project_sink" "audit_compliance_sink" {
  name        = "audit-compliance-sink"
  description = "Route audit and compliance logs to compliance bucket and BigQuery"
  
  # Route to compliance log bucket
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/techcorp-compliance-logs"
  
  # Filter for audit logs
  filter = <<-EOT
    protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
    OR
    logName=~"projects/${var.project_id}/logs/cloudaudit.googleapis.com"
  EOT
  
  # Use a unique writer identity
  unique_writer_identity = true
  
  # Exclude logs from certain services to reduce volume
  exclusions {
    name        = "exclude-gcs-data-access"
    description = "Exclude GCS data access logs to reduce volume"
    filter      = "protoPayload.serviceName=\"storage.googleapis.com\" AND protoPayload.methodName=~\"storage.objects.(get|list)\""
  }
}

# Security events sink
resource "google_logging_project_sink" "security_events_sink" {
  name        = "security-events-sink"
  description = "Route security events to security bucket and Pub/Sub for SIEM"
  
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/techcorp-security-logs"
  
  filter = <<-EOT
    (logName=~"compute.googleapis.com/firewall" OR
     logName=~"cloudaudit.googleapis.com/activity" OR
     logName=~"cloudaudit.googleapis.com/system_event" OR
     protoPayload.authenticationInfo.principalEmail!="") AND
    (severity >= "WARNING" OR
     protoPayload.authorizationInfo.granted=false OR
     protoPayload.methodName=~".*delete.*|.*create.*|.*update.*")
  EOT
  
  unique_writer_identity = true
}

# Security events to Pub/Sub for real-time processing
resource "google_logging_project_sink" "security_pubsub_sink" {
  name        = "security-pubsub-sink"
  description = "Route critical security events to Pub/Sub for real-time processing"
  
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.security_events.name}"
  
  filter = <<-EOT
    (severity >= "ERROR" OR
     protoPayload.authorizationInfo.granted=false OR
     jsonPayload.event_type=~"security_violation|intrusion_detected|unauthorized_access") AND
    NOT protoPayload.serviceName="compute.googleapis.com"
  EOT
  
  unique_writer_identity = true
}

# Application logs sink
resource "google_logging_project_sink" "application_logs_sink" {
  name        = "application-logs-sink"
  description = "Route application logs to dedicated bucket and BigQuery"
  
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/techcorp-application-logs"
  
  filter = <<-EOT
    (resource.type="gce_instance" AND
     (resource.labels.instance_name=~"web-tier-.*" OR
      resource.labels.instance_name=~"app-tier-.*" OR
      resource.labels.instance_name=~"data-tier-.*")) OR
    (resource.type="k8s_container" AND
     resource.labels.namespace_name=~"web-tier|app-tier|data-tier")
  EOT
  
  unique_writer_identity = true
}

# BigQuery sink for log analytics
resource "google_logging_project_sink" "logs_analytics_sink" {
  name        = "logs-analytics-sink"
  description = "Route structured logs to BigQuery for analytics"
  
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs_analytics.dataset_id}"
  
  filter = <<-EOT
    (jsonPayload != "" OR
     protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog") AND
    severity >= "INFO" AND
    NOT logName=~"compute.googleapis.com/serial_port"
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Cost optimization sink with sampling
resource "google_logging_project_sink" "cost_optimized_sink" {
  name        = "cost-optimized-sink"
  description = "Sample verbose logs to reduce costs while maintaining visibility"
  
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/techcorp-default-logs"
  
  filter = <<-EOT
    resource.type=~"gce_instance|gke_container" AND
    severity >= "INFO" AND
    sample(insertId, 0.1)
  EOT
}
```

### 3. Compliance and Audit Logging

#### Compliance Logging Framework
```
┌─────────────────────────────────────────────────────────────┐
│                Compliance Logging Framework                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Regulatory Requirements                                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  SOX (Sarbanes-Oxley) Requirements                     │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • All administrative actions logged                 ││ │
│  │  │ • Financial data access tracking                    ││ │
│  │  │ • Change management audit trails                    ││ │
│  │  │ • 7-year retention requirement                      ││ │
│  │  │ • Immutable log storage                             ││ │
│  │  │ • Segregation of duties enforcement                 ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  PCI DSS Requirements                                   │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Cardholder data access logging                    ││ │
│  │  │ • Network activity monitoring                       ││ │
│  │  │ • Security event correlation                        ││ │
│  │  │ • Regular log review processes                      ││ │
│  │  │ • Secure log transmission                           ││ │
│  │  │ • Log integrity protection                          ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  GDPR Requirements                                      │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Personal data processing logs                     ││ │
│  │  │ • Data subject request tracking                     ││ │
│  │  │ • Consent management logging                        ││ │
│  │  │ • Data breach incident logs                         ││ │
│  │  │ • Right to erasure compliance                       ││ │
│  │  │ • Data processing lawfulness                        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
│                             │                               │
│                             ▼                               │
│  Audit Trail Implementation                                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Administrative Actions                                 │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • IAM policy changes                                ││ │
│  │  │ • Resource creation/deletion                        ││ │
│  │  │ • Configuration modifications                       ││ │
│  │  │ • Access control updates                            ││ │
│  │  │ • Service account key operations                    ││ │
│  │  │ • Organization policy changes                       ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Data Access Tracking                                  │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Database query logging                            ││ │
│  │  │ • File access monitoring                            ││ │
│  │  │ • API endpoint usage                                ││ │
│  │  │ • Data export operations                            ││ │
│  │  │ • Backup and restore activities                     ││ │
│  │  │ • Cross-border data transfers                       ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  │                                                         │ │
│  │  Security Events                                        │ │
│  │  ┌─────────────────────────────────────────────────────┐│ │
│  │  │ • Authentication attempts                           ││ │
│  │  │ • Authorization failures                            ││ │
│  │  │ • Privilege escalation events                       ││ │
│  │  │ • Network security violations                       ││ │
│  │  │ • Malware detection events                          ││ │
│  │  │ • Intrusion detection alerts                        ││ │
│  │  └─────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Compliance Logging Configuration
```hcl
# BigQuery dataset for compliance analytics
resource "google_bigquery_dataset" "compliance_logs" {
  dataset_id                  = "compliance_logs"
  friendly_name              = "Compliance and Audit Logs"
  description                = "Dataset for compliance logging and audit trail analysis"
  location                   = var.region
  default_table_expiration_ms = null  # No expiration for compliance data
  
  # Access controls for compliance data
  access {
    role          = "OWNER"
    user_by_email = var.compliance_officer_email
  }
  
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  
  access {
    role          = "WRITER"
    user_by_email = google_service_account.logging_service_account.email
  }
  
  labels = {
    environment = var.environment
    purpose     = "compliance"
    retention   = "7-years"
  }
}

# BigQuery dataset for log analytics
resource "google_bigquery_dataset" "logs_analytics" {
  dataset_id                  = "logs_analytics"
  friendly_name              = "Log Analytics"
  description                = "Dataset for general log analytics and monitoring"
  location                   = var.region
  default_table_expiration_ms = 7776000000  # 90 days in milliseconds
  
  access {
    role          = "OWNER"
    user_by_email = data.terraform_remote_state.lab05.outputs.service_accounts["monitoring-sa"].email
  }
  
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  
  labels = {
    environment = var.environment
    purpose     = "analytics"
    retention   = "90-days"
  }
}

# Cloud Storage bucket for long-term log archival
resource "google_storage_bucket" "log_archive" {
  name     = "${var.project_id}-log-archive"
  location = var.region
  
  # Compliance requires immutable storage
  retention_policy {
    retention_period = 220752000  # 7 years in seconds
    is_locked       = true
  }
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 2555  # 7 years
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
  
  labels = {
    purpose     = "compliance-archive"
    retention   = "7-years"
    environment = var.environment
  }
}

# Pub/Sub topic for real-time security event processing
resource "google_pubsub_topic" "security_events" {
  name = "security-events"
  
  labels = {
    purpose = "security-monitoring"
    type    = "real-time"
  }
}

resource "google_pubsub_subscription" "security_events_sub" {
  name  = "security-events-processor"
  topic = google_pubsub_topic.security_events.name
  
  # Message retention for 7 days
  message_retention_duration = "604800s"
  
  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.security_events_dlq.id
    max_delivery_attempts = 5
  }
  
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

resource "google_pubsub_topic" "security_events_dlq" {
  name = "security-events-dead-letter"
}
```

### 4. Log Analysis and Correlation

#### Log Analysis Framework
```hcl
# Cloud Function for automated log analysis
resource "google_cloudfunctions_function" "log_analyzer" {
  name        = "log-analyzer"
  description = "Automated log analysis and correlation function"
  runtime     = "python39"
  
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.log_analyzer_function.name
  timeout               = 540
  
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.log_analysis_requests.name
  }
  
  entry_point = "analyze_logs"
  
  environment_variables = {
    PROJECT_ID = var.project_id
    BIGQUERY_DATASET = google_bigquery_dataset.logs_analytics.dataset_id
    SECURITY_TOPIC = google_pubsub_topic.security_events.name
    ALERT_THRESHOLD = "10"
    SLACK_WEBHOOK = var.slack_webhook_url
  }
  
  service_account_email = data.terraform_remote_state.lab05.outputs.service_accounts["monitoring-sa"].email
}

resource "google_pubsub_topic" "log_analysis_requests" {
  name = "log-analysis-requests"
}

# Scheduled log analysis job
resource "google_cloud_scheduler_job" "log_analysis_schedule" {
  name             = "automated-log-analysis"
  description      = "Scheduled log analysis and anomaly detection"
  schedule         = "0 */6 * * *"  # Every 6 hours
  time_zone        = "America/New_York"
  attempt_deadline = "320s"
  
  pubsub_target {
    topic_name = google_pubsub_topic.log_analysis_requests.id
    data       = base64encode(jsonencode({
      analysis_type = "anomaly_detection"
      time_range = "6h"
      severity_threshold = "WARNING"
    }))
  }
}

# BigQuery views for common log analysis queries
resource "google_bigquery_table" "security_events_view" {
  dataset_id = google_bigquery_dataset.logs_analytics.dataset_id
  table_id   = "security_events_view"
  
  view {
    query = <<-EOT
      SELECT
        timestamp,
        severity,
        resource.type as resource_type,
        resource.labels.instance_id,
        protoPayload.authenticationInfo.principalEmail as user_email,
        protoPayload.methodName as method,
        protoPayload.resourceName as resource,
        protoPayload.authorizationInfo.granted as access_granted,
        protoPayload.request as request_details,
        httpRequest.remoteIp as source_ip,
        httpRequest.userAgent as user_agent
      FROM
        `${var.project_id}.${google_bigquery_dataset.logs_analytics.dataset_id}.*`
      WHERE
        protoPayload.@type = "type.googleapis.com/google.cloud.audit.AuditLog"
        AND (
          protoPayload.authorizationInfo.granted = false
          OR severity >= "WARNING"
          OR protoPayload.methodName LIKE "%delete%"
          OR protoPayload.methodName LIKE "%create%"
        )
        AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
      ORDER BY
        timestamp DESC
    EOT
    use_legacy_sql = false
  }
}

resource "google_bigquery_table" "error_analysis_view" {
  dataset_id = google_bigquery_dataset.logs_analytics.dataset_id
  table_id   = "error_analysis_view"
  
  view {
    query = <<-EOT
      SELECT
        timestamp,
        severity,
        resource.type as resource_type,
        resource.labels.instance_name,
        resource.labels.zone,
        jsonPayload.message as error_message,
        jsonPayload.stack_trace,
        httpRequest.status as http_status,
        httpRequest.remoteIp as client_ip,
        labels.tier as application_tier,
        COUNT(*) OVER (
          PARTITION BY jsonPayload.message, resource.labels.instance_name
          ORDER BY timestamp
          ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
        ) as error_frequency
      FROM
        `${var.project_id}.${google_bigquery_dataset.logs_analytics.dataset_id}.*`
      WHERE
        severity = "ERROR"
        AND resource.type IN ("gce_instance", "k8s_container", "gae_app")
        AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
      ORDER BY
        timestamp DESC
    EOT
    use_legacy_sql = false
  }
}

resource "google_bigquery_table" "performance_analysis_view" {
  dataset_id = google_bigquery_dataset.logs_analytics.dataset_id
  table_id   = "performance_analysis_view"
  
  view {
    query = <<-EOT
      SELECT
        TIMESTAMP_TRUNC(timestamp, MINUTE) as time_bucket,
        resource.labels.backend_service_name,
        AVG(CAST(jsonPayload.response_time_ms AS FLOAT64)) as avg_response_time,
        PERCENTILE_CONT(CAST(jsonPayload.response_time_ms AS FLOAT64), 0.95) OVER (
          PARTITION BY TIMESTAMP_TRUNC(timestamp, MINUTE), resource.labels.backend_service_name
        ) as p95_response_time,
        COUNT(*) as request_count,
        COUNT(CASE WHEN httpRequest.status >= 400 THEN 1 END) as error_count,
        COUNT(CASE WHEN httpRequest.status >= 400 THEN 1 END) / COUNT(*) as error_rate
      FROM
        `${var.project_id}.${google_bigquery_dataset.logs_analytics.dataset_id}.*`
      WHERE
        resource.type = "gce_backend_service"
        AND httpRequest IS NOT NULL
        AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
      GROUP BY
        time_bucket,
        backend_service_name
      ORDER BY
        time_bucket DESC
    EOT
    use_legacy_sql = false
  }
}
```

### 5. Cost Optimization Strategies

#### Logging Cost Management
```hcl
# Log-based metrics for cost monitoring
resource "google_logging_metric" "log_volume_by_severity" {
  name        = "log_volume_by_severity"
  description = "Track log volume by severity for cost optimization"
  
  filter = "resource.type=~\".*\""
  
  metric_descriptor {
    metric_kind = "COUNTER"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Log Volume by Severity"
  }
  
  label_extractors = {
    "severity" = "EXTRACT(severity)"
    "resource_type" = "EXTRACT(resource.type)"
  }
}

resource "google_logging_metric" "expensive_log_sources" {
  name        = "expensive_log_sources"
  description = "Identify high-volume log sources for optimization"
  
  filter = "resource.type=~\".*\""
  
  metric_descriptor {
    metric_kind = "COUNTER"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Log Volume by Source"
  }
  
  label_extractors = {
    "resource_type" = "EXTRACT(resource.type)"
    "log_name" = "EXTRACT(logName)"
  }
}

# Cost optimization through log sampling
resource "google_logging_project_exclusion" "debug_log_sampling" {
  name        = "debug-log-sampling"
  description = "Sample debug logs to reduce volume and cost"
  
  filter = <<-EOT
    severity="DEBUG" AND
    NOT sample(insertId, 0.01)  # Keep only 1% of debug logs
  EOT
}

resource "google_logging_project_exclusion" "verbose_gce_logs" {
  name        = "verbose-gce-sampling"
  description = "Reduce verbose GCE system logs"
  
  filter = <<-EOT
    resource.type="gce_instance" AND
    logName=~"compute.googleapis.com/serial_port" AND
    NOT sample(insertId, 0.05)  # Keep only 5% of serial port logs
  EOT
}

# Alert on unusual log volume spikes
resource "google_monitoring_alert_policy" "log_volume_spike" {
  display_name = "Unusual Log Volume Spike"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Log ingestion rate > 10x normal"
    
    condition_threshold {
      filter          = "resource.type=\"logging_sink\" AND metric.type=\"logging.googleapis.com/log_entry_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 100000  # Adjust based on normal volume
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
  
  notification_channels = [
    data.terraform_remote_state.lab06.outputs.notification_channels.slack_general
  ]
  
  documentation {
    content = <<-EOF
    Unusual log volume spike detected. This may indicate:
    1. Application error loops
    2. Security scanning/attacks
    3. Misconfigured logging levels
    4. System malfunctions
    
    Check log sources and consider implementing sampling.
    EOF
    mime_type = "text/markdown"
  }
}

# Cost tracking dashboard
resource "google_monitoring_dashboard" "logging_cost_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Logging Cost Optimization"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Log Volume by Source"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"logging_sink\" AND metric.type=\"logging.googleapis.com/log_entry_count\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.sink_name"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Log Volume by Severity"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/log_volume_by_severity\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.severity"]
                    }
                  }
                }
                plotType = "STACKED_AREA"
              }]
            }
          }
        }
      ]
    }
  })
}
```

---

## Integration Patterns

### 1. Integration with Previous Labs
```hcl
# Reference previous lab outputs
data "terraform_remote_state" "lab05" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-05/terraform/state"
  }
}

data "terraform_remote_state" "lab06" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-06/terraform/state"
  }
}

# Service account for logging operations
resource "google_service_account" "logging_service_account" {
  account_id   = "logging-operations-sa"
  display_name = "Logging Operations Service Account"
  description  = "Service account for logging operations and log sink management"
}

# IAM binding for logging service account
resource "google_project_iam_member" "logging_sa_roles" {
  for_each = toset([
    "roles/logging.admin",
    "roles/bigquery.dataEditor",
    "roles/storage.admin",
    "roles/pubsub.publisher"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.logging_service_account.email}"
}
```

### 2. Integration with Monitoring (Lab 06)
```hcl
# Log-based metrics for monitoring integration
resource "google_logging_metric" "application_errors" {
  name        = "application_errors_by_tier"
  description = "Application errors by tier for monitoring dashboards"
  
  filter = <<-EOT
    resource.type="gce_instance" AND
    severity="ERROR" AND
    (labels.tier="web" OR labels.tier="app" OR labels.tier="data")
  EOT
  
  metric_descriptor {
    metric_kind = "COUNTER"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Application Errors by Tier"
  }
  
  label_extractors = {
    "tier" = "EXTRACT(labels.tier)"
    "instance_name" = "EXTRACT(resource.labels.instance_name)"
    "error_type" = "REGEXP_EXTRACT(jsonPayload.message, \"^([A-Za-z]+Error|[A-Za-z]+Exception)\")"
  }
}

# Alert policy based on log patterns
resource "google_monitoring_alert_policy" "application_error_spike" {
  display_name = "Application Error Spike"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Error rate > 10 errors/minute"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/application_errors_by_tier\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 10
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["metric.tier"]
      }
    }
  }
  
  notification_channels = [
    data.terraform_remote_state.lab06.outputs.notification_channels.slack_general
  ]
}
```

### 3. Outputs for Future Labs
```hcl
# Outputs for integration with subsequent labs
output "logging_configuration" {
  description = "Logging configuration for TechCorp infrastructure"
  value = {
    log_buckets = {
      default_logs     = google_logging_project_bucket_config.techcorp_logs.bucket_id
      compliance_logs  = google_logging_project_bucket_config.compliance_logs.bucket_id
      security_logs    = google_logging_project_bucket_config.security_logs.bucket_id
      application_logs = google_logging_project_bucket_config.application_logs.bucket_id
    }
    
    log_sinks = {
      audit_compliance = google_logging_project_sink.audit_compliance_sink.id
      security_events  = google_logging_project_sink.security_events_sink.id
      application_logs = google_logging_project_sink.application_logs_sink.id
      logs_analytics   = google_logging_project_sink.logs_analytics_sink.id
    }
    
    analytics_datasets = {
      compliance_logs = google_bigquery_dataset.compliance_logs.dataset_id
      logs_analytics  = google_bigquery_dataset.logs_analytics.dataset_id
    }
    
    storage_buckets = {
      log_archive = google_storage_bucket.log_archive.name
    }
    
    pubsub_topics = {
      security_events = google_pubsub_topic.security_events.name
      log_analysis    = google_pubsub_topic.log_analysis_requests.name
    }
  }
}

output "compliance_configuration" {
  description = "Compliance logging configuration"
  value = {
    retention_periods = {
      compliance_logs  = "${google_logging_project_bucket_config.compliance_logs.retention_days} days"
      security_logs    = "${google_logging_project_bucket_config.security_logs.retention_days} days"
      application_logs = "${google_logging_project_bucket_config.application_logs.retention_days} days"
      default_logs     = "${google_logging_project_bucket_config.techcorp_logs.retention_days} days"
    }
    
    archive_storage = {
      bucket_name = google_storage_bucket.log_archive.name
      retention_period = "7 years"
      immutable = true
    }
    
    analytics_views = {
      security_events      = google_bigquery_table.security_events_view.table_id
      error_analysis       = google_bigquery_table.error_analysis_view.table_id
      performance_analysis = google_bigquery_table.performance_analysis_view.table_id
    }
  }
}

output "cost_optimization" {
  description = "Cost optimization configuration for logging"
  value = {
    log_sampling = {
      debug_logs = "1% sampling"
      verbose_gce = "5% sampling"
    }
    
    lifecycle_policies = {
      nearline_after = "30 days"
      coldline_after = "365 days"
      archive_after  = "7 years"
    }
    
    monitoring = {
      volume_alerts = google_monitoring_alert_policy.log_volume_spike.id
      cost_dashboard = google_monitoring_dashboard.logging_cost_dashboard.id
    }
  }
}
```

---

## Best Practices and Optimization

### 1. Logging Strategy
- **Structured Logging**: Use JSON format for better parsing and analysis
- **Contextual Information**: Include relevant metadata in log entries
- **Log Levels**: Implement appropriate log level filtering
- **Sampling**: Use sampling for high-volume, low-value logs
- **Centralization**: Route all logs through Cloud Logging for consistency

### 2. Compliance Management
- **Retention Policies**: Implement appropriate retention based on regulatory requirements
- **Immutable Storage**: Use retention policies and bucket locks for compliance
- **Access Controls**: Implement strict access controls for audit logs
- **Regular Audits**: Conduct periodic reviews of logging configuration
- **Documentation**: Maintain comprehensive documentation of logging practices

### 3. Cost Optimization
- **Log Sampling**: Implement intelligent sampling for verbose logs
- **Lifecycle Management**: Use storage classes for cost-effective long-term retention
- **Volume Monitoring**: Monitor and alert on unusual log volume spikes
- **Regular Reviews**: Periodic review of logging costs and optimization opportunities
- **Exclusion Filters**: Use exclusions to filter out unnecessary logs

### 4. Performance Optimization
- **Batch Processing**: Use batch processing for log analysis where possible
- **Efficient Queries**: Optimize BigQuery queries for log analysis
- **Partitioning**: Use partitioned tables for better query performance
- **Indexing**: Implement appropriate indexing strategies for log data

---

## Troubleshooting Guide

### Log Ingestion Issues
```bash
# Check log ingestion rates
gcloud logging read "timestamp >= \"$(date -d '1 hour ago' --iso-8601)\"" --limit=10

# Verify log sinks
gcloud logging sinks list
gcloud logging sinks describe SINK_NAME

# Check sink permissions
gcloud projects get-iam-policy PROJECT_ID --filter="bindings.members:*logging*"
```

### BigQuery Integration Issues
```bash
# Check BigQuery dataset permissions
bq show --format=prettyjson PROJECT_ID:DATASET_ID

# Verify table creation from log sink
bq ls -j PROJECT_ID:DATASET_ID

# Test log sink to BigQuery
gcloud logging read "timestamp >= \"$(date -d '10 minutes ago' --iso-8601)\"" --format="table(timestamp,severity,resource.type)"
```

### Storage and Retention Issues
```bash
# Check bucket retention policies
gsutil retention get gs://BUCKET_NAME

# Verify log bucket configuration
gcloud logging buckets describe BUCKET_ID --location=LOCATION

# Check log volume and costs
gcloud logging read "timestamp >= \"$(date -d '1 day ago' --iso-8601)\"" --format="value(timestamp)" | wc -l
```

---

## Assessment Questions

1. **How does centralized logging support compliance and audit requirements?**
2. **What strategies can be used to optimize logging costs while maintaining visibility?**
3. **How do log sinks and routing improve log management and analysis?**
4. **What are the key considerations for long-term log retention and archival?**
5. **How does log analysis integration with monitoring enhance observability?**

---

## Additional Resources

### Documentation
- [Cloud Logging Overview](https://cloud.google.com/logging/docs)
- [Log Sinks](https://cloud.google.com/logging/docs/export)
- [Log-based Metrics](https://cloud.google.com/logging/docs/logs-based-metrics)
- [BigQuery Log Analytics](https://cloud.google.com/logging/docs/export/bigquery)

### Compliance Resources
- [SOX Compliance Logging](https://cloud.google.com/architecture/sox-compliance-logging)
- [PCI DSS Logging Requirements](https://cloud.google.com/security/compliance/pci-dss)
- [GDPR Data Processing Logs](https://cloud.google.com/privacy/gdpr)

### Best Practices
- [Logging Best Practices](https://cloud.google.com/logging/docs/best-practices)
- [Cost Optimization](https://cloud.google.com/logging/docs/pricing)
- [Security Logging](https://cloud.google.com/security/compliance/iso-27001)
LAB07_CONCEPTS_END

echo "Created concept guides for Labs 03-07..."
echo "✅ Lab 03: Core Networking Architecture concepts"
echo "✅ Lab 04: Network Security Implementation concepts" 
echo "✅ Lab 05: Identity and Access Management concepts"
echo "✅ Lab 06: Cloud Monitoring Foundation concepts"
echo "✅ Lab 07: Cloud Logging Architecture concepts"

echo "
==========================================
🎉 Labs 03-07 Concept Guides Created! 🎉
==========================================

Additional Documentation Generated:
✅ Lab 03: Core Networking Architecture (Multi-tier, Load Balancing, Auto-scaling)
✅ Lab 04: Network Security Implementation (Cloud Armor, WAF, DDoS Protection)  
✅ Lab 05: Identity and Access Management (Custom Roles, Workload Identity, Conditional Access)
✅ Lab 06: Cloud Monitoring Foundation (Dashboards, Alerts, SLI/SLO)
✅ Lab 07: Cloud Logging Architecture (Centralized Logging, Compliance, Analytics)

Complete Documentation Structure:
workshop-materials/docs/
├── presentations/
│   └── workshop-overview.md          # 45+ slides
├── guides/
│   ├── lab-01-concepts.md           # GCP Foundation (Complete)
│   ├── lab-02-concepts.md           # Terraform Setup (Complete)
│   ├── lab-03-concepts.md           # Networking (Complete)
│   ├── lab-04-concepts.md           # Security (Complete)
│   ├── lab-05-concepts.md           # IAM (Complete)
│   ├── lab-06-concepts.md           # Monitoring (Complete)
│   └── lab-07-concepts.md           # Logging (Complete)
├── diagrams/
│   └── architecture-overview.md     # Complete architecture
├── reference/
│   ├── complete-workshop-guide.md   # Master reference
│   └── quick-reference.md           # Commands & troubleshooting
└── generate-presentations.sh       # Presentation generator

Key Features Added in Labs 03-07:

🏗️ **Lab 03 - Networking**: Multi-tier architecture, global load balancing, auto-scaling, firewall micro-segmentation
🛡️ **Lab 04 - Security**: Cloud Armor WAF, DDoS protection, OWASP Top 10, geo-blocking, adaptive protection
🔐 **Lab 05 - IAM**: Custom roles, Workload Identity, conditional access, organization policies, JIT access
📊 **Lab 06 - Monitoring**: Golden signals, SLI/SLO, error budgets, custom dashboards, alert policies
📋 **Lab 07 - Logging**: Centralized logging, compliance retention, log analytics, cost optimization

Each concept guide includes:
📖 Comprehensive conceptual explanations
🏗️ ASCII architecture diagrams  
💻 Complete Terraform implementations
🔧 Integration patterns between labs
💡 Best practices and troubleshooting
📚 Assessment questions and resources

Ready for Professional Workshop Delivery! 🚀
========================================"
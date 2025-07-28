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

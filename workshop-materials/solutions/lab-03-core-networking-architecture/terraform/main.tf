# Lab 03 Solution: Core Networking Architecture
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "${TF_STATE_BUCKET}"
    prefix = "lab-03/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get previous lab outputs
data "terraform_remote_state" "lab02" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "lab-02/terraform/state"
  }
}

locals {
  common_labels = {
    workshop    = "gcp-landing-zone"
    lab         = "03"
    component   = "networking"
    environment = "production"
  }
}

# Create firewall rules for multi-tier architecture
resource "google_compute_firewall" "allow_internal" {
  name    = "techcorp-allow-internal"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3306", "5432", "8080"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["internal"]
  priority      = 1000
  
  description = "Allow internal communication between subnets"
}

resource "google_compute_firewall" "allow_web_tier" {
  name    = "techcorp-allow-web"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-tier"]
  priority      = 900
  
  description = "Allow public access to web tier"
}

resource "google_compute_firewall" "allow_app_tier" {
  name    = "techcorp-allow-app"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }
  
  source_tags = ["web-tier"]
  target_tags = ["app-tier"]
  priority    = 900
  
  description = "Allow web tier to communicate with app tier"
}

resource "google_compute_firewall" "allow_database_tier" {
  name    = "techcorp-allow-database"
  network = data.terraform_remote_state.lab02.outputs.shared_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["3306", "5432"]
  }
  
  source_tags = ["app-tier"]
  target_tags = ["database-tier"]
  priority    = 900
  
  description = "Allow app tier to communicate with database tier"
}

# Create health checks
resource "google_compute_health_check" "web_health_check" {
  name        = "techcorp-web-health-check"
  description = "Health check for web tier"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

resource "google_compute_health_check" "app_health_check" {
  name        = "techcorp-app-health-check"
  description = "Health check for app tier"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# Create instance templates
resource "google_compute_instance_template" "web_template" {
  name_prefix = "techcorp-web-"
  description = "Template for web tier instances"
  
  machine_type = "e2-medium"
  
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }
  
  network_interface {
    network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
    subnetwork = data.terraform_remote_state.lab02.outputs.subnets["dev-web"].self_link
  }
  
  service_account {
    email  = data.terraform_remote_state.lab02.outputs.workload_service_accounts["web-tier-sa"].email
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    startup-script = file("${path.module}/../scripts/web-startup.sh")
    enable-oslogin = "TRUE"
  }
  
  tags = ["web-tier", "internal"]
  
  labels = local.common_labels
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_template" "app_template" {
  name_prefix = "techcorp-app-"
  description = "Template for app tier instances"
  
  machine_type = "e2-standard-2"
  
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 50
  }
  
  network_interface {
    network    = data.terraform_remote_state.lab02.outputs.shared_vpc.id
    subnetwork = data.terraform_remote_state.lab02.outputs.subnets["dev-app"].self_link
  }
  
  service_account {
    email  = data.terraform_remote_state.lab02.outputs.workload_service_accounts["app-tier-sa"].email
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    startup-script = file("${path.module}/../scripts/app-startup.sh")
    enable-oslogin = "TRUE"
  }
  
  tags = ["app-tier", "internal"]
  
  labels = local.common_labels
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create managed instance groups
resource "google_compute_region_instance_group_manager" "web_mig" {
  name               = "techcorp-web-mig"
  base_instance_name = "techcorp-web"
  region             = var.region
  
  version {
    instance_template = google_compute_instance_template.web_template.id
  }
  
  target_size = 2
  
  auto_healing_policies {
    health_check      = google_compute_health_check.web_health_check.id
    initial_delay_sec = 300
  }
  
  named_port {
    name = "http"
    port = 80
  }
  
  named_port {
    name = "https"
    port = 443
  }
}

resource "google_compute_region_instance_group_manager" "app_mig" {
  name               = "techcorp-app-mig"
  base_instance_name = "techcorp-app"
  region             = var.region
  
  version {
    instance_template = google_compute_instance_template.app_template.id
  }
  
  target_size = 2
  
  auto_healing_policies {
    health_check      = google_compute_health_check.app_health_check.id
    initial_delay_sec = 300
  }
  
  named_port {
    name = "http"
    port = 8080
  }
}

# Create load balancer components
resource "google_compute_backend_service" "web_backend" {
  name        = "techcorp-web-backend"
  description = "Backend service for web tier"
  protocol    = "HTTP"
  timeout_sec = 30
  
  backend {
    group           = google_compute_region_instance_group_manager.web_mig.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
  
  health_checks = [google_compute_health_check.web_health_check.id]
  
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "web_url_map" {
  name            = "techcorp-web-url-map"
  default_service = google_compute_backend_service.web_backend.id
  
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_backend.id
  }
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "techcorp-web-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

resource "google_compute_global_address" "web_ip" {
  name = "techcorp-web-ip"
}

resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "techcorp-web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.web_ip.address
}

data "google_client_openid_userinfo" "current" {}

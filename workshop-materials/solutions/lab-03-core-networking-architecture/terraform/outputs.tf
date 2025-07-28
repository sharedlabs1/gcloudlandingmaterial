# Outputs for Lab 03

output "lab_03_resources" {
  description = "Resources created in Lab 03"
  value = {
    lab_number = "03"
    project_id = var.project_id
    region     = var.region
  }
}

output "firewall_rules" {
  description = "Created firewall rules"
  value = {
    internal = google_compute_firewall.allow_internal.name
    web      = google_compute_firewall.allow_web_tier.name
    app      = google_compute_firewall.allow_app_tier.name
    database = google_compute_firewall.allow_database_tier.name
  }
}

output "load_balancer" {
  description = "Load balancer configuration"
  value = {
    ip_address    = google_compute_global_address.web_ip.address
    backend_service = google_compute_backend_service.web_backend.name
  }
}

output "instance_groups" {
  description = "Created instance groups"
  value = {
    web = google_compute_region_instance_group_manager.web_mig.instance_group
    app = google_compute_region_instance_group_manager.app_mig.instance_group
  }
}

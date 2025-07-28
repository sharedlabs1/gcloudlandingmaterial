output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnets" {
  description = "Created subnets"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      id        = v.id
      self_link = v.self_link
      cidr      = v.ip_cidr_range
    }
  }
}

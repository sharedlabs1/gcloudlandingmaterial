output "service_accounts" {
  description = "Created service accounts"
  value = {
    for k, v in google_service_account.environment_sa : k => {
      email = v.email
      name  = v.name
    }
  }
}

output "storage_buckets" {
  description = "Created storage buckets"
  value = {
    for k, v in google_storage_bucket.environment_buckets : k => {
      name = v.name
      url  = v.url
    }
  }
}

output "project_id" {
  description = "Project ID"
  value       = var.project_id
}

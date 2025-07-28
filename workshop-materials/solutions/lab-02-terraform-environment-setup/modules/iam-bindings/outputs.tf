output "service_accounts" {
  description = "Created service accounts"
  value = {
    for k, v in google_service_account.service_accounts : k => {
      email = v.email
      name  = v.name
    }
  }
}

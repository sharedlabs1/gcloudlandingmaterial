resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts
  
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_project_iam_member" "service_account_bindings" {
  for_each = {
    for binding in flatten([
      for sa_key, sa_config in var.service_accounts : [
        for role in sa_config.roles : {
          key = "${sa_key}-${role}"
          service_account = sa_key
          role = role
        }
      ]
    ]) : binding.key => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account].email}"
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region"
  type        = string
  default     = "us-central1"
}

variable "company_name" {
  description = "Company name for resources"
  type        = string
  default     = "TechCorp"
}

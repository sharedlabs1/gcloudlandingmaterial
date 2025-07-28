variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region"
  type        = string
  default     = "us-central1"
}

variable "tf_state_bucket" {
  description = "Terraform state bucket name"
  type        = string
}

variable "lab_08_enabled" {
  description = "Enable Lab 08 resources"
  type        = bool
  default     = true
}

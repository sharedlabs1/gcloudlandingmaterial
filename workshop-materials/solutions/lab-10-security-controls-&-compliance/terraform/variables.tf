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


variable "pgp_public_key" {
  description = "PGP public key for Binary Authorization"
  type        = string
  default     = "-----BEGIN PGP PUBLIC KEY BLOCK-----\n...\n-----END PGP PUBLIC KEY BLOCK-----"
}

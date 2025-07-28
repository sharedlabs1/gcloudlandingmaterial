variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "subnets" {
  description = "Subnets configuration"
  type = map(object({
    cidr        = string
    region      = string
    description = string
  }))
}
